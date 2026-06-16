from __future__ import annotations

from pathlib import Path
from typing import Optional

from playwright.sync_api import BrowserContext, Page, Playwright, sync_playwright

from realtor_profile_downloader.config.settings import settings


class BrowserManager:
    """Launch Chrome once and reuse the same browser context for the full batch."""

    def __init__(self) -> None:
        self._playwright: Optional[Playwright] = None
        self.context: Optional[BrowserContext] = None
        self.page: Optional[Page] = None

    def start(self) -> Page:
        self._playwright = sync_playwright().start()

        user_data_dir = Path(settings.chrome_user_data_dir)
        user_data_dir.mkdir(parents=True, exist_ok=True)

        launch_args = [
            "--start-maximized",
            "--disable-blink-features=AutomationControlled",
            "--disable-dev-shm-usage",
            "--no-first-run",
            "--no-default-browser-check",
        ]

        kwargs = {
            "user_data_dir": str(user_data_dir),
            "headless": settings.headless,
            "accept_downloads": True,
            "downloads_path": str(settings.downloads_dir),
            "args": launch_args,
            "slow_mo": settings.slow_mo_ms,
            "viewport": None,
        }

        if settings.chrome_executable_path:
            kwargs["executable_path"] = settings.chrome_executable_path
        else:
            kwargs["channel"] = "chrome"

        self.context = self._playwright.chromium.launch_persistent_context(**kwargs)

        if self.context.pages:
            self.page = self.context.pages[0]
        else:
            self.page = self.context.new_page()

        self.page.set_default_timeout(settings.profile_load_timeout_ms)
        return self.page

    def new_page(self) -> Page:
        if not self.context:
            raise RuntimeError("Browser context is not started.")
        page = self.context.new_page()
        page.set_default_timeout(settings.profile_load_timeout_ms)
        return page

    def close(self) -> None:
        if self.context:
            self.context.close()
        if self._playwright:
            self._playwright.stop()
        self.context = None
        self.page = None
        self._playwright = None
