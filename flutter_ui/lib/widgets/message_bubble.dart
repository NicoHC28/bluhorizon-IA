// Widget de burbuja de mensaje; renderiza markdown y abre enlaces con url_launcher.

import "package:flutter/material.dart";
import "package:flutter_markdown/flutter_markdown.dart";
import "package:url_launcher/url_launcher.dart";

import "../models/chat_message.dart";

class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == Role.user;
    final scheme = Theme.of(context).colorScheme;

    final bubbleColor = isUser ? scheme.primaryContainer : scheme.surfaceContainerHighest;
    final textColor = isUser ? scheme.onPrimaryContainer : scheme.onSurface;
    final borderColor = isUser ? scheme.primary.withValues(alpha: 0.25) : scheme.outlineVariant;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: MarkdownBody(
          data: message.content,
          onTapLink: (text, href, title) async {
            if (href == null || href.isEmpty) return;
            final uri = Uri.tryParse(href);
            if (uri == null) return;

            final opened = await launchUrl(
              uri,
              mode: LaunchMode.externalApplication,
            );
            if (!opened && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("No se pudo abrir el enlace.")),
              );
            }
          },
          styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
            p: Theme.of(context).textTheme.bodyMedium?.copyWith(color: textColor),
          ),
        ),
      ),
    );
  }
}
