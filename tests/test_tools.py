"""Pruebas unitarias de herramientas; valida calculadora segura y busqueda web mockeada."""

from __future__ import annotations

import ast
import json

from src.bluhorizon_ia.tools import _eval_expr, calculator_tool, web_search_tool


def test_safe_calculator_basic_operation() -> None:
    result = calculator_tool.invoke("2 + 2 * 3")
    assert "8.0" in result


def test_safe_calculator_rejects_names() -> None:
    node = ast.parse("__import__('os').system('dir')", mode="eval").body
    try:
        _eval_expr(node)
        assert False, "Expected ValueError"
    except ValueError:
        assert True


def test_web_search_tool_with_mocked_response(monkeypatch) -> None:
    class _MockResponse:
        def __enter__(self):
            return self

        def __exit__(self, exc_type, exc, tb):
            return None

        def read(self):
            payload = {
                "AbstractText": "FAISS es una biblioteca para busqueda de similitud.",
                "AbstractURL": "https://duckduckgo.com/FAISS",
            }
            return json.dumps(payload).encode("utf-8")

    def _mock_urlopen(*args, **kwargs):
        return _MockResponse()

    monkeypatch.setattr("src.bluhorizon_ia.tools.urlopen", _mock_urlopen)
    result = web_search_tool.invoke("FAISS")

    assert "Resultado web" in result
    assert "FAISS" in result
