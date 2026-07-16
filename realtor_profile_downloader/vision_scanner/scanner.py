from __future__ import annotations

import argparse
import hashlib
import json
import logging
import os
import shutil
import time
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path

from dotenv import load_dotenv

from .cropper import ProfileCropper
from .gemini_client import GeminiQuotaExceededError, GeminiVisionClient
from .models import ProfileExtraction
from .storage import StorageConfig, StorageRouter
from .validator import validate_profile

SUPPORTED_EXTENSIONS = {".png", ".jpg", ".jpeg", ".webp"}
logger = logging.getLogger(__name__)


@dataclass(frozen=True)
class ScannerConfig:
    root: Path
    gemini_api_key: str
    gemini_model: str
    gemini_fallback_models: tuple[str, ...]
    crop_scale: float
    keep_crops: bool
    poll_seconds: int
    storage: StorageConfig

    @classmethod
    def from_env(cls) -> "ScannerConfig":
        root = Path(os.getenv("REALTOR_PROFILE_ROOT", r"C:\RealtorProfileScanner")).expanduser()
        fallback_models = tuple(
            model.strip()
            for model in os.getenv(
                "GEMINI_FALLBACK_MODELS",
                "gemini-3.5-flash,gemini-2.5-flash",
            ).split(",")
            if model.strip()
        )
        return cls(
            root=root,
            gemini_api_key=os.getenv("GEMINI_API_KEY", "").strip(),
            gemini_model=os.getenv("GEMINI_MODEL", "gemini-3.1-flash-lite").strip(),
            gemini_fallback_models=fallback_models,
            crop_scale=float(os.getenv("VISION_CROP_SCALE", "2.0")),
            keep_crops=os.getenv("KEEP_VISION_CROPS", "false").lower() in {"1", "true", "yes"},
            poll_seconds=max(5, int(os.getenv("VISION_POLL_SECONDS", "30"))),
            storage=StorageConfig(
                google_sheet_id=os.getenv("GOOGLE_SHEET_ID", "").strip(),
                google_service_account_file=os.getenv("GOOGLE_SERVICE_ACCOUNT_FILE", "").strip(),
                supabase_url=os.getenv("SUPABASE_URL", "").strip(),
                supabase_service_role_key=os.getenv("SUPABASE_SERVICE_ROLE_KEY", "").strip(),
            ),
        )

    def prepare(self) -> dict[str, Path]:
        names = ("incoming", "processing", "processed", "review", "failed", "crops", "reports")
        folders = {name: self.root / name for name in names}
        for folder in folders.values():
            folder.mkdir(parents=True, exist_ok=True)
        return folders


def file_hash(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


class LocalProfileScanner:
    def __init__(self, config: ScannerConfig) -> None:
        self.config = config
        self.folders = config.prepare()
        self.cropper = ProfileCropper(scale=config.crop_scale)
        self.vision = GeminiVisionClient(
            config.gemini_api_key,
            config.gemini_model,
            config.gemini_fallback_models,
        )
        self.storage = StorageRouter(config.storage)
        self.state_path = config.root / ".scanner_state.json"
        self.state = self._load_state()

    def _load_state(self) -> dict[str, dict]:
        if not self.state_path.exists():
            return {}
        try:
            return json.loads(self.state_path.read_text(encoding="utf-8"))
        except Exception:
            logger.warning("Scanner state was unreadable; starting with an empty state.")
            return {}

    def _save_state(self) -> None:
        temporary = self.state_path.with_suffix(".tmp")
        temporary.write_text(json.dumps(self.state, indent=2), encoding="utf-8")
        temporary.replace(self.state_path)

    def scan_once(self) -> int:
        images = sorted(
            path
            for path in self.folders["incoming"].iterdir()
            if path.is_file() and path.suffix.lower() in SUPPORTED_EXTENSIONS
        )
        completed = 0
        for image in images:
            try:
                self.process(image)
                completed += 1
            except GeminiQuotaExceededError as exc:
                logger.error("%s", exc)
                logger.error(
                    "Stopping this batch so no more requests are attempted. The current screenshot was returned to Incoming."
                )
                break
            except Exception:
                logger.exception("Failed to process %s", image.name)
        return completed

    def process(self, incoming_path: Path) -> None:
        source_hash = file_hash(incoming_path)
        if source_hash in self.state:
            duplicate_target = self.folders["processed"] / incoming_path.name
            shutil.move(str(incoming_path), self._unique_path(duplicate_target))
            logger.info("Skipped duplicate %s", incoming_path.name)
            return

        processing_path = self._unique_path(self.folders["processing"] / incoming_path.name)
        shutil.move(str(incoming_path), processing_path)
        scanned_at = datetime.now(timezone.utc).isoformat()
        crop_dir = self.folders["crops"] / source_hash[:16]

        try:
            crops = self.cropper.create_crops(processing_path, crop_dir)
            profile: ProfileExtraction = self.vision.extract_profile(crops)
            validation = validate_profile(profile)
            metadata = {
                "source_file": processing_path.name,
                "source_hash": source_hash,
                "scanned_at": scanned_at,
            }
            self.storage.write(profile, metadata, validation)
            report_path = self.folders["reports"] / f"{processing_path.stem}-{source_hash[:8]}.json"
            report_path.write_text(
                json.dumps(
                    {
                        "metadata": metadata,
                        "validation": validation.model_dump(),
                        "profile": profile.model_dump(),
                    },
                    indent=2,
                ),
                encoding="utf-8",
            )
            target_folder = (
                "review"
                if validation.status in {"LOW_CONFIDENCE", "TOTAL_MISMATCH", "NEEDS_REVIEW"}
                else "processed"
            )
            shutil.move(str(processing_path), self._unique_path(self.folders[target_folder] / processing_path.name))
            self.state[source_hash] = {
                "source_file": processing_path.name,
                "status": validation.status,
                "scanned_at": scanned_at,
                "report": str(report_path),
            }
            self._save_state()
            logger.info("Processed %s with status %s", processing_path.name, validation.status)
        except GeminiQuotaExceededError:
            if processing_path.exists():
                shutil.move(
                    str(processing_path),
                    self._unique_path(self.folders["incoming"] / processing_path.name),
                )
            raise
        except Exception as exc:
            error_report = self.folders["reports"] / f"{processing_path.stem}-{source_hash[:8]}-error.txt"
            error_report.write_text(f"{type(exc).__name__}: {exc}", encoding="utf-8")
            if processing_path.exists():
                shutil.move(str(processing_path), self._unique_path(self.folders["failed"] / processing_path.name))
            raise
        finally:
            if crop_dir.exists() and not self.config.keep_crops:
                shutil.rmtree(crop_dir, ignore_errors=True)

    @staticmethod
    def _unique_path(path: Path) -> Path:
        if not path.exists():
            return path
        for index in range(1, 10_000):
            candidate = path.with_name(f"{path.stem}-{index}{path.suffix}")
            if not candidate.exists():
                return candidate
        raise RuntimeError(f"Could not create a unique destination for {path}")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Scan local realtor profile screenshots with Gemini Vision.")
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--once", action="store_true", help="Process current incoming files once and exit (default).")
    mode.add_argument("--watch", action="store_true", help="Continuously watch the incoming folder.")
    mode.add_argument(
        "--list-models",
        action="store_true",
        help="List generateContent models available to the configured Gemini API key and exit.",
    )
    return parser


def main() -> None:
    load_dotenv()
    args = build_parser().parse_args()
    logging.basicConfig(level=os.getenv("LOG_LEVEL", "INFO"), format="%(asctime)s [%(levelname)s] %(message)s")
    config = ScannerConfig.from_env()

    if args.list_models:
        vision = GeminiVisionClient(
            config.gemini_api_key,
            config.gemini_model,
            config.gemini_fallback_models,
        )
        models = vision.list_generate_models(refresh=True)
        print("Gemini models available to this API project for generateContent:")
        for model in models:
            print(model)
        return

    scanner = LocalProfileScanner(config)
    if not args.watch:
        count = scanner.scan_once()
        logger.info("Finished. Processed %s file(s).", count)
        return
    logger.info("Watching %s", scanner.folders["incoming"])
    while True:
        scanner.scan_once()
        time.sleep(scanner.config.poll_seconds)


if __name__ == "__main__":
    main()
