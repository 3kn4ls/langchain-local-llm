
import os
from langchain_community.document_loaders import PyPDFLoader

# Crear un PDF dummy simple para prueba
from fpdf import FPDF

pdf = FPDF()
pdf.add_page()
pdf.set_font("Arial", size=12)
pdf.cell(200, 10, txt="Contrato de prueba del gimnasio. Regla 1: No hacer ruido.", ln=1, align="C")
pdf.output("test_contract.pdf")

try:
    print("Intentando cargar PDF...")
    loader = PyPDFLoader("test_contract.pdf")
    docs = loader.load()
    print(f"Exito! Se cargaron {len(docs)} paginas.")
    print(f"Contenido: {docs[0].page_content}")
except Exception as e:
    print(f"Error al cargar PDF: {e}")
    import traceback
    traceback.print_exc()
