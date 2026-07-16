BASE_RULES = """
You are extracting structured data from one cropped section of a realtor profile screenshot.
Read only information visibly present in this image. Never guess, infer hidden table rows, or
complete truncated names. Use null when a value is unreadable. Preserve names and company
names as displayed. Footer text such as 'Showing 1 to 6 of 26 entries' means only the visible
rows can be extracted; record both visible and expected counts. Confidence must reflect image
readability and extraction certainty, not how favorable the profile looks.
""".strip()

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
