from __future__ import annotations

import logging
import mimetypes
from pathlib import Path
from typing import Iterable, Mapping

from google import genai
from google.genai import types
from tenacity import retry, retry_if_exception, stop_after_attempt, wait_exponential

from .models import ProfileExtraction
from .prompts import COMBINED_PROMPT

logger = logging.getLogger(__name__)

SECTION_ORDER = (
    "identity",
    "performance",
    "relationships",
    "transactions",
    "loan_details",
    "extras",
)


class GeminiQuotaExceededError(RuntimeError):
    """Raised when every configured Gemini model has exhausted its available quota."""


class GeminiModelsUnavailableError(RuntimeError):
    """Raised when no configured Gemini model is available to the API project."""


def _message(exc: Exception) -> str:
    return str(exc).upper()


def _is_quota_error(exc: Exception) -> bool:
    text = _message(exc)
    return "RESOURCE_EXHAUSTED" in text or "429" in text or "QUOTA" in text


def _is_model_not_found(exc: Exception) -> bool:
    text = _message(exc)
    return "404" in text or "NOT_FOUND" in text or ("MODEL" in text and "NOT FOUND" in text)


def _is_transient_error(exc: Exception) -> bool:
    text = _message(exc)
    return any(
        marker in text
        for marker in (
            "500",
            "502",
            "503",
            "504",
            "INTERNAL",
            "UNAVAILABLE",
            "DEADLINE_EXCEEDED",
            "CONNECTION RESET",
            "TIMED OUT",
        )
    )


def _clean_model_name(name: str) -> str:
    return name.removeprefix("models/").strip()


class GeminiVisionClient:
    def __init__(
        self,
        api_key: str,
        model: str = "gemini-3.1-flash-lite",
        fallback_models: Iterable[str] = ("gemini-3.5-flash", "gemini-2.5-flash"),
    ) -> None:
        if not api_key:
            raise RuntimeError("GEMINI_API_KEY is required.")
        self.client = genai.Client(api_key=api_key)
        self.models = tuple(
            dict.fromkeys(_clean_model_name(x) for x in (model, *fallback_models) if x.strip())
        )
        self._available_generate_models: tuple[str, ...] | None = None

    def list_generate_models(self, refresh: bool = False) -> tuple[str, ...]:
        """Return models this API project exposes for generateContent."""
        if self._available_generate_models is not None and not refresh:
            return self._available_generate_models

        available: list[str] = []
        for model in self.client.models.list():
            actions = tuple(getattr(model, "supported_actions", ()) or ())
            if "generateContent" in actions:
                name = _clean_model_name(str(getattr(model, "name", "")))
                if name:
                    available.append(name)

        self._available_generate_models = tuple(dict.fromkeys(available))
        return self._available_generate_models

    def _candidate_models(self) -> tuple[str, ...]:
        """Prefer configured models that are actually visible to this API project."""
        try:
            available = set(self.list_generate_models())
        except Exception as exc:
            logger.warning("Could not list Gemini models for this project: %s", exc)
            return self.models

        if not available:
            return self.models

        candidates = tuple(model for model in self.models if model in available)
        unavailable = tuple(model for model in self.models if model not in available)
        if unavailable:
            logger.warning(
                "Configured Gemini model(s) not exposed to this API project: %s",
                ", ".join(unavailable),
            )
        return candidates

    def extract_profile(self, crops: Mapping[str, Path]) -> ProfileExtraction:
        """Extract a complete profile using one API request for all available crops.

        Sending all labeled crops in one request reduces free-tier usage from six requests per
        realtor to one request per realtor. Configured models are filtered against the models
        exposed by the user's API project before generation is attempted.
        """
        contents: list[object] = [COMBINED_PROMPT]
        supplied_sections = 0

        for section in SECTION_ORDER:
            image_path = crops.get(section)
            if image_path is None or not image_path.exists():
                continue
            mime_type = mimetypes.guess_type(image_path.name)[0] or "image/png"
            contents.append(f"IMAGE SECTION: {section}")
            contents.append(types.Part.from_bytes(data=image_path.read_bytes(), mime_type=mime_type))
            supplied_sections += 1

        if supplied_sections == 0:
            raise RuntimeError("No profile crops were supplied to Gemini Vision.")

        candidates = self._candidate_models()
        if not candidates:
            available = self.list_generate_models()
            raise GeminiModelsUnavailableError(
                "None of the configured models are available to this API project. "
                f"Configured: {', '.join(self.models)}. "
                f"Available generateContent models: {', '.join(available) or 'none'}."
            )

        quota_failures: list[str] = []
        unavailable_models: list[str] = []

        for model in candidates:
            try:
                logger.info("Extracting profile with Gemini model %s in one request.", model)
                return self._generate(model, contents)
            except Exception as exc:
                if _is_quota_error(exc):
                    quota_failures.append(model)
                    logger.warning("Gemini quota unavailable for model %s; trying fallback model.", model)
                    continue
                if _is_model_not_found(exc):
                    unavailable_models.append(model)
                    logger.warning(
                        "Gemini model %s is unavailable for this API project; trying fallback model.",
                        model,
                    )
                    continue
                raise

        if quota_failures:
            raise GeminiQuotaExceededError(
                "Gemini quota is exhausted for configured model(s): "
                + ", ".join(quota_failures)
                + ". The screenshot was not lost. Wait for the quota reset, enable billing, or configure another available model."
            )

        raise GeminiModelsUnavailableError(
            "No configured Gemini model was available: " + ", ".join(unavailable_models or candidates)
        )

    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=2, max=12),
        retry=retry_if_exception(_is_transient_error),
        reraise=True,
    )
    def _generate(self, model: str, contents: list[object]) -> ProfileExtraction:
        response = self.client.models.generate_content(
            model=model,
            contents=contents,
            config=types.GenerateContentConfig(
                response_mime_type="application/json",
                response_schema=ProfileExtraction,
                temperature=0,
            ),
        )
        if isinstance(response.parsed, ProfileExtraction):
            return response.parsed
        if not response.text:
            raise RuntimeError(f"Gemini model {model} returned no profile data.")
        return ProfileExtraction.model_validate_json(response.text)
