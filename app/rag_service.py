import os
import shutil
from typing import List, Optional
from langchain_ollama import ChatOllama, OllamaEmbeddings
from langchain_chroma import Chroma
from langchain_community.document_loaders import TextLoader, DirectoryLoader, PyPDFLoader, UnstructuredMarkdownLoader
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser
from langchain_core.runnables import RunnablePassthrough
from langchain_core.documents import Document

class RAGService:
    """Service to handle RAG operations: ingestion, retrieval, and generation."""

    def __init__(self, 
                 ollama_base_url: str = "http://localhost:11434",
                 model_name: str = "llama3.2",
                 embedding_model: str = "qwen3-embedding:8b", # "nomic-embed-text",
                 persist_dir: str = "./chroma_db"):
        
        self.ollama_base_url = ollama_base_url
        self.model_name = model_name
        self.persist_dir = persist_dir
        self.embedding_model_name = None # Force initial setup in _update_embedding_model
        
        # Initialize LLM
        self.llm = ChatOllama(
            model=model_name,
            base_url=ollama_base_url,
            temperature=0.3, # Low temperature for factual RAG
        )

        # Initialize embeddings, vectorstore, and retriever
        self._update_embedding_model(embedding_model)

    def _update_embedding_model(self, embedding_model: Optional[str]):
        """Updates the embedding model if it's different from the current one."""
        if not embedding_model or embedding_model == getattr(self, 'embedding_model_name', None):
            return

        print(f"Switching embedding model to: {embedding_model}")
        self.embedding_model_name = embedding_model
        self.embeddings = OllamaEmbeddings(
            model=embedding_model,
            base_url=self.ollama_base_url,
        )
        
        # Use a model-specific subdirectory to avoid dimension mismatch
        model_persist_dir = os.path.join(self.persist_dir, embedding_model.replace(':', '_'))
        
        # Update vectorstore with new embedding function
        self.vectorstore = Chroma(
            persist_directory=model_persist_dir,
            embedding_function=self.embeddings,
        )
        self.retriever = self.vectorstore.as_retriever(
            search_type="similarity",
            search_kwargs={"k": 3}
        )

    def ingest_file(self, file_path: str, embedding_model: Optional[str] = None) -> int:
        """Ingests a single file into the vector store."""
        if embedding_model:
            self._update_embedding_model(embedding_model)

        if not os.path.exists(file_path):
            raise FileNotFoundError(f"File not found: {file_path}")

        # Determine loader based on extension
        ext = os.path.splitext(file_path)[1].lower()
        if ext == ".pdf":
            loader = PyPDFLoader(file_path)
        elif ext == ".md":
            try:
                # Try to ensure resources are available if using Unstructured
                import nltk
                try:
                    nltk.data.find('tokenizers/punkt_tab')
                except LookupError:
                    nltk.download('punkt_tab')
                try:
                    nltk.data.find('tokenizers/punkt')
                except LookupError:
                    nltk.download('punkt')
                try:
                    nltk.data.find('taggers/averaged_perceptron_tagger')
                except LookupError:
                    nltk.download('averaged_perceptron_tagger')

                loader = UnstructuredMarkdownLoader(file_path)
                documents = loader.load()
            except Exception as e:
                print(f"Warning: UnstructuredMarkdownLoader failed: {e}. Falling back to TextLoader.")
                loader = TextLoader(file_path, encoding="utf-8", autodetect_encoding=True)
                documents = loader.load()
        elif ext == ".txt":
            loader = TextLoader(file_path, encoding="utf-8")
        else:
            # Fallback for code files or others, treat as text
            loader = TextLoader(file_path, encoding="utf-8", autodetect_encoding=True)

        documents = loader.load()
        return self._process_documents(documents)

    def ingest_directory(self, dir_path: str, glob_pattern: str = "**/*") -> int:
        """Ingests all matching files in a directory."""
        # Note: DirectoryLoader defaults to Unstructured for unknown types, 
        # might want to be specific or use multiple loaders.
        # For simplicity, we use TextLoader for now for text-based.
        loader = DirectoryLoader(dir_path, glob=glob_pattern, loader_cls=TextLoader)
        documents = loader.load()
        return self._process_documents(documents)

    def _process_documents(self, documents: List[Document]) -> int:
        """Splits documents and adds them to the vector store."""
        text_splitter = RecursiveCharacterTextSplitter(
            chunk_size=1000,
            chunk_overlap=200,
            length_function=len,
        )
        chunks = text_splitter.split_documents(documents)
        
        if not chunks:
            return 0
            
        self.vectorstore.add_documents(chunks)
        # Chroma handles persistence automatically in recent versions, but explicit persist calls
        # were deprecated. LangChain's Chroma wrapper handles it.
        
        return len(chunks)

    def clear_database(self, embedding_model: Optional[str] = None):
        """Clears the vector database. If embedding_model is provided, clears only that model's data."""
        if embedding_model:
            self._update_embedding_model(embedding_model)
            if os.path.exists(self.vectorstore._persist_directory):
                import shutil
                shutil.rmtree(self.vectorstore._persist_directory)
                # Force re-init after deletion
                self.embedding_model_name = None
                self._update_embedding_model(embedding_model)
        else:
            # Clear everything
            if os.path.exists(self.persist_dir):
                import shutil
                shutil.rmtree(self.persist_dir)
                os.makedirs(self.persist_dir, exist_ok=True)
                # Re-initialize current model
                current_model = self.embedding_model_name
                self.embedding_model_name = None
                self._update_embedding_model(current_model)

    def list_documents(self, embedding_model: Optional[str] = None) -> List[str]:
        """Returns a list of unique document sources in the vector store."""
        try:
            if embedding_model:
                self._update_embedding_model(embedding_model)
            
            # Get all metadata from the collection
            results = self.vectorstore.get()
            if not results or 'metadatas' not in results:
                return []
            
            # Extract unique 'source' values
            sources = set()
            for meta in results['metadatas']:
                if meta and 'source' in meta:
                    sources.add(os.path.basename(meta['source']))
            
            return sorted(list(sources))
        except Exception as e:
            print(f"Error listing documents: {e}")
            return []

    def delete_document(self, filename: str, embedding_model: Optional[str] = None) -> bool:
        """Deletes all chunks associated with a specific filename."""
        try:
            if embedding_model:
                self._update_embedding_model(embedding_model)

            results = self.vectorstore.get()
            if not results or 'metadatas' not in results:
                return False
            
            ids_to_delete = []
            for i, meta in enumerate(results['metadatas']):
                if meta and 'source' in meta:
                    if os.path.basename(meta['source']) == filename:
                        ids_to_delete.append(results['ids'][i])
            
            if ids_to_delete:
                self.vectorstore.delete(ids=ids_to_delete)
                print(f"Deleted {len(ids_to_delete)} chunks from {filename}")
                return True
            
            return False
        except Exception as e:
            print(f"Error deleting document {filename}: {e}")
            return False

    async def ask(self, question: str, model_name: Optional[str] = None, temperature: float = 0.3, embedding_model: Optional[str] = None) -> str:
        """Asks a question using the RAG chain."""
        if embedding_model:
            self._update_embedding_model(embedding_model)

        # Use provided model or fallback to default
        target_model = model_name or self.model_name
        
        # Create a specific LLM instance for this request
        llm = ChatOllama(
            model=target_model,
            base_url=self.ollama_base_url,
            temperature=temperature,
        )

        template = """Usa el siguiente contexto para responder a la pregunta del usuario.
Si la respuesta no se encuentra en el contexto, di que no tienes esa información. No inventes nada.
Mantén la respuesta concisa y profesional.

Contexto:
{context}

Pregunta: {question}
Respuesta:"""
        
        prompt = ChatPromptTemplate.from_template(template)

        def format_docs(docs):
            return "\n\n".join(doc.page_content for doc in docs)

        chain = (
            {"context": self.retriever | format_docs, "question": RunnablePassthrough()}
            | prompt
            | llm
            | StrOutputParser()
        )
        
        return await chain.ainvoke(question)

    async def ask_stream(self, question: str, model_name: Optional[str] = None, temperature: float = 0.3, embedding_model: Optional[str] = None):
        """Asks a question using the RAG chain and streams the response."""
        if embedding_model:
            self._update_embedding_model(embedding_model)

        # Use provided model or fallback to default
        target_model = model_name or self.model_name
        
        # Create a specific LLM instance for this request
        llm = ChatOllama(
            model=target_model,
            base_url=self.ollama_base_url,
            temperature=temperature,
        )

        template = """Usa el siguiente contexto para responder a la pregunta del usuario.
Si la respuesta no se encuentra en el contexto, di que no tienes esa información. No inventes nada.
Mantén la respuesta concisa y profesional.

Contexto:
{context}

Pregunta: {question}
Respuesta:"""
        
        prompt = ChatPromptTemplate.from_template(template)

        def format_docs(docs):
            return "\n\n".join(doc.page_content for doc in docs)

        chain = (
            {"context": self.retriever | format_docs, "question": RunnablePassthrough()}
            | prompt
            | llm
            | StrOutputParser()
        )
        
        async for chunk in chain.astream(question):
            yield chunk

    def get_related_docs(self, query: str, k: int = 3) -> List[Document]:
        """Returns documents similar to the query."""
        return self.vectorstore.similarity_search(query, k=k)
