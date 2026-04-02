"""API FastAPI del proyecto; expone chat normal/stream y usa TutorAgent + SessionStore."""

from __future__ import annotations

import json
from pathlib import Path
from collections.abc import Iterator

from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
from pydantic import BaseModel, Field

from .bluhorizon_ia.agent import TutorAgent
from .bluhorizon_ia.config import get_settings
from .bluhorizon_ia.session_store import SessionStore


class ChatMessageIn(BaseModel):
    role: str = Field(pattern="^(user|assistant|developer)$")
    content: str


class ChatResponse(BaseModel):
    output: str


class ChatRequest(BaseModel):
    session_id: str | None = None
    messages: list[ChatMessageIn]


settings = get_settings()
app = FastAPI(title="Bluhorizon IA API", version="1.0.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Instancia unica para reutilizar vectorstore y evitar reprocesamiento por request.
agent = TutorAgent(settings)
session_store = SessionStore(Path("data/session_memory.json"))

# Mejora el output del agente para casos matematicos, reemplazando simbolos LaTeX por texto plano y eliminando backslashes.
def _sanitize_output_text(text: str) -> str:
    cleaned = text
    replacements = {
        r"\\div": "/",
        r"\\times": "x",
        r"\\cdot": "*",
        "÷": "/",
        "×": "x",
        r"\\(": "(",
        r"\\)": ")",
        "`": "",
    }
    for source, target in replacements.items():
        cleaned = cleaned.replace(source, target)
    return cleaned


def _normalize_payload(payload: object) -> ChatRequest:
    # Compatibilidad: la UI vieja puede enviar lista de mensajes sin session_id.
    if isinstance(payload, list):
        messages = [ChatMessageIn.model_validate(m) for m in payload]
        return ChatRequest(session_id=None, messages=messages)

    if isinstance(payload, dict):
        return ChatRequest.model_validate(payload)

    raise HTTPException(status_code=400, detail="Payload invalido para chat.")


def _merge_with_session(session_id: str | None, messages: list[ChatMessageIn]) -> list[dict[str, str]]:
    # El agente siempre recibe historial homogeneo en formato role/content.
    current = [{"role": m.role, "content": m.content} for m in messages]
    if not session_id:
        return current

    previous = session_store.get_messages(session_id)
    return [*previous, *current]


def _persist_session(session_id: str | None, merged_messages: list[dict[str, str]], answer: str) -> None:
    if not session_id:
        return

    updated = [
        *merged_messages,
        {"role": "assistant", "content": answer},
    ]
    session_store.set_messages(session_id, updated)


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.post("/chat", response_model=ChatResponse)
async def chat(request: Request) -> ChatResponse:
    # Se soporta payload flexible para facilitar pruebas con curl/Postman/Flutter.
    body = await request.json()
    payload = _normalize_payload(body)
    merged_messages = _merge_with_session(payload.session_id, payload.messages)

    user_messages = [m["content"] for m in merged_messages if m.get("role") == "user"]
    if not user_messages:
        raise HTTPException(status_code=400, detail="Se requiere al menos un mensaje de usuario.")

    answer = _sanitize_output_text(agent.ask(user_messages[-1], history=merged_messages))
    _persist_session(payload.session_id, merged_messages, answer)
    return ChatResponse(output=answer)


@app.post("/chat/stream")
async def chat_stream(request: Request) -> StreamingResponse:
    body = await request.json()
    payload = _normalize_payload(body)
    merged_messages = _merge_with_session(payload.session_id, payload.messages)

    user_messages = [m["content"] for m in merged_messages if m.get("role") == "user"]
    if not user_messages:
        raise HTTPException(status_code=400, detail="Se requiere al menos un mensaje de usuario.")

    answer = _sanitize_output_text(agent.ask(user_messages[-1], history=merged_messages))
    _persist_session(payload.session_id, merged_messages, answer)

    def emit_chunks() -> Iterator[str]:
        # Streaming simple por palabras para UI: una linea JSON por token parcial.
        for token in answer.split(" "):
            # Formato esperado por la UI Flutter: una linea JSON por delta.
            yield json.dumps({"delta": token + " "}, ensure_ascii=True) + "\n"

    return StreamingResponse(emit_chunks(), media_type="text/plain")
