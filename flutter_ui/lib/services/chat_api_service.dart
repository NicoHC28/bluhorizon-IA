// Cliente HTTP del chat; consume /chat/stream y traduce deltas JSON a flujo de texto.

import "dart:async";
import "dart:convert";

import "package:http/http.dart" as http;

import "../models/chat_message.dart";
import "../models/persona.dart";

class ChatApiService {
  ChatApiService({required this.baseUrl});

  final String baseUrl;

  Stream<String> streamAssistantResponse({
    required Persona persona,
    required List<ChatMessage> history,
    required String userInput,
    required String sessionId,
  }) async* {
    final uri = Uri.parse("$baseUrl/chat/stream");

    final payload = {
      "session_id": sessionId,
      "messages": [
        {"role": "developer", "content": persona.prompt},
        ...history
            .where((m) => m.role != Role.developer)
            .map((m) => m.toJson()),
        {"role": "user", "content": userInput},
      ],
    };

    final request = http.Request("POST", uri)
      ..headers.addAll({
        "Content-Type": "application/json",
      })
      ..body = jsonEncode(payload);

    final response = await request.send();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception("Error HTTP ${response.statusCode} al consultar el backend.");
    }

    var pending = "";
    await for (final chunk in response.stream.transform(utf8.decoder)) {
      final lines = chunk.split("\n");
      for (final rawLine in lines) {
        final line = rawLine.trim();
        if (line.isEmpty) {
          continue;
        }

        final joined = pending + line;
        try {
          final map = jsonDecode(joined) as Map<String, dynamic>;
          pending = "";
          final delta = map["delta"] as String?;
          if (delta != null && delta.isNotEmpty) {
            yield delta;
          }
        } catch (_) {
          pending = joined;
        }
      }
    }
  }
}
