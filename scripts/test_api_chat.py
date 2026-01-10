import urllib.request
import json
import sys

url = "http://localhost:8000/chat"
headers = {
    "accept": "application/json",
    "Content-Type": "application/json"
}
data = {
    "message": "Hola, confirma por favor si tienes acceso a MongoDB. Si es asi, busca las colecciones existentes y dime cuales son.",
    "history": [],
    "system_prompt": "Eres un asistente con capacidades extras. Tienes herramientas para usar MongoDB.",
    "temperature": 0.0,
    "model": "llama3.2"
}

try:
    req = urllib.request.Request(url, data=json.dumps(data).encode('utf-8'), headers=headers, method='POST')
    print(f"Sending request to {url}...")
    with urllib.request.urlopen(req) as response:
        print(f"Status Code: {response.getcode()}")
        result = json.loads(response.read().decode('utf-8'))
        print("Response JSON:")
        print(json.dumps(result, indent=2))
        
except Exception as e:
    print(f"Error: {e}")
