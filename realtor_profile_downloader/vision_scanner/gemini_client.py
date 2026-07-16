from __future__ import annotations

import mimetypes
from pathlib import Path

from google import genai
from google.genai import types
from pydantic import BaseModel
from tenacity import retry, stop_after_attempt, wait_exponential

from .models import (
    ExtrasSection,
    IdentitySection,
    LoanDetailsSection,
    PerformanceSection,
    RelationshipsSection,
    TransactionsSection,
)
from .prompts import PROMPTS

SCHEMAS: dict[str, type[BaseModel]] = {
    "identity": IdentitySection,
    "performance": PerformanceSection,
    "relationships": RelationshipsSection,
    "transactions": TransactionsSection,
    "loan_details": LoanDetailsSection,
    "extras": ExtrasSection,
}


class GeminiVisionClient:
    def __init__(self, api_key: str, model: str = "gemini-2.5-flash") -> None:
        if not api_key:
            raise RuntimeError("GEMINI_API_KEY is required.")
        self.client = genai.Client(api_key=api_key)
        self.model = model

    @retry(stop=stop_after_attempt(3), wait=wait_exponential(multiplier=1, min=2, max=12), reraise=True)
    def extract(self, section: str, image_path: Path) -> BaseModel:
        schema = SCHEMAS[section]
        mime_type = mimetypes.guess_type(image_path.name)[0] or "image/png"
        image_part = types.Part.from_bytes(data=image_path.read_bytes(), mime_type=mime_type)
        response = self.client.models.generate_content(
            model=self.model,
            contents=[PROMPTS[section], image_part],
            config=types.GenerateContentConfig(
                response_mime_type="application/json",
                response_schema=schema,
                temperature=0,
            ),
        )
        if isinstance(response.parsed, schema):
            return response.parsed
        if not response.text:
            raise RuntimeError(f"Gemini returned no data for section {section}.")
        return schema.model_validate_json(response.text)
