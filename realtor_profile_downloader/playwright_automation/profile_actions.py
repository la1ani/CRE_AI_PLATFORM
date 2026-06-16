from __future__ import annotations

import re
import time
from typing import Iterable

from playwright.sync_api import Page, TimeoutError as PlaywrightTimeoutError

from realtor_profile_downloader.config.settings import settings


EXPAND_BUTTON_NAMES = [
    "Full Details",
    "View Full Profile",
    "Expand Profile",
    "View Details",
    "Show More",
    "Complete Profile",
    "View Complete Record",
    "See More",
    "More Details",
    "Read More",
]


class ProfileActions:
    def __init__(self, page: Page) -> None:
        self.page = page

    def open_profile(self, url: str) -> None:
        if not url.lower().startswith(("http://", "https://")):
            raise ValueError(f"Invalid profile URL: {url}")

        self.page.goto(url, wait_until="domcontentloaded", timeout=settings.profile_load_timeout_ms)
        self._safe_wait_load_state("networkidle", timeout=settings.profile_load_timeout_ms)
        self.page.wait_for_timeout(settings.profile_dynamic_wait_ms)
        self._wait_for_visible_body()

    def expand_profile_if_available(self) -> bool:
        for label in EXPAND_BUTTON_NAMES:
            if self._click_by_accessible_name(label):
                self._after_expand_wait()
                return True

        # Fallback: scan visible clickable elements and match similar text.
        candidates = self.page.locator("button, a, [role=button], input[type=button], input[type=submit]")
        count = min(candidates.count(), 250)
        wanted = [self._normalize(x) for x in EXPAND_BUTTON_NAMES]

        for idx in range(count):
            element = candidates.nth(idx)
            try:
                if not element.is_visible():
                    continue
                text = (element.inner_text(timeout=1000) or element.get_attribute("value") or "").strip()
                normalized = self._normalize(text)
                if not normalized:
                    continue
                if any(self._looks_similar(normalized, target) for target in wanted):
                    element.scroll_into_view_if_needed(timeout=5000)
                    element.click(timeout=10000)
                    self._after_expand_wait()
                    return True
            except Exception:
                continue

        return False

    def _click_by_accessible_name(self, label: str) -> bool:
        patterns = [
            re.compile(rf"^{re.escape(label)}$", re.I),
            re.compile(re.escape(label), re.I),
        ]
        for pattern in patterns:
            locators = [
                self.page.get_by_role("button", name=pattern),
                self.page.get_by_role("link", name=pattern),
                self.page.get_by_text(pattern),
            ]
            for locator in locators:
                try:
                    if locator.count() > 0 and locator.first.is_visible(timeout=1500):
                        locator.first.scroll_into_view_if_needed(timeout=5000)
                        locator.first.click(timeout=10000)
                        return True
                except Exception:
                    continue
        return False

    def _after_expand_wait(self) -> None:
        self.page.wait_for_timeout(1500)
        self._safe_wait_load_state("networkidle", timeout=20000)
        self.page.wait_for_timeout(settings.profile_dynamic_wait_ms)

    def _safe_wait_load_state(self, state: str, timeout: int) -> None:
        try:
            self.page.wait_for_load_state(state, timeout=timeout)
        except PlaywrightTimeoutError:
            pass

    def _wait_for_visible_body(self) -> None:
        self.page.locator("body").wait_for(state="visible", timeout=settings.profile_load_timeout_ms)

    @staticmethod
    def _normalize(text: str) -> str:
        return re.sub(r"[^a-z0-9]+", " ", text.lower()).strip()

    @staticmethod
    def _looks_similar(candidate: str, target: str) -> bool:
        if candidate == target:
            return True
        if target in candidate or candidate in target:
            return True
        candidate_words = set(candidate.split())
        target_words = set(target.split())
        if not candidate_words or not target_words:
            return False
        overlap = len(candidate_words & target_words) / max(len(target_words), 1)
        return overlap >= 0.6
