"""Capa RAG: construye/carga FAISS y prepara recuperacion semantica desde la base de conocimiento."""

from __future__ import annotations

from pathlib import Path

from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain_community.document_loaders import TextLoader
from langchain_community.vectorstores import FAISS

from .config import Settings
from .providers import get_embedding_model


def build_or_load_vectorstore(settings: Settings) -> FAISS:
    embeddings = get_embedding_model(settings)
    vector_dir = settings.vectorstore_path

    if _vectorstore_exists(vector_dir):
        return FAISS.load_local(
            folder_path=str(vector_dir),
            embeddings=embeddings,
            allow_dangerous_deserialization=True,
        )

    loader = TextLoader(str(settings.knowledge_base_path), encoding="utf-8")
    documents = loader.load()

    splitter = RecursiveCharacterTextSplitter(
        chunk_size=600,
        chunk_overlap=120,
        separators=["\n\n", "\n", ". ", " "],
    )
    chunks = splitter.split_documents(documents)

    db = FAISS.from_documents(chunks, embeddings)
    vector_dir.mkdir(parents=True, exist_ok=True)
    db.save_local(str(vector_dir))
    return db


def _vectorstore_exists(path: Path) -> bool:
    return (path / "index.faiss").exists() and (path / "index.pkl").exists()
