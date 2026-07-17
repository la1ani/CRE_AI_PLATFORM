from __future__ import annotations

import logging
import os

from dotenv import load_dotenv

from .drive_list_importer import import_drive_lists


def main() -> None:
    load_dotenv()
    logging.basicConfig(
        level=os.getenv("LOG_LEVEL", "INFO"),
        format="%(asctime)s [%(levelname)s] %(message)s",
    )
    result = import_drive_lists(
        spreadsheet_id=os.getenv("GOOGLE_SHEET_ID", "").strip(),
        service_account_file=os.getenv("GOOGLE_SERVICE_ACCOUNT_FILE", "").strip(),
    )
    print(
        "Drive import complete: "
        f"{result['realtors']} realtor(s), "
        f"{result['listings']} listing(s), "
        f"{result['loan_officers']} loan officer(s)."
    )
    if result["inaccessible"]:
        print("Sources still needing service-account Reader access:")
        for source in result["inaccessible"]:
            print(f"- {source}")
        print(f"Share those source Sheets with: {result['service_account_email']}")


if __name__ == "__main__":
    main()
