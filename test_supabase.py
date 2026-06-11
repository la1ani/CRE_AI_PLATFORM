from dotenv import load_dotenv
import os
from supabase import create_client  # type: ignore

load_dotenv()

supabase = create_client(
    os.getenv("SUPABASE_URL"),
    os.getenv("SUPABASE_SERVICE_ROLE_KEY")
)

print("SUPABASE CONNECTED")