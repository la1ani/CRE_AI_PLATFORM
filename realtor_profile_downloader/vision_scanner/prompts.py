BASE_RULES = """
You are extracting structured data from saved screenshots of one realtor profile.
Read only information visibly present in the supplied images. Never guess, infer hidden table
rows, or complete truncated names. Use null when a value is unreadable. Preserve names and
company names exactly as displayed. Footer text such as 'Showing 1 to 6 of 26 entries' means
only the visible rows can be extracted; record both visible and expected counts. Confidence
must reflect image readability and extraction certainty, not how favorable the profile looks.
""".strip()


COMBINED_PROMPT = BASE_RULES + """

The request contains up to six labeled images from the same realtor profile. Each label is
provided immediately before its image. Populate every section of the requested JSON schema:

- identity: left identity card, contact details, summary metrics, languages and visible social icons.
- performance: Agent Performance Summary, loan-type values, and readable monthly production values.
- relationships: loan-officer relationships, loan-company relationships, totals and connection counts.
- transactions: every fully or substantially visible Agent Transaction Details row and footer counts.
- loan_details: retail/wholesale shares, top loan companies, visible loan rows and footer counts.
- extras: title-company relationships and recent listings; use empty arrays when absent.

Cross-check values repeated in different images, but do not manufacture missing information. Return
one JSON object matching the complete ProfileExtraction schema.
""".strip()


# Kept for compatibility with any older code that still performs section-by-section extraction.
PROMPTS = {
    "identity": BASE_RULES + "\nExtract the left identity card and its summary metrics.",
    "performance": BASE_RULES
    + "\nExtract Agent Performance Summary, loan-type chart labels/values when readable, and monthly chart values only when labels are readable.",
    "relationships": BASE_RULES
    + "\nExtract buyer-side loan officer relationships, loan-company relationships, reported totals, and mutual connection counts.",
    "transactions": BASE_RULES
    + "\nExtract every fully or substantially visible Agent Transaction Details row and the table footer counts.",
    "loan_details": BASE_RULES
    + "\nExtract Agent Loan Details, top loan companies, retail/wholesale shares, every visible loan row, and footer counts.",
    "extras": BASE_RULES
    + "\nExtract Title Company Relationships and Recent Listings when present. Return empty arrays when these sections are absent.",
}
