import os

# Ollama Settings
OLLAMA_BASE_URL = os.getenv("OLLAMA_BASE_URL", "http://localhost:11434")
DEFAULT_MODEL = os.getenv("MODEL_NAME", "llama3.2")
DEFAULT_EMBEDDING_MODEL = os.getenv("EMBEDDING_MODEL", "nomic-embed-text")

# API Server Settings
PORT = int(os.getenv("PORT", 8000))
MAX_INPUT_LENGTH = int(os.getenv("MAX_INPUT_LENGTH", 4096))
UPLOAD_DIR = os.getenv("UPLOAD_DIR", "./uploaded_files")

# Vector Database (ChromaDB) Settings
CHROMA_PERSIST_DIR = os.getenv("CHROMA_PERSIST_DIR", "./chroma_db")

# MongoDB Settings (for MCP)
MONGODB_URI = os.getenv("MONGODB_URI", "")
MONGODB_DATABASE = os.getenv("MONGODB_DATABASE", "")
MONGODB_TIMEOUT = int(os.getenv("MONGODB_TIMEOUT", 5000))
MONGODB_MAX_POOL_SIZE = int(os.getenv("MONGODB_MAX_POOL_SIZE", 10))

# Logging
LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO")
