import os
import sys
from pymongo import MongoClient
import time

# Add app directory to path to import tools if needed, though we will test raw connection first
sys.path.append(os.path.join(os.getcwd(), 'app'))

def test_mongo_connection():
    print("Testing MongoDB Connection...")
    
    # URL default for localhost if running outside docker but connecting to exposed port
    uri = "mongodb://localhost:27017/"
    print(f"Connecting to: {uri}")
    
    try:
        client = MongoClient(uri, serverSelectionTimeoutMS=2000)
        # Force connection verification
        client.admin.command('ping')
        print("[SUCCESS] Connected to MongoDB!")
        
        db = client["test_db"]
        collection = db["test_collection"]
        
        # Test Insert
        print("Testing Insert...")
        result = collection.insert_one({"test": "data", "timestamp": time.time()})
        print(f"[SUCCESS] Inserted document with ID: {result.inserted_id}")
        
        # Test Find
        print("Testing Find...")
        doc = collection.find_one({"_id": result.inserted_id})
        print(f"[SUCCESS] Found document: {doc}")
        
        # Cleanup
        collection.delete_one({"_id": result.inserted_id})
        print("[SUCCESS] Cleaned up test document.")
        
    except Exception as e:
        print(f"\n[ERROR] Failed to connect or perform operations: {e}")
        print("\nPossible reasons:")
        print("1. MongoDB container is not running.")
        print("2. Port 27017 is not exposed or mapped correctly.")
        print("3. Firewall issues.")
        print("\nPlease run: 'docker-compose up -d mongo' or 'docker-compose up -d --build'")

if __name__ == "__main__":
    test_mongo_connection()
