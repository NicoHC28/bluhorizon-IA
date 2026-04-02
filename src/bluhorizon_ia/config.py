"""Configuracion central del proyecto; usa pydantic-settings y dotenv para leer .env."""

from __future__ import annotations

from pathlib import Path

from dotenv import load_dotenv
from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    openai_model: str = Field(default="gpt-4o-mini")

    knowledge_base_path: Path = Field(default=Path("data/base_conocimiento.md"))
    vectorstore_path: Path = Field(default=Path("vectorstore"))
    top_k: int = Field(default=4)


def get_settings() -> Settings:
    load_dotenv(override=False)
    return Settings()
