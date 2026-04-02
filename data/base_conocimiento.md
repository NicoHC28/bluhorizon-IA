# Fundamentos de GenAI para el Tutor

## 1. ¿Qué es GenAI?
La Inteligencia Artificial Generativa (GenAI) crea contenido nuevo como texto, imágenes, audio o código.
En aplicaciones reales, los modelos necesitan contexto y reglas para producir respuestas útiles.

## 2. Conceptos básicos de LLMs
Un LLM (Large Language Model) predice la siguiente palabra de una secuencia.
Conceptos clave:
- Prompt: instrucción o contexto inicial.
- Tokens: unidades mínimas de texto que procesa el modelo.
- Temperatura: controla creatividad vs. consistencia.
- Context window: cantidad de tokens que puede considerar en una respuesta.

## 3. Procesamiento de datos
Antes de usar datos en un sistema RAG se aplica:
1. Carga de documentos.
2. Limpieza y normalización.
3. Fragmentación (chunking).
4. Generación de embeddings para cada fragmento.

## 4. Fundamentos de RAG
RAG combina recuperación de información con generación de texto.
Flujo:
1. Convertir la pregunta del usuario en embedding.
2. Buscar fragmentos similares en una base vectorial.
3. Enviar esos fragmentos como contexto al LLM.
4. Generar respuesta más precisa y trazable.

## 5. Bases de datos vectoriales
Una base vectorial almacena representaciones numéricas (embeddings).
Permite búsqueda semántica por similitud.
FAISS es una opción eficiente para correr localmente.

## 6. Wrappers de API para LLMs
Wrappers facilitan conexión a múltiples proveedores:
- OpenAI (ChatGPT)
- Google Gemini
- Anthropic Claude
Con LangChain podemos cambiar proveedor sin reescribir toda la lógica de negocio.

## 7. Agente con herramientas
Un agente puede decidir usar herramientas cuando el problema lo requiere.
Ejemplos de herramientas:
- Calculadora para operaciones numéricas.
- Búsqueda local en documentos.
- Consulta de API externa.

## 8. Buenas prácticas
- Explicar límites del modelo.
- Mostrar fuentes recuperadas cuando sea posible.
- Manejar errores de API con mensajes claros.
- Separar configuración, lógica del agente y herramientas.
