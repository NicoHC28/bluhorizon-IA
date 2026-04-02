// Pantalla principal del chat; maneja estado por agente, streaming, persistencia y UX.

import "package:flutter/material.dart";
import "dart:async";
import "dart:convert";
import "package:shared_preferences/shared_preferences.dart";

import "../constants/personas.dart";
import "../models/chat_message.dart";
import "../models/persona.dart";
import "../services/chat_api_service.dart";
import "../widgets/message_bubble.dart";

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    required this.isDarkMode,
    required this.onToggleTheme,
    super.key,
  });

  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late Persona _persona;
  late final TextEditingController _controller;
  late final ScrollController _scrollController;
  late final ChatApiService _service;

  // Historial y session ID independientes por agente
  final Map<String, List<ChatMessage>> _conversationsByPersona = {};
  final Map<String, String> _sessionIds = {};

  bool _isLoading = false;

  void _ensurePersonaState(Persona persona) {
    _conversationsByPersona.putIfAbsent(
      persona.name,
      () => [
        ChatMessage(role: Role.assistant, content: persona.initialMessage),
      ],
    );
    _sessionIds.putIfAbsent(
      persona.name,
      () => "session-${DateTime.now().millisecondsSinceEpoch}-${persona.name}",
    );
  }

  List<ChatMessage> get _messages =>
      _conversationsByPersona[_persona.name] ?? [];

  @override
  void initState() {
    super.initState();
    _persona = personas.first;
    _controller = TextEditingController();
    _scrollController = ScrollController();
    _service = ChatApiService(baseUrl: "http://localhost:8000");
    for (final p in personas) {
      _conversationsByPersona[p.name] = [];
      _sessionIds[p.name] =
          "session-${DateTime.now().millisecondsSinceEpoch}-${p.name}";
    }
    _loadPersistedState();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPersistedState() async {
    final prefs = await SharedPreferences.getInstance();

    // Cargar agente activo
    final personaName = prefs.getString("persona_name");
    Persona activePersona = personas.first;
    if (personaName != null) {
      activePersona = personas.firstWhere(
        (p) => p.name == personaName,
        orElse: () => personas.first,
      );
    }

    // Cargar historial y session de cada agente por separado
    for (final p in personas) {
      final sid = prefs.getString("session_id_${p.name}");
      if (sid != null) _sessionIds[p.name] = sid;

      final rawMessages = prefs.getString("messages_json_${p.name}");
      if (rawMessages != null && rawMessages.isNotEmpty) {
        try {
          final decoded = jsonDecode(rawMessages) as List<dynamic>;
          final loaded = decoded
              .whereType<Map<String, dynamic>>()
              .map(ChatMessage.fromJson)
              .toList();
          if (loaded.isNotEmpty) {
            _conversationsByPersona[p.name] = loaded;
          }
        } catch (_) {}
      }

      // Si no tiene mensajes, iniciar con el mensaje de bienvenida
      if (_conversationsByPersona[p.name]!.isEmpty) {
        _conversationsByPersona[p.name] = [
          ChatMessage(role: Role.assistant, content: p.initialMessage),
        ];
      }
    }

    setState(() {
      _persona = activePersona;
    });
    _scrollToBottom();
  }

  Future<void> _persistState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("persona_name", _persona.name);
    for (final p in personas) {
      _ensurePersonaState(p);
      // Persistencia independiente por agente para recuperar contexto al cambiar.
      await prefs.setString("session_id_${p.name}", _sessionIds[p.name]!);
      await prefs.setString(
        "messages_json_${p.name}",
        jsonEncode(
          _conversationsByPersona[p.name]!.map((m) => m.toJson()).toList(),
        ),
      );
    }
  }

  // Cambiar agente sin borrar historial
  void _switchPersona(Persona newPersona) {
    if (newPersona.name == _persona.name) return;
    setState(() {
      _persona = newPersona;
    });
    _persistState();
    _scrollToBottom();
  }

  // Reiniciar solo el agente activo
  void _resetConversation() {
    setState(() {
      _sessionIds[_persona.name] =
          "session-${DateTime.now().millisecondsSinceEpoch}";
      _conversationsByPersona[_persona.name] = [
        ChatMessage(role: Role.assistant, content: _persona.initialMessage),
      ];
    });
    _persistState();
    _scrollToBottom();
  }

  Future<void> _sendMessage() async {
    final input = _controller.text.trim();
    if (input.isEmpty || _isLoading) return;

    final currentPersona = _persona;
    _ensurePersonaState(currentPersona);
    setState(() {
      _isLoading = true;
      _conversationsByPersona[currentPersona.name]!
          .add(ChatMessage(role: Role.user, content: input));
      _conversationsByPersona[currentPersona.name]!
          .add(ChatMessage(role: Role.assistant, content: ""));
      _controller.clear();
    });
    _persistState();
    _scrollToBottom();

    final assistantIndex =
        _conversationsByPersona[currentPersona.name]!.length - 1;
    var built = "";
    var pending = "";
    var streamDone = false;
    Timer? renderTimer;

    void flushStep() {
      if (!mounted || pending.isEmpty) return;
      // Render incremental para evitar saltos bruscos cuando llegan chunks grandes.
      final take = pending.length >= 6 ? 6 : pending.length;
      final chunk = pending.substring(0, take);
      pending = pending.substring(take);
      built += chunk;

      setState(() {
        _conversationsByPersona[currentPersona.name]![assistantIndex] =
            _conversationsByPersona[currentPersona.name]![assistantIndex]
                .copyWith(content: built);
      });
      _scrollToBottom();
    }

    renderTimer = Timer.periodic(const Duration(milliseconds: 35), (_) {
      flushStep();
      if (streamDone && pending.isEmpty) {
        renderTimer?.cancel();
      }
    });

    try {
      await for (final delta in _service.streamAssistantResponse(
        persona: currentPersona,
        history: List<ChatMessage>.from(
          _conversationsByPersona[currentPersona.name]!,
        ),
        userInput: input,
        sessionId: _sessionIds[currentPersona.name]!,
      )) {
        pending += delta;
        if (!mounted) return;
      }
      streamDone = true;

      // Espera breve para drenar el buffer visual antes de terminar el ciclo.
      var guard = 0;
      while (pending.isNotEmpty && guard < 120) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        guard++;
      }
    } catch (e) {
      renderTimer?.cancel();
      if (!mounted) return;
      setState(() {
        _conversationsByPersona[currentPersona.name]![assistantIndex] =
            _conversationsByPersona[currentPersona.name]![assistantIndex]
                .copyWith(content: "Error consultando backend: $e");
      });
    } finally {
      renderTimer?.cancel();
      if (pending.isNotEmpty) {
        built += pending;
        pending = "";
        if (mounted) {
          setState(() {
            _conversationsByPersona[currentPersona.name]![assistantIndex] =
                _conversationsByPersona[currentPersona.name]![assistantIndex]
                    .copyWith(content: built);
          });
        }
      }
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _persistState();
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final max = _scrollController.position.maxScrollExtent;
      if (_isLoading) {
        // Mientras carga la respuesta, saltar directamente al final para mostrar el mensaje sin tener que bajar manualmente.
        _scrollController.jumpTo(max);
        return;
      }

      _scrollController.animateTo(
        max,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    _ensurePersonaState(_persona);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Tutor GenAI"),
        actions: [
          IconButton(
            onPressed: widget.onToggleTheme,
            icon: Icon(
              widget.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            ),
            tooltip: widget.isDarkMode
                ? "Cambiar a modo claro"
                : "Cambiar a modo oscuro",
          ),
          IconButton(
            onPressed: _isLoading ? null : _resetConversation,
            icon: const Icon(Icons.refresh),
            tooltip: "Nuevo chat",
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: scheme.surfaceContainerHighest,
              child: Row(
                children: [
                  Text(
                    "Agente:",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 10),
                  DropdownButton<String>(
                    value: _persona.name,
                    dropdownColor: scheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    style: TextStyle(color: scheme.onSurface),
                    underline: Container(
                      height: 1,
                      color: scheme.outlineVariant,
                    ),
                    isDense: true,
                    onChanged: _isLoading
                        ? null
                        : (value) {
                            if (value == null) return;
                            final selected =
                                personas.firstWhere((p) => p.name == value);
                            _switchPersona(selected);
                          },
                    items: personas
                        .map(
                          (p) => DropdownMenuItem<String>(
                            value: p.name,
                            child: Text(p.name),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(12),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  if (msg.role == Role.developer) {
                    return const SizedBox.shrink();
                  }
                  return MessageBubble(message: msg);
                },
              ),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      enabled: !_isLoading,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: const InputDecoration(
                        hintText: "Escribe tu mensaje...",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _isLoading ? null : _sendMessage,
                    child: const Text("Enviar"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
