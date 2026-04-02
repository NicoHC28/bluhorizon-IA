"""Orquestacion del agente tutor; combina prompt, RAG, historial y herramientas LangChain."""

from __future__ import annotations

from langchain.agents import AgentExecutor, create_tool_calling_agent
from langchain.prompts import ChatPromptTemplate, MessagesPlaceholder
from langchain_core.output_parsers import StrOutputParser

from .config import Settings
from .providers import get_chat_model
from .rag import build_or_load_vectorstore
from .tools import get_agent_tools


SYSTEM_PROMPT = """
Eres un tutor de IA generativa y respondes SIEMPRE en espanol claro.
Objetivo: ensenar LLMs, procesamiento de datos, RAG, bases vectoriales y uso de herramientas.
Reglas:
1) Si la pregunta requiere datos del conocimiento interno, usa contexto RAG.
2) Si requiere calculos o busqueda, usa herramientas cuando aplique.
3) Para operaciones numericas, usa siempre la herramienta calculadora.
4) En resultados matematicos usa texto plano (sin LaTeX ni simbolos como \\div, \\times o ecuaciones entre parentesis especiales).
5) Explica paso a paso de forma didactica y breve.
6) Si no tienes suficiente informacion, dilo explicitamente.
""".strip()


class TutorAgent:
    def __init__(self, settings: Settings) -> None:
        self.settings = settings
        self.llm = get_chat_model(settings)
        self.vectorstore = build_or_load_vectorstore(settings)

    def ask(self, question: str, history: list[dict[str, str]] | None = None) -> str:
        # RAG: recupera contexto semantico antes de armar el prompt del agente.
        retriever = self.vectorstore.as_retriever(search_kwargs={"k": self.settings.top_k})
        docs = retriever.invoke(question)
        context = "\n\n".join(doc.page_content for doc in docs)
        history = history or []

        # Se limita historial para controlar costo/tokens sin perder continuidad.
        history_text = "\n".join(
            f"{m.get('role', 'user')}: {m.get('content', '')}" for m in history[-12:]
        )

        tools = get_agent_tools()

        prompt = ChatPromptTemplate.from_messages(
            [
                ("system", SYSTEM_PROMPT),
                (
                    "system",
                    "Contexto RAG disponible:\n{rag_context}\n\n"
                    "Usa este contexto para mayor precision si es relevante.",
                ),
                (
                    "system",
                    "Historial conversacional reciente:\n{history_context}\n\n"
                    "Usa el historial para mantener continuidad cuando aplique.",
                ),
                ("human", "{input}"),
                MessagesPlaceholder("agent_scratchpad"),
            ]
        )

        # El executor coordina LLM + herramientas segun lo que decida el agente.
        agent = create_tool_calling_agent(self.llm, tools, prompt)
        executor = AgentExecutor(agent=agent, tools=tools, verbose=False)
        result = executor.invoke(
            {
                "input": question,
                "rag_context": context,
                "history_context": history_text,
            }
        )

        return str(result.get("output", "No se pudo generar respuesta."))


class DirectTutor:
    """Demostracion de wrapper directo sin agente para comparar enfoques."""

    def __init__(self, settings: Settings) -> None:
        self.llm = get_chat_model(settings)
        self.parser = StrOutputParser()

    def explain(self, topic: str) -> str:
        chain = self.llm | self.parser
        prompt = (
            "Explica en espanol para principiantes el tema: "
            f"{topic}. Incluye ejemplo simple."
        )
        return chain.invoke(prompt)
