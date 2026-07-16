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
    return "404" in text or "NOT_FOUND" in text or "MODEL" in text and "NOT FOUND" in text


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


class GeminiVisionClient:
    def __init__(
        self,
        api_key: str,
        model: str = "gemini-2.5-flash-lite",
        fallback_models: Iterable[str] = ("gemini-2.5-flash",),
    ) -> None:
        if not api_key:
            raise RuntimeError("GEMINI_API_KEY is required.")
        self.client = genai.Client(api_key=api_key)
        self.models = tuple(dict.fromkeys(x.strip() for x in (model, *fallback_models) if x.strip()))

    def extract_profile(self, crops: Mapping[str, Path]) -> ProfileExtraction:
        """Extract a complete profile using one API request for all available crops.

        Sending all labeled crops in one request reduces free-tier usage from six requests per
        realtor to one request per realtor. If the primary model is unavailable or has exhausted
        a model-specific quota, the next configured model is attempted.
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

        quota_failures: list[str] = []
        unavailable_models: list[str] = []

        for model in self.models:
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
                    logger.warning("Gemini model %s is unavailable for this API project; trying fallback model.", model)
                    continue
                raise

        if quota_failures:
            raise GeminiQuotaExceededError(
                "Gemini quota is exhausted for configured model(s): "
                + ", ".join(quota_failures)
                + ". The screenshot was not lost. Wait for the quota reset, enable billing, or configure another model."
            )

        raise GeminiModelsUnavailableError(
            "No configured Gemini model was available: " + ", ".join(unavailable_models or self.models)
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
