import sys
import os
sys.path.append(os.path.join(os.getcwd(), 'app'))

try:
    from app.rag_service import RAGService
    from app.api_server import app
    print("Imports successful")
except ImportError as e:
    print(f"Import failed: {e}")
    sys.exit(1)
