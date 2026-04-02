"""Persistencia de sesiones en JSON; usa locks para lecturas/escrituras seguras por proceso."""

from __future__ import annotations

import json
from pathlib import Path
from threading import Lock


class SessionStore:
    def __init__(self, file_path: Path) -> None:
        self.file_path = file_path
        # Lock por proceso para evitar corrupcion del JSON en escrituras concurrentes.
        self._lock = Lock()
        self.file_path.parent.mkdir(parents=True, exist_ok=True)
        if not self.file_path.exists():
            self._write({})

    def get_messages(self, session_id: str) -> list[dict[str, str]]:
        data = self._read()
        value = data.get(session_id, [])
        if not isinstance(value, list):
            return []
        return [m for m in value if isinstance(m, dict)]

    def set_messages(self, session_id: str, messages: list[dict[str, str]]) -> None:
        with self._lock:
            data = self._read_unlocked()
            data[session_id] = messages
            self._write_unlocked(data)

    def _read(self) -> dict[str, object]:
        with self._lock:
            return self._read_unlocked()

    def _read_unlocked(self) -> dict[str, object]:
        try:
            raw = self.file_path.read_text(encoding="utf-8")
            loaded = json.loads(raw)
            if isinstance(loaded, dict):
                return loaded
            return {}
        except Exception:
            # Si el archivo no existe o esta corrupto, se regresa vacio para no tumbar la API.
            return {}

    def _write(self, data: dict[str, object]) -> None:
        with self._lock:
            self._write_unlocked(data)

    def _write_unlocked(self, data: dict[str, object]) -> None:
        self.file_path.write_text(
            json.dumps(data, ensure_ascii=True, indent=2),
            encoding="utf-8",
        )
