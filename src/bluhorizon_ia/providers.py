"""Proveedores de modelos LLM/embeddings; usa wrappers de LangChain para OpenAI."""

from __future__ import annotations

from langchain_core.language_models.chat_models import BaseChatModel
from langchain_openai import ChatOpenAI, OpenAIEmbeddings

from .config import Settings


def get_chat_model(settings: Settings) -> BaseChatModel:
    return ChatOpenAI(model=settings.openai_model, temperature=0.2)


def get_embedding_model(_: Settings):
    return OpenAIEmbeddings(model="text-embedding-3-small")
