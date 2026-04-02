# Agente Tutor de GenAI (FastAPI + RAG + Herramientas + Flutter)

Este proyecto es una plataforma educativa completa para practicar como se construye un asistente con LLMs en un caso real.

No es solo un chat: combina un backend en Python, una UI en Flutter, recuperacion de contexto con RAG, base de datos vectorial, uso de herramientas y memoria de conversacion por sesion.

## Que problema resuelve

Cuando usas un LLM "solo con prompt", la respuesta depende de lo que el modelo recuerde de su entrenamiento general.

Este proyecto mejora eso con dos capas:

- RAG: inyecta contexto relevante desde una base de conocimiento del proyecto.
- Herramientas: permite que el agente haga acciones (buscar, calcular, consultar APIs) cuando la pregunta lo necesita.

Asi se obtiene un tutor mas util, mas explicativo y mas cercano a una app real de produccion.

## Requerimientos del reto (explicados en lenguaje directo)

Este proyecto cubre explicitamente:

- Conceptos basicos de LLMs
- Procesamiento de datos
- Fundamentos de RAG (LLM + recuperacion de informacion precisa)
- Bases de datos vectoriales
- Wrappers de API para interactuar con LLMs
- Agente que usa herramientas (busquedas, calculos y APIs)

## Como esta compuesta la plataforma

### 1) Backend (Python + FastAPI)

El backend expone el agente como servicio para que pueda usarse desde CLI y desde la UI.

Endpoints principales:

- GET /health
- POST /chat
- POST /chat/stream

Con esto puedes probar la logica del agente sin depender de una interfaz especifica.

### 2) Agente con LLM

El agente usa OpenAI (via LangChain) y decide cuando responder directamente y cuando llamar herramientas.

Tambien incluye una ruta "directa" del modelo para comparar:

- modo agente (RAG + herramientas)
- modo wrapper directo (sin agente)

### 3) RAG (recuperacion aumentada)

El RAG aqui NO es memoria de chat. Su funcion es recuperar contexto documental relevante.

Flujo:

1. Se consulta el indice vectorial con la pregunta.
2. Se recuperan fragmentos relevantes.
3. Esos fragmentos se agregan al prompt.
4. El LLM responde con mas precision sobre el dominio.

### 4) Base de datos vectorial (FAISS)

FAISS es la base vectorial local del proyecto.

Se usa para guardar embeddings y recuperar contexto semantico rapidamente.

Por eso aparece en el README: porque forma parte directa de "RAG + BD vectorial", que es uno de los requerimientos del reto.

### 5) Procesamiento de datos

La base de conocimiento en Markdown se convierte en chunks y luego en embeddings.

Ese pipeline de transformacion es el bloque de procesamiento de datos del proyecto.

### 6) Wrappers de API

La interaccion con LLMs se hace mediante wrappers de LangChain (por ejemplo ChatOpenAI y OpenAIEmbeddings).

Esto deja la arquitectura mas limpia y extensible que llamar la API cruda en cada parte del codigo.

### 7) Herramientas del agente

El agente puede usar herramientas en tiempo de respuesta, por ejemplo:

- calculadora segura
- busqueda web (DuckDuckGo Instant Answer API)

La idea es que no todo lo resuelva "solo generando texto", sino que pueda ejecutar acciones utiles.

### 8) Memoria de conversacion

La memoria de conversacion vive en dos capas:

- Cliente Flutter: guarda estado local por agente con SharedPreferences.
- Backend FastAPI: guarda historial por session_id en data/session_memory.json.

Esto permite mantener continuidad entre mensajes y entre reinicios.

### 9) UI (Flutter)

La UI esta hecha para consumir el backend por streaming.

Incluye:

- chat con burbujas y markdown
- selector visible de agente/persona
- nuevo chat por agente
- dark/light mode
- auto-scroll durante generacion
- render incremental para que el texto aparezca de forma mas legible

## Arquitectura (vision general)

Usuario -> Flutter UI o CLI  
Flutter UI -> FastAPI  
CLI -> Agente  
Agente -> Retriever (FAISS)  
Agente -> Herramientas  
Agente -> OpenAI (LangChain wrappers)

## Estructura del proyecto

```text
bluhorizon-IA/
|-- data/
|   |-- base_conocimiento.md
|   |-- session_memory.json (se crea en runtime)
|-- src/
|   |-- bluhorizon_ia/
|   |   |-- __init__.py
|   |   |-- config.py
|   |   |-- providers.py
|   |   |-- rag.py
|   |   |-- tools.py
|   |   |-- agent.py
|   |   |-- session_store.py
|   |-- api.py
|   |-- main.py
|-- flutter_ui/
|-- tests/
|   |-- test_tools.py
|-- Dockerfile
|-- .dockerignore
|-- .env.example
|-- requirements.txt
|-- README.md
```

## Requisitos tecnicos

- Python 3.10+
- Clave API de OpenAI
- Flutter SDK (si vas a usar la UI)
- Docker (opcional)

## Instalacion rapida

1) Crear entorno virtual:

```bash
python -m venv .venv
```

2) Instalar dependencias Python:

```bash
.venv\Scripts\pip install -r requirements.txt
```

3) Configurar entorno:

```bash
copy .env.example .env
```

Editar .env con:

- OPENAI_API_KEY
- OPENAI_MODEL

## Ejecucion

### Opcion A: CLI

```bash
.venv\Scripts\python.exe -m src.main
```

### Opcion B: API FastAPI

```bash
.venv\Scripts\uvicorn.exe src.api:app --reload --host 0.0.0.0 --port 8000
```

Prueba de salud:

```bash
curl http://localhost:8000/health
```

### Opcion C: UI Flutter

Desde flutter_ui:

```bash
flutter pub get
flutter run -d windows
```

o en navegador:

```bash
flutter run -d chrome
```

## Docker

Construir imagen:

```bash
docker build -t bluhorizon-ia .
```

Ejecutar contenedor:

```bash
docker run -it --rm --env-file .env -p 8000:8000 bluhorizon-ia
```

## Testing

```bash
.venv\Scripts\python.exe -m pytest tests/ -v
```

## Ejemplos de preguntas

- Explicame la diferencia entre prompt, token y contexto.
- Que es RAG y cuando conviene usarlo?
- Usa calculadora y resuelve: 25*(8+2)
- Busca informacion breve sobre embeddings y comparala con esta base de conocimiento.

## Nota final

La implementacion actual esta enfocada en OpenAI para cumplir alcance y tiempos del reto.

La arquitectura ya permite extender a otros proveedores sin rehacer toda la app.
