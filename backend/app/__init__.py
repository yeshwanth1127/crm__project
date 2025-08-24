import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Set SECRET_KEY globally
SECRET_KEY = os.getenv("SECRET_KEY")
if not SECRET_KEY:
    raise ValueError("SECRET_KEY environment variable is not set")
