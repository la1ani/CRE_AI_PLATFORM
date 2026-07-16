from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageEnhance, ImageFilter


@dataclass(frozen=True)
class RelativeCrop:
    name: str
    left: float
    top: float
    right: float
    bottom: float


# Crops intentionally overlap. The supplied screenshots have consistent
# left identity panels and vertically stacked content, but section height varies.
DEFAULT_CROPS = (
    RelativeCrop("identity", 0.00, 0.00, 0.31, 0.25),
    RelativeCrop("performance", 0.25, 0.00, 1.00, 0.28),
    RelativeCrop("relationships", 0.24, 0.18, 1.00, 0.50),
    RelativeCrop("transactions", 0.24, 0.40, 1.00, 0.71),
    RelativeCrop("loan_details", 0.24, 0.60, 1.00, 0.91),
    RelativeCrop("extras", 0.24, 0.80, 1.00, 1.00),
)


class ProfileCropper:
    def __init__(self, scale: float = 2.0) -> None:
        self.scale = max(1.0, scale)

    def create_crops(self, image_path: Path, output_dir: Path) -> dict[str, Path]:
        output_dir.mkdir(parents=True, exist_ok=True)
        with Image.open(image_path) as source:
            image = source.convert("RGB")
            width, height = image.size
            results: dict[str, Path] = {}
            for spec in DEFAULT_CROPS:
                box = (
                    int(width * spec.left),
                    int(height * spec.top),
                    int(width * spec.right),
                    int(height * spec.bottom),
                )
                crop = image.crop(box)
                crop = crop.resize(
                    (int(crop.width * self.scale), int(crop.height * self.scale)),
                    Image.Resampling.LANCZOS,
                )
                crop = ImageEnhance.Contrast(crop).enhance(1.08)
                crop = ImageEnhance.Sharpness(crop).enhance(1.25)
                crop = crop.filter(ImageFilter.UnsharpMask(radius=1, percent=110, threshold=3))
                destination = output_dir / f"{spec.name}.png"
                crop.save(destination, format="PNG", optimize=True)
                results[spec.name] = destination
            return results
