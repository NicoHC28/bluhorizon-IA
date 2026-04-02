// Modelo de mensaje de chat; define roles y serializacion JSON para persistencia y API.

enum Role {
  user,
  assistant,
  developer,
}

class ChatMessage {
  ChatMessage({required this.role, required this.content});

  final Role role;
  final String content;

  ChatMessage copyWith({Role? role, String? content}) {
    return ChatMessage(
      role: role ?? this.role,
      content: content ?? this.content,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "role": role.name,
      "content": content,
    };
  }

  static ChatMessage fromJson(Map<String, dynamic> json) {
    final roleValue = (json["role"] as String? ?? "assistant").trim();
    final role = Role.values.firstWhere(
      (r) => r.name == roleValue,
      orElse: () => Role.assistant,
    );

    return ChatMessage(
      role: role,
      content: (json["content"] as String? ?? "").trim(),
    );
  }
}
