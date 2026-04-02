"""Herramientas del agente (calculadora y busqueda); usa AST seguro y API web externa."""

from __future__ import annotations

import ast
import json
import operator
from urllib.parse import quote_plus
from urllib.request import Request, urlopen
from typing import Any

from langchain_core.tools import tool

_ALLOWED_OPERATORS = {
    ast.Add: operator.add,
    ast.Sub: operator.sub,
    ast.Mult: operator.mul,
    ast.Div: operator.truediv,
    ast.Pow: operator.pow,
    ast.USub: operator.neg,
}


def _eval_expr(node: ast.AST) -> float:
    if isinstance(node, ast.Constant) and isinstance(node.value, (int, float)):
        return float(node.value)

    if isinstance(node, ast.BinOp) and type(node.op) in _ALLOWED_OPERATORS:
        return _ALLOWED_OPERATORS[type(node.op)](_eval_expr(node.left), _eval_expr(node.right))

    if isinstance(node, ast.UnaryOp) and type(node.op) in _ALLOWED_OPERATORS:
        return _ALLOWED_OPERATORS[type(node.op)](_eval_expr(node.operand))

    raise ValueError("Expresion no soportada por la calculadora segura.")


def _normalize_expression(expression: str) -> str:
    # Permite entradas humanas como 1,000,726/726 removiendo separadores de miles.
    return expression.replace(",", "").strip()


def _format_number(value: float) -> str:
    if float(value).is_integer():
        return f"{int(value):,}".replace(",", ".")

    rendered = f"{value:,.6f}".rstrip("0").rstrip(".")
    # Formato legible estilo es-CO: miles con punto y decimales con coma.
    return rendered.replace(",", "_").replace(".", ",").replace("_", ".")


@tool("calculadora", return_direct=False)
def calculator_tool(expression: str) -> str:
    """Evalua expresiones matematicas simples de forma segura."""
    try:
        normalized = _normalize_expression(expression)
        tree = ast.parse(normalized, mode="eval")
        value = _eval_expr(tree.body)
        pretty_result = _format_number(value)
        return f"Resultado: {pretty_result}"
    except Exception as exc:  # noqa: BLE001
        return f"No pude calcular eso. Error: {exc}"


@tool("busqueda_simulada", return_direct=False)
def fake_search_tool(query: str) -> str:
    """Simula una busqueda externa para demostraciones del agente."""
    query_l = query.lower().strip()

    data: dict[str, str] = {
        "rag": "RAG mejora respuestas al recuperar contexto antes de generar.",
        "llm": "Un LLM predice tokens y responde segun prompt + contexto.",
        "faiss": "FAISS permite indexar embeddings y buscar por similitud.",
        "langchain": "LangChain facilita cadenas, agentes, herramientas e integracion LLM.",
    }

    for key, value in data.items():
        if key in query_l:
            return f"Busqueda simulada: {value}"

    return "Busqueda simulada: no hay resultado exacto, intenta con RAG, LLM, FAISS o LangChain."


@tool("busqueda_web", return_direct=False)
def web_search_tool(query: str) -> str:
    """Consulta DuckDuckGo Instant Answer API para obtener resumenes breves."""
    try:
        endpoint = (
            "https://api.duckduckgo.com/?q="
            f"{quote_plus(query)}&format=json&no_html=1&skip_disambig=1"
        )
        req = Request(endpoint, headers={"User-Agent": "bluhorizon-ia-agent/1.0"})
        with urlopen(req, timeout=8) as resp:  # nosec B310
            payload = json.loads(resp.read().decode("utf-8"))

        abstract = (payload.get("AbstractText") or "").strip()
        link = (payload.get("AbstractURL") or "").strip()

        if abstract:
            if link:
                return f"Resultado web: {abstract} Fuente: {link}"
            return f"Resultado web: {abstract}"

        topics = payload.get("RelatedTopics") or []
        for topic in topics:
            if isinstance(topic, dict) and topic.get("Text"):
                txt = str(topic.get("Text")).strip()
                first_url = str(topic.get("FirstURL") or "").strip()
                if first_url:
                    return f"Resultado web: {txt} Fuente: {first_url}"
                return f"Resultado web: {txt}"

        return "No encontre un resultado web concluyente para esa consulta."
    except Exception as exc:  # noqa: BLE001
        return f"No pude consultar la busqueda web. Error: {exc}"


def get_agent_tools() -> list[Any]:
    return [calculator_tool, web_search_tool, fake_search_tool]
