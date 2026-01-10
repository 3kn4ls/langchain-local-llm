import os
import json
from pymongo import MongoClient
from langchain_core.tools import tool

# Configuracion
# En docker-compose, el hostname es el nombre del servicio: "mongo"
MONGO_URI = os.getenv("MONGO_URI", "mongodb://mongo:27017/")
DB_NAME = os.getenv("MONGO_DB_NAME", "agent_db")

def get_db():
    client = MongoClient(MONGO_URI)
    return client[DB_NAME]

@tool
def mongo_list_collections() -> str:
    """
    Lista las colecciones disponibles en la base de datos.
    Usa esta herramienta para ver que tipos de datos existen.
    """
    try:
        db = get_db()
        collections = db.list_collection_names()
        return f"Colecciones disponibles: {', '.join(collections)}"
    except Exception as e:
        return f"Error al listar colecciones: {e}"

@tool
def mongo_find(collection: str, query_json: str = "{}") -> str:
    """
    Busca documentos en una coleccion de MongoDB.
    
    Args:
        collection: Nombre de la coleccion
        query_json: Consulta en formato JSON string (ej: '{"nombre": "Juan"}')
    """
    try:
        db = get_db()
        # Verificar coleccion si es necesario, pero permitimos crear nuevas implicitamente en insert
        # Para find, si no existe retorna vacio
        
        import json
        if isinstance(query_json, dict):
            query = query_json
        else:
            try:
                query = json.loads(query_json)
            except:
                # Fallback si no es JSON valido, intentar tratar como dict vacio o error
                return f"Error: query_json no es un JSON valido: {query_json}"

        # Limitar resultados para no saturar al agente
        cursor = db[collection].find(query).limit(5)
        results = list(cursor)
        
        # Convertir ObjectId a string para serializacion
        for doc in results:
            if '_id' in doc:
                doc['_id'] = str(doc['_id'])
                
        if not results:
            return "No se encontraron documentos."
            
        return json.dumps(results, indent=2)
    except Exception as e:
        return f"Error en la busqueda: {e}"

@tool
def mongo_insert(collection: str, document_json: str) -> str:
    """
    Inserta un documento en una coleccion de MongoDB.
    
    Args:
        collection: Nombre de la coleccion
        document_json: Documento a insertar en formato JSON string
    """
    try:
        db = get_db()
        import json
        
        if isinstance(document_json, dict):
            document = document_json
        else:
            try:
                document = json.loads(document_json)
            except:
                 return f"Error: document_json no es un JSON valido: {document_json}"
        
        result = db[collection].insert_one(document)
        return f"Documento insertado con ID: {result.inserted_id}"
    except Exception as e:
        return f"Error al insertar: {e}"
