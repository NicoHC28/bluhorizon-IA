// Modelo de persona/agente; contiene nombre, prompt del sistema y mensaje inicial.

class Persona {
  const Persona({
    required this.name,
    required this.prompt,
    required this.initialMessage,
  });

  final String name;
  final String prompt;
  final String initialMessage;
}
