# Documentación Completa del Proyecto
# LangChain + Ollama en Docker

---

## Índice

1. [Introducción](#introducción)
2. [¿Qué es este proyecto?](#qué-es-este-proyecto)
3. [Conceptos básicos de IA](#conceptos-básicos-de-ia)
4. [Arquitectura del sistema](#arquitectura-del-sistema)
5. [Estructura de archivos](#estructura-de-archivos)
6. [Casos de uso prácticos](#casos-de-uso-prácticos)
7. [Ejemplos de código explicados](#ejemplos-de-código-explicados)
8. [Mejores prácticas](#mejores-prácticas)
9. [Solución de problemas](#solución-de-problemas)

---

# Introducción

Este proyecto te permite **ejecutar modelos de inteligencia artificial en tu propia computadora, sin costes y sin internet** (después de la instalación inicial).

## ¿Para quién es esto?

- Desarrolladores que quieren experimentar con IA sin pagar APIs
- Empresas que necesitan privacidad de datos (todo local)
- Estudiantes aprendiendo sobre LLMs y LangChain
- Cualquier persona interesada en IA pero sin conocimientos técnicos profundos

## ¿Qué NO necesitas?

- ❌ Pagar por APIs de OpenAI, Claude, etc.
- ❌ Conexión a internet constante
- ❌ Conocimientos avanzados de IA
- ❌ GPU potente (funciona con CPU, aunque más lento)

---

# ¿Qué es este proyecto?

Este proyecto combina tres tecnologías principales:

## 1. Docker
**¿Qué es?** Plataforma para ejecutar aplicaciones en "contenedores" aislados.

**Analogía:** Imagina que Docker es como tener varias computadoras virtuales dentro de tu PC. Cada contenedor es como una mini-computadora que ejecuta un programa específico, sin interferir con tu sistema principal.

**Ventajas:**
- No ensucias tu sistema con instalaciones complejas
- Funciona igual en Windows, Mac y Linux
- Fácil de desinstalar (solo borras los contenedores)

---

## 2. Ollama
**¿Qué es?** Servidor que ejecuta modelos de lenguaje (LLMs) en tu computadora.

**Analogía:** Es como tener ChatGPT corriendo en tu PC. Puedes hacerle preguntas, pedirle que escriba código, resuma textos, traduzca idiomas, etc.

**Características:**
- 100% gratuito y open source
- No envía tus datos a internet
- Soporta modelos de Meta (Llama), Google (Gemma), Microsoft (Phi-3), etc.
- Optimizado para CPU y GPU

**Modelos populares:**
- **Llama 3.2** (4.7 GB) - Excelente calidad, uso general
- **Mistral** (4.1 GB) - Bueno para código y razonamiento
- **Phi-3 Mini** (2.3 GB) - Ligero, ideal para PCs con poca RAM

---

## 3. LangChain
**¿Qué es?** Framework para construir aplicaciones con modelos de IA.

**Analogía:** Si Ollama es el "motor" de un coche, LangChain es el "volante, pedales y panel de control" que te permite manejarlo fácilmente.

**¿Qué puedes hacer con LangChain?**
- Chatbots con memoria (recuerda conversaciones anteriores)
- RAG (Retrieval Augmented Generation) - responde preguntas sobre tus documentos
- Agentes con herramientas (calculadora, búsqueda web, bases de datos)
- Análisis de sentimientos, resúmenes, traducciones
- Pipelines complejos con múltiples pasos

---

# Conceptos Básicos de IA

## ¿Qué es un LLM (Large Language Model)?

**Definición simple:** Un programa de inteligencia artificial entrenado con billones de palabras de internet para entender y generar texto humano.

**¿Cómo funciona?**
1. Tú escribes un "prompt" (pregunta o instrucción)
2. El modelo procesa tu texto
3. Predice cuál es la respuesta más probable, palabra por palabra
4. Genera una respuesta coherente

**Ejemplos famosos:**
- GPT-4 (OpenAI) - El más potente, pero de pago
- Claude (Anthropic) - Bueno para conversaciones largas
- Llama 3 (Meta) - Open source, funciona localmente
- Gemini (Google) - Multimodal (texto + imágenes)

---

## ¿Qué es un "Prompt"?

**Definición:** La instrucción o pregunta que le das al modelo de IA.

**Ejemplo básico:**
```
Prompt: "Explica qué es Docker en 2 oraciones."
Respuesta: "Docker es una plataforma que permite empaquetar aplicaciones en contenedores..."
```

**Ejemplo avanzado (con contexto):**
```
Prompt: "Eres un experto en arquitectura de software.
Explica el patrón CQRS y cuándo usarlo."
Respuesta: "CQRS (Command Query Responsibility Segregation) es un patrón que separa..."
```

**Mejores prácticas para prompts:**
- Sé específico: "Resume este artículo en 3 puntos" vs "Resume esto"
- Da contexto: "Eres un profesor de matemáticas..."
- Pide formato: "Responde en JSON" o "Dame una lista numerada"

---

## ¿Qué es RAG (Retrieval Augmented Generation)?

**Problema:** Los LLMs solo "saben" lo que aprendieron durante su entrenamiento. No conocen tus documentos privados ni información reciente.

**Solución: RAG**

### ¿Cómo funciona RAG?

1. **Indexación (una sola vez):**
   - Tomas tus documentos (PDFs, Word, TXT)
   - Los divides en fragmentos pequeños
   - Conviertes cada fragmento en "embeddings" (representación numérica)
   - Los guardas en una base de datos vectorial (ChromaDB, Pinecone, etc.)

2. **Búsqueda (cuando haces una pregunta):**
   - Tu pregunta se convierte en embedding
   - Se buscan los fragmentos más similares en la base de datos
   - Se combinan con tu pregunta
   - Se envían al LLM para generar la respuesta

**Ejemplo práctico:**

Imagina que tienes 100 PDFs sobre tu empresa. Con RAG:
```
Usuario: "¿Cuál es la política de vacaciones?"
Sistema:
  1. Busca en los PDFs fragmentos sobre "vacaciones"
  2. Encuentra: "Los empleados tienen 22 días laborables..."
  3. Envía al LLM: "Basándote en este texto: [...] responde: ¿Cuál es la política de vacaciones?"
  4. LLM: "Según la documentación, los empleados tienen 22 días laborables de vacaciones..."
```

**Ventajas de RAG:**
- El LLM responde con TUS datos, no con información genérica
- Puedes actualizar los documentos sin reentrenar el modelo
- Citas las fuentes (de qué documento viene la respuesta)

---

## ¿Qué son los "Embeddings"?

**Definición:** Representación numérica (vector) de un texto que captura su significado.

**Analogía:** Es como traducir palabras a coordenadas en un mapa. Palabras con significados similares están cerca en el mapa.

**Ejemplo:**
```
"perro" → [0.2, 0.8, 0.1, ...]  (300-1536 números)
"gato"  → [0.19, 0.82, 0.09, ...] (muy cerca de "perro")
"coche" → [0.7, 0.1, 0.9, ...]   (lejos de "perro")
```

**¿Para qué sirven?**
- Buscar textos similares (RAG)
- Agrupar documentos por temas
- Detectar duplicados
- Sistemas de recomendación

**Modelo de embeddings usado en este proyecto:**
- **nomic-embed-text** (274 MB)
- Genera vectores de 768 dimensiones
- Optimizado para búsqueda semántica

---

## ¿Qué es la "Temperatura" en un LLM?

**Definición:** Parámetro que controla cuán "creativo" o "aleatorio" es el modelo.

**Rango:** 0.0 a 1.0 (a veces hasta 2.0)

**Temperatura 0.0 (Determinista):**
- Siempre elige la palabra más probable
- Respuestas consistentes y predecibles
- Ideal para: código, análisis técnico, extracción de datos

**Temperatura 0.7 (Balanceado - Default):**
- Mezcla probabilidad con algo de aleatoriedad
- Respuestas naturales pero coherentes
- Ideal para: conversaciones, creatividad moderada

**Temperatura 1.0+ (Creativo):**
- Elige palabras menos probables
- Respuestas más variadas y sorprendentes
- Ideal para: escritura creativa, brainstorming

**Ejemplo:**

Prompt: "Escribe un slogan para una cafetería"

Temperatura 0.0:
- "Café de calidad premium para empezar tu día"

Temperatura 0.7:
- "Donde cada taza cuenta una historia"

Temperatura 1.0:
- "Despierta tus sueños, una nube de espuma a la vez"

---

# Arquitectura del Sistema

## Diagrama de Componentes

```
┌─────────────────────────────────────────────────────────────────┐
│                        TU COMPUTADORA                            │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                    Docker Desktop                        │   │
│  │                                                          │   │
│  │  ┌───────────────────────┐    ┌──────────────────────┐  │   │
│  │  │   Contenedor 1:       │    │   Contenedor 2:      │  │   │
│  │  │   ollama-server       │    │   langchain-app      │  │   │
│  │  │                       │    │                      │  │   │
│  │  │  ┌─────────────────┐ │    │  ┌────────────────┐  │  │   │
│  │  │  │  Servidor HTTP  │ │    │  │  Python 3.11   │  │  │   │
│  │  │  │  Puerto 11434   │ │◄───┤  │  + LangChain   │  │  │   │
│  │  │  └─────────────────┘ │    │  │  + FastAPI     │  │  │   │
│  │  │                       │    │  └────────────────┘  │  │   │
│  │  │  ┌─────────────────┐ │    │                      │  │   │
│  │  │  │  Motor de IA    │ │    │  Puerto 8000 (API)   │  │   │
│  │  │  │  (llama.cpp)    │ │    │                      │  │   │
│  │  │  └─────────────────┘ │    └──────────────────────┘  │   │
│  │  │         ▲             │               ▲              │   │
│  │  └─────────┼─────────────┘               │              │   │
│  │            │                             │              │   │
│  │            ▼                             ▼              │   │
│  │  ┌─────────────────┐          ┌──────────────────┐     │   │
│  │  │  Volumen:       │          │  Volumen:        │     │   │
│  │  │  ollama_data    │          │  ./app (sync)    │     │   │
│  │  │                 │          │                  │     │   │
│  │  │ • Llama 3.2     │          │ • main.py        │     │   │
│  │  │ • nomic-embed   │          │ • rag_example.py │     │   │
│  │  │ (~5 GB)         │          │ • api_server.py  │     │   │
│  │  └─────────────────┘          └──────────────────┘     │   │
│  │                                                          │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                  │
│  Acceso desde:                                                  │
│  • Terminal: docker exec -it langchain-app python main.py      │
│  • Navegador: http://localhost:8000                            │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Flujo de Datos: Ejemplo de Chat

```
1. Usuario escribe:
   "¿Qué es Docker?"

2. LangChain App (Python):
   - Recibe la pregunta
   - Crea un prompt estructurado
   - Envía solicitud HTTP a Ollama

3. Ollama Server:
   - Recibe: POST http://localhost:11434/api/generate
   - Carga el modelo Llama 3.2 en memoria
   - Procesa el prompt token por token

4. Motor de IA (llama.cpp):
   - Realiza billones de cálculos matemáticos
   - Predice la siguiente palabra más probable
   - Repite hasta completar la respuesta

5. Ollama Server:
   - Devuelve la respuesta a LangChain

6. LangChain App:
   - Procesa la respuesta
   - La muestra al usuario

Tiempo total: 1-5 segundos (CPU) o 0.2-1s (GPU)
```

---

## Flujo de Datos: Ejemplo de RAG

```
1. Preparación (una sola vez):
   Usuario: "Indexa este PDF sobre la empresa"

   a) LangChain lee el PDF
   b) Lo divide en chunks (fragmentos de ~500 palabras)
   c) Para cada chunk:
      - Envía a Ollama: "Genera embedding de: [chunk]"
      - Ollama usa nomic-embed-text
      - Devuelve un vector de 768 números
   d) Guarda en ChromaDB:
      {chunk: "El horario es...", vector: [0.2, 0.8, ...]}

2. Consulta:
   Usuario: "¿Cuál es el horario de trabajo?"

   a) LangChain genera embedding de la pregunta
   b) Busca en ChromaDB los 3 chunks más similares
   c) Construye prompt:
      """
      Contexto:
      1. "El horario es de 9-18h..."
      2. "Los viernes salimos a las 15h..."
      3. "Se puede trabajar remoto 2 días..."

      Pregunta: ¿Cuál es el horario de trabajo?
      """
   d) Envía a Ollama
   e) Ollama genera respuesta basada en el contexto
   f) Respuesta: "El horario es de 9 a 18h, con salida anticipada..."
```

---

# Estructura de Archivos

```
langchain-local-llm/
│
├── docker-compose.yml           # Configuración de servicios Docker
├── Dockerfile                   # Instrucciones para construir la imagen de la app
├── requirements.txt             # Dependencias de Python
├── .env.example                 # Variables de entorno (ejemplo)
├── README.md                    # Guía de inicio rápido
│
├── DOCKER_COMPOSE_EXPLICADO.md  # ← Documentación detallada de Docker
├── DOCUMENTACION_COMPLETA.md    # ← Este archivo
├── GLOSARIO.md                  # ← Términos de IA explicados
│
├── app/                         # Código de la aplicación
│   ├── main.py                  # Ejemplos básicos de LangChain
│   ├── rag_example.py           # Sistema RAG completo
│   ├── api_server.py            # API REST con FastAPI
│   └── agent_example.py         # Agente con herramientas
│
└── scripts/                     # Scripts de utilidad
    ├── setup.ps1                # Configuración automática (PowerShell)
    └── test_connection.py       # Verificar conexión con Ollama
```

---

## Descripción Detallada de Archivos

### `docker-compose.yml`
**Función:** Orquesta los dos contenedores (Ollama y LangChain App)

**Qué define:**
- Qué imágenes usar
- Qué puertos exponer
- Qué volúmenes montar
- Orden de inicio (dependencias)
- Variables de entorno

**Ver:** `DOCKER_COMPOSE_EXPLICADO.md` para explicación línea por línea

---

### `Dockerfile`
**Función:** Instrucciones para construir la imagen de LangChain App

**Qué hace:**
1. Usa Python 3.11 como base
2. Instala dependencias del sistema (curl)
3. Copia `requirements.txt`
4. Instala dependencias Python (LangChain, FastAPI, etc.)
5. Copia el código de `app/`
6. Define comando por defecto

**Cuándo se usa:** Al ejecutar `docker-compose up` por primera vez

---

### `requirements.txt`
**Función:** Lista de paquetes Python necesarios

**Dependencias principales:**
- `langchain` - Framework principal
- `langchain-ollama` - Integración con Ollama
- `chromadb` - Base de datos vectorial para RAG
- `fastapi` - Framework web para crear APIs
- `uvicorn` - Servidor web para FastAPI

---

### `app/main.py`
**Función:** 6 ejemplos prácticos de LangChain

**Contenido:**
1. Chat simple
2. Prompts con templates
3. Conversación con memoria
4. Chain de múltiples pasos
5. Streaming de respuestas
6. Salida estructurada (JSON)

**Uso:**
```powershell
docker exec -it langchain-app python main.py
```

---

### `app/rag_example.py`
**Función:** Sistema RAG completo

**Características:**
- Carga documentos de texto
- Los divide en chunks
- Genera embeddings con nomic-embed-text
- Almacena en ChromaDB
- Responde preguntas basadas en los documentos

**Uso:**
```powershell
docker exec -it langchain-app python rag_example.py
```

---

### `app/api_server.py`
**Función:** API REST para integrar LangChain en otras aplicaciones

**Endpoints:**
- `GET /` - Health check
- `GET /models` - Listar modelos disponibles
- `POST /chat` - Chat simple
- `POST /chat/stream` - Chat con streaming
- `POST /analyze` - Análisis de texto

**Uso:**
```powershell
# Iniciar servidor
docker exec -it langchain-app python api_server.py

# En otro terminal:
curl -X POST http://localhost:8000/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Hola"}'
```

---

### `app/agent_example.py`
**Función:** Agente de IA con herramientas

**Herramientas incluidas:**
- Calculadora matemática
- Obtener fecha/hora actual
- Búsqueda en base de conocimiento
- Conversión de unidades

**Ejemplo:**
```
Usuario: "¿Cuánto es 25% de 480?"
Agente:
  1. Detecta que necesita calcular
  2. Usa la herramienta "calculadora"
  3. Ejecuta: 480 * 0.25 = 120
  4. Responde: "25% de 480 es 120"
```

---

# Casos de Uso Prácticos

## 1. Chatbot de Soporte al Cliente

**Problema:** Necesitas un chatbot para tu sitio web que responda preguntas frecuentes.

**Solución con RAG:**
1. Indexa tus FAQs, manuales de producto, políticas
2. El chatbot busca en tus documentos
3. Responde con información precisa de tu empresa

**Código simplificado:**
```python
from langchain_ollama import ChatOllama
from langchain.chains import RetrievalQA
from langchain_community.vectorstores import Chroma

# Cargar base de conocimiento
vectorstore = Chroma(persist_directory="./faqs_db")

# Crear chain RAG
qa_chain = RetrievalQA.from_chain_type(
    llm=ChatOllama(model="llama3.2"),
    retriever=vectorstore.as_retriever()
)

# Usar
respuesta = qa_chain.invoke("¿Cuál es la política de devoluciones?")
```

---

## 2. Análisis de Sentimientos en Reseñas

**Problema:** Tienes miles de reseñas de productos y quieres saber si son positivas o negativas.

**Solución:**
```python
from langchain_ollama import ChatOllama
from langchain_core.prompts import ChatPromptTemplate

llm = ChatOllama(model="llama3.2", temperature=0.1)

prompt = ChatPromptTemplate.from_template("""
Analiza el sentimiento de esta reseña:

"{review}"

Responde SOLO con uno de estos: POSITIVO, NEGATIVO, NEUTRAL
""")

chain = prompt | llm

# Procesar múltiples reseñas
reseñas = [
    "Me encanta este producto, es perfecto!",
    "Horrible, no funciona y el soporte no responde",
    "Es normal, cumple su función"
]

for review in reseñas:
    sentimiento = chain.invoke({"review": review})
    print(f"Reseña: {review}\nSentimiento: {sentimiento}\n")
```

---

## 3. Generador de Código

**Problema:** Necesitas generar código repetitivo (APIs, tests, etc.)

**Solución:**
```python
from langchain_ollama import ChatOllama

llm = ChatOllama(model="llama3.2", temperature=0.3)

prompt = """
Genera una función Python que:
1. Recibe una lista de números
2. Retorna solo los números pares
3. Incluye docstring y type hints
"""

codigo = llm.invoke(prompt)
print(codigo.content)
```

**Salida:**
```python
def filtrar_pares(numeros: list[int]) -> list[int]:
    """
    Filtra una lista de números y retorna solo los pares.

    Args:
        numeros: Lista de números enteros

    Returns:
        Lista con solo los números pares
    """
    return [n for n in numeros if n % 2 == 0]
```

---

## 4. Resumen de Documentos Largos

**Problema:** Tienes PDFs de 50 páginas y necesitas un resumen ejecutivo.

**Solución:**
```python
from langchain_community.document_loaders import PyPDFLoader
from langchain.chains.summarize import load_summarize_chain
from langchain_ollama import ChatOllama

# Cargar PDF
loader = PyPDFLoader("informe_anual.pdf")
documentos = loader.load()

# Crear chain de resumen
llm = ChatOllama(model="llama3.2")
chain = load_summarize_chain(llm, chain_type="map_reduce")

# Generar resumen
resumen = chain.invoke(documentos)
print(resumen["output_text"])
```

---

## 5. Traductor Multilingüe

**Problema:** Traducir contenido de tu app a múltiples idiomas.

**Solución:**
```python
from langchain_ollama import ChatOllama
from langchain_core.prompts import ChatPromptTemplate

llm = ChatOllama(model="llama3.2", temperature=0.2)

prompt = ChatPromptTemplate.from_template("""
Traduce el siguiente texto del {idioma_origen} al {idioma_destino}.
Mantén el tono y formato original.

Texto: {texto}

Traducción:
""")

chain = prompt | llm

# Traducir
resultado = chain.invoke({
    "idioma_origen": "español",
    "idioma_destino": "inglés",
    "texto": "Bienvenido a nuestra aplicación"
})
```

---

# Ejemplos de Código Explicados

## Ejemplo 1: Chat Simple

```python
from langchain_ollama import ChatOllama

# 1. Crear instancia del modelo
llm = ChatOllama(
    model="llama3.2",           # Modelo a usar
    base_url="http://ollama:11434",  # URL del servidor Ollama
    temperature=0.7             # Creatividad (0-1)
)

# 2. Invocar con un prompt
response = llm.invoke("Explica qué es Python")

# 3. Obtener respuesta
print(response.content)
```

**Explicación:**
- `ChatOllama`: Clase que se conecta a Ollama
- `invoke()`: Envía el prompt y espera la respuesta completa
- `response.content`: El texto generado por el modelo

---

## Ejemplo 2: Prompt Template (Reutilizable)

```python
from langchain_ollama import ChatOllama
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser

llm = ChatOllama(model="llama3.2")

# 1. Crear template con variables
prompt = ChatPromptTemplate.from_messages([
    ("system", "Eres un experto en {tema}."),
    ("human", "{pregunta}")
])

# 2. Crear chain (prompt + llm + parser)
chain = prompt | llm | StrOutputParser()

# 3. Usar con diferentes valores
respuesta1 = chain.invoke({
    "tema": "programación Python",
    "pregunta": "¿Qué es una list comprehension?"
})

respuesta2 = chain.invoke({
    "tema": "marketing digital",
    "pregunta": "¿Qué es el SEO?"
})
```

**Ventajas:**
- Reutilizas el mismo template con diferentes valores
- Mantienes la estructura del prompt consistente
- Fácil de testear y modificar

---

## Ejemplo 3: Conversación con Memoria

```python
from langchain_ollama import ChatOllama
from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder
from langchain_core.messages import HumanMessage, AIMessage

llm = ChatOllama(model="llama3.2")

prompt = ChatPromptTemplate.from_messages([
    ("system", "Eres un asistente útil."),
    MessagesPlaceholder(variable_name="history"),  # Historial
    ("human", "{input}")
])

chain = prompt | llm

# Simular conversación
history = []

# Turno 1
user_msg = "Me llamo Carlos"
history.append(HumanMessage(content=user_msg))
response = chain.invoke({"history": history, "input": user_msg})
history.append(AIMessage(content=response.content))

# Turno 2
user_msg = "¿Cómo me llamo?"  # El modelo recuerda!
history.append(HumanMessage(content=user_msg))
response = chain.invoke({"history": history, "input": user_msg})
# Respuesta: "Te llamas Carlos"
```

**Concepto clave:**
- `history` es una lista de mensajes (humano ↔ AI)
- El modelo ve todo el historial en cada invocación
- Puede "recordar" información de turnos anteriores

---

## Ejemplo 4: Streaming (Respuestas en Tiempo Real)

```python
from langchain_ollama import ChatOllama

llm = ChatOllama(model="llama3.2")

# En lugar de invoke(), usa stream()
for chunk in llm.stream("Escribe un poema sobre programación"):
    print(chunk.content, end="", flush=True)
```

**Salida:**
```
En el silencio de la noche,
el código fluye sin reproche.
Variables danzan en la pantalla,
while bucles cantan su batalla...
```

**Ventaja:** El usuario ve la respuesta generándose palabra por palabra, como ChatGPT.

---

## Ejemplo 5: RAG Básico

```python
from langchain_community.document_loaders import TextLoader
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain_community.vectorstores import Chroma
from langchain_ollama import OllamaEmbeddings, ChatOllama
from langchain.chains import RetrievalQA

# 1. Cargar documentos
loader = TextLoader("mi_empresa.txt")
documentos = loader.load()

# 2. Dividir en chunks
splitter = RecursiveCharacterTextSplitter(
    chunk_size=500,    # Tamaño de cada fragmento
    chunk_overlap=50   # Overlap para mantener contexto
)
chunks = splitter.split_documents(documentos)

# 3. Generar embeddings y guardar en ChromaDB
embeddings = OllamaEmbeddings(model="nomic-embed-text")
vectorstore = Chroma.from_documents(
    documents=chunks,
    embedding=embeddings,
    persist_directory="./db"
)

# 4. Crear chain de RAG
llm = ChatOllama(model="llama3.2")
qa_chain = RetrievalQA.from_chain_type(
    llm=llm,
    retriever=vectorstore.as_retriever(search_kwargs={"k": 3})
)

# 5. Hacer preguntas
respuesta = qa_chain.invoke("¿Cuál es la misión de la empresa?")
print(respuesta["result"])
```

**Flujo:**
1. Cargas un archivo de texto
2. Lo divides en fragmentos de ~500 caracteres
3. Conviertes cada fragmento en un vector (embedding)
4. Los guardas en ChromaDB
5. Cuando preguntas algo, busca los 3 fragmentos más relevantes
6. Los envía al LLM junto con tu pregunta

---

# Mejores Prácticas

## 1. Gestión de Recursos

### RAM
```yaml
# docker-compose.yml
services:
  ollama:
    deploy:
      resources:
        limits:
          memory: 12G  # Limitar RAM máxima
```

**Recomendaciones:**
- Modelo pequeño (phi3:mini): 6 GB RAM
- Modelo mediano (llama3.2): 12 GB RAM
- Modelo grande (llama3.1:70b): 64 GB RAM

---

### Disco
```powershell
# Limpiar modelos no usados
docker exec ollama-server ollama rm mistral

# Ver espacio usado
docker system df
```

---

## 2. Optimización de Prompts

### ❌ Prompt Vago
```python
llm.invoke("Dime sobre Python")
```

### ✅ Prompt Específico
```python
llm.invoke("""
Explica el concepto de "list comprehension" en Python.
Incluye:
1. Definición en 1 oración
2. Ejemplo de código
3. Cuándo usarlo vs un for loop
""")
```

---

## 3. Manejo de Errores

```python
import httpx
from langchain_ollama import ChatOllama

try:
    llm = ChatOllama(model="llama3.2", timeout=30)
    response = llm.invoke("Hola")
except httpx.ConnectError:
    print("Error: No se puede conectar a Ollama")
    print("Verifica que esté corriendo: docker ps")
except httpx.ReadTimeout:
    print("Error: Timeout - El modelo tardó mucho en responder")
    print("Considera usar un modelo más pequeño")
except Exception as e:
    print(f"Error inesperado: {e}")
```

---

## 4. Logging para Debugging

```python
import logging

# Activar logs de LangChain
logging.basicConfig(level=logging.DEBUG)

from langchain_ollama import ChatOllama

llm = ChatOllama(model="llama3.2", verbose=True)
response = llm.invoke("Test")
```

Esto mostrará:
- Tiempo de respuesta
- Tokens generados
- Errores internos

---

## 5. Versionado de Modelos

```python
# En lugar de "latest", fija una versión
llm = ChatOllama(model="llama3.2:latest")  # ❌ Puede cambiar

llm = ChatOllama(model="llama3.2:8b")      # ✅ Versión específica
```

---

# Solución de Problemas

## Problema 1: "No se puede conectar a Ollama"

**Error:**
```
httpx.ConnectError: [Errno 111] Connection refused
```

**Soluciones:**

1. Verificar que Ollama está corriendo:
```powershell
docker ps
```

Deberías ver `ollama-server` en la lista.

2. Si no está corriendo:
```powershell
docker-compose up -d ollama
```

3. Ver logs de Ollama:
```powershell
docker logs ollama-server
```

---

## Problema 2: "Modelo no encontrado"

**Error:**
```
Error: model 'llama3.2' not found
```

**Solución:**
```powershell
# Listar modelos disponibles
docker exec ollama-server ollama list

# Si no está, descargarlo
docker exec ollama-server ollama pull llama3.2

# Verificar descarga
docker exec ollama-server ollama list
```

---

## Problema 3: Respuestas muy lentas

**Síntomas:** Cada respuesta tarda 30+ segundos

**Soluciones:**

1. Usar un modelo más pequeño:
```powershell
docker exec ollama-server ollama pull phi3:mini
```

2. Aumentar RAM en Docker Desktop:
   - Settings > Resources > Memory > 16 GB

3. Si tienes GPU NVIDIA, habilitar aceleración GPU:
   - Descomentar sección `deploy` en `docker-compose.yml`

---

## Problema 4: Error de memoria

**Error:**
```
CUDA out of memory
```
o
```
Killed
```

**Soluciones:**

1. Cerrar otros programas que usen RAM
2. Usar modelo más pequeño
3. Aumentar swap del sistema

---

## Problema 5: ChromaDB no guarda datos

**Síntoma:** Cada vez que reinicias, ChromaDB está vacío

**Solución:**

Asegúrate de especificar `persist_directory`:

```python
vectorstore = Chroma.from_documents(
    documents=chunks,
    embedding=embeddings,
    persist_directory="./chroma_db"  # ← Importante!
)
```

Y monta el volumen en docker-compose:

```yaml
langchain-app:
  volumes:
    - ./app:/app
    - ./chroma_db:/app/chroma_db  # ← Agregar esto
```

---

## Problema 6: "Module not found"

**Error:**
```python
ModuleNotFoundError: No module named 'langchain_ollama'
```

**Solución:**

Reconstruir la imagen:
```powershell
docker-compose build --no-cache langchain-app
docker-compose up -d
```

---

# Próximos Pasos

## Nivel Principiante

1. Ejecuta todos los ejemplos de `main.py`
2. Modifica los prompts para ver cómo cambian las respuestas
3. Prueba diferentes modelos (phi3, mistral)
4. Experimenta con temperaturas (0.0, 0.5, 1.0)

---

## Nivel Intermedio

1. Crea tu primer sistema RAG con tus propios documentos
2. Construye una API REST simple con FastAPI
3. Implementa un chatbot con memoria en una web
4. Integra con bases de datos (SQLite, PostgreSQL)

---

## Nivel Avanzado

1. Crea agentes con múltiples herramientas
2. Implementa fine-tuning de modelos (LoRA)
3. Construye pipelines complejos con LangGraph
4. Despliega en producción con Kubernetes

---

# Recursos Adicionales

## Documentación Oficial

- **LangChain:** https://python.langchain.com/
- **Ollama:** https://ollama.ai/
- **Docker:** https://docs.docker.com/

## Comunidad

- **LangChain Discord:** https://discord.gg/langchain
- **Ollama Discord:** https://discord.gg/ollama
- **Reddit r/LocalLLaMA:** https://reddit.com/r/LocalLLaMA

## Tutoriales

- LangChain Cookbook: https://github.com/langchain-ai/langchain/tree/master/cookbook
- Ollama Blog: https://ollama.ai/blog
- Awesome LangChain: https://github.com/kyrolabs/awesome-langchain

---

# Conclusión

Este proyecto te proporciona:

✅ Un entorno completo de desarrollo con IA local
✅ Sin costes de APIs ($0.00)
✅ Privacidad total (todo local)
✅ Ejemplos prácticos listos para usar
✅ Arquitectura escalable y profesional

**Próximo paso:** Ejecuta `docker-compose up -d` y empieza a experimentar!

Para documentación técnica detallada, consulta:
- `DOCKER_COMPOSE_EXPLICADO.md` - Explicación del docker-compose
- `GLOSARIO.md` - Términos de IA

**¿Preguntas?** Revisa los logs con `docker-compose logs -f`

---

*Última actualización: 2026-01-02*
