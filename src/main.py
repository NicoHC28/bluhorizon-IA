
"""Entrada CLI del proyecto; inicializa configuracion y usa TutorAgent/DirectTutor."""

from __future__ import annotations

from .bluhorizon_ia.agent import DirectTutor, TutorAgent
from .bluhorizon_ia.config import get_settings


def run_cli() -> None:
    settings = get_settings()
    tutor = TutorAgent(settings)
    direct_tutor = DirectTutor(settings)

    # CLI simple para probar funcionalidades del agente temporario. Remplazado por UI Flutter luego.
    print("\n=== Agente Tutor de GenAI (RAG + Herramientas + LLM) ===")
    print(
        "Este tutor te ayuda a entender LLMs, procesamiento de datos, RAG, bases vectoriales y wrappers de API."
    )
    print(
        "Tambien puedes ver como el agente usa herramientas en casos reales (busqueda, calculo o APIs)."
    )
    print("Escribe 'salir' para terminar.")
    print("Escribe 'directo: tema' para usar el wrapper directo sin agente.\n")

    while True:
        question = input("Tu pregunta: ").strip()

        if not question:
            continue

        if question.lower() in {"salir", "exit", "quit"}:
            print("Hasta luego.")
            break

        try:
            if question.lower().startswith("directo:"):
                topic = question.split(":", maxsplit=1)[1].strip()
                response = direct_tutor.explain(topic)
            else:
                response = tutor.ask(question)

            print(f"\nTutor:\n{response}\n")
        except Exception as exc:  # noqa: BLE001
            print(f"\nOcurrio un error: {exc}\n")


if __name__ == "__main__":
    run_cli()
