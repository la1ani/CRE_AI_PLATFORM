"""Generate HTML deal reports from Supabase property data."""

from __future__ import annotations

import datetime
import html
import logging
import sys
from pathlib import Path
from typing import Any, Dict, Iterable, List

# Ensure the repository root is on sys.path so report generator can be
# executed directly from the reports/ directory.
ROOT_DIR = Path(__file__).resolve().parents[1]
if str(ROOT_DIR) not in sys.path:
    sys.path.insert(0, str(ROOT_DIR))

from database.supabase_client import SupabaseClient

logger = logging.getLogger(__name__)


def _normalize_numeric(value: Any) -> float:
    if value is None:
        return 0.0
    if isinstance(value, (int, float)):
        return float(value)
    try:
        return float(str(value).replace("%", "").replace("$", "").replace(",", ""))
    except Exception:
        return 0.0


def _score_completeness(property_data: Dict[str, Any]) -> float:
    keys = [
        "property_name",
        "address",
        "property_type",
        "asking_price",
        "noi",
        "cap_rate",
        "occupancy",
        "building_sf",
        "land_sf",
        "year_built",
        "broker_name",
        "broker_email",
    ]
    present = sum(1 for key in keys if property_data.get(key))
    return round(present / len(keys) * 100, 2)


def _sort_properties(properties: Iterable[Dict[str, Any]]) -> List[Dict[str, Any]]:
    def score_item(item: Dict[str, Any]) -> tuple[float, float, float, float]:
        noi = _normalize_numeric(item.get("noi"))
        cap_rate = _normalize_numeric(item.get("cap_rate"))
        occupancy = _normalize_numeric(item.get("occupancy"))
        completeness = _score_completeness(item)
        return (
            noi,
            cap_rate,
            occupancy,
            completeness,
        )

    return sorted(
        properties,
        key=score_item,
        reverse=True,
    )


def _render_table(properties: List[Dict[str, Any]], title: str) -> str:
    rows = []
    for prop in properties:
        rows.append(
            """
            <tr>
              <td>{name}</td>
              <td>{property_type}</td>
              <td>{address}</td>
              <td>{noi}</td>
              <td>{cap_rate}</td>
              <td>{occupancy}</td>
              <td>{completeness}</td>
            </tr>
            """.format(
                name=html.escape(str(prop.get("property_name", "")) or "-"),
                property_type=html.escape(str(prop.get("property_type", "")) or "-"),
                address=html.escape(str(prop.get("address", "")) or "-"),
                noi=html.escape(str(prop.get("noi", "")) or "-"),
                cap_rate=html.escape(str(prop.get("cap_rate", "")) or "-"),
                occupancy=html.escape(str(prop.get("occupancy", "")) or "-"),
                completeness=html.escape(str(_score_completeness(prop))) if prop else "-",
            )
        )
    return f"""
    <h2>{html.escape(title)}</h2>
    <table>
      <thead>
        <tr>
          <th>Property Name</th>
          <th>Type</th>
          <th>Address</th>
          <th>NOI</th>
          <th>Cap Rate</th>
          <th>Occupancy</th>
          <th>Completeness</th>
        </tr>
      </thead>
      <tbody>
        {''.join(rows)}
      </tbody>
    </table>
    """


def _section_heading(title: str) -> str:
    return f"<section><h1>{html.escape(title)}</h1>"


def _section_footer() -> str:
    return "</section>"


def _build_html(report_sections: List[str]) -> str:
    timestamp = datetime.datetime.utcnow().strftime("%Y-%m-%d %H:%M UTC")
    body = "".join(report_sections)
    return f"""
<!DOCTYPE html>
<html lang=\"en\">
<head>
  <meta charset=\"utf-8\" />
  <title>CRE AI Platform Top Deals Report</title>
  <style>
    body {{ font-family: Arial, sans-serif; margin: 2rem; }}
    h1 {{ color: #223a5e; }}
    table {{ border-collapse: collapse; width: 100%; margin-bottom: 2rem; }}
    th, td {{ border: 1px solid #ccc; padding: 8px; text-align: left; }}
    th {{ background: #f2f5fb; }}
    tr:nth-child(even) {{ background: #f9fbff; }}
  </style>
</head>
<body>
  <h1>Top Deals Report</h1>
  <p>Generated: {html.escape(timestamp)}</p>
  {body}
</body>
</html>
"""


def generate_report(output_path: Path | str) -> None:
    client = SupabaseClient()

    all_props = client.fetch_properties(limit=500)
    if not all_props:
        logger.warning("No properties found in Supabase to build reports.")

    sections: List[str] = []

    top_deals = _sort_properties(all_props)[:25]
    sections.append(_section_heading("Top Deals"))
    sections.append(_render_table(top_deals, "Top Deals"))
    sections.append(_section_footer())

    multifamily = [p for p in all_props if str(p.get("property_type", "")).lower() == "multifamily"]
    retail = [p for p in all_props if str(p.get("property_type", "")).lower() == "retail"]

    sections.append(_section_heading("Multifamily Report"))
    sections.append(_render_table(_sort_properties(multifamily)[:25], "Top Multifamily Deals"))
    sections.append(_section_footer())

    sections.append(_section_heading("Retail Report"))
    sections.append(_render_table(_sort_properties(retail)[:25], "Top Retail Deals"))
    sections.append(_section_footer())

    report_html = _build_html(sections)
    output_file = Path(output_path)
    output_file.parent.mkdir(parents=True, exist_ok=True)
    output_file.write_text(report_html, encoding="utf-8")
    logger.info("Report written to %s", output_file)


def main() -> None:
    output_file = Path(__file__).resolve().parent / "top_deals_report.html"
    generate_report(output_file)


if __name__ == "__main__":
    main()
