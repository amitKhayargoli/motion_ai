import 'package:flutter/material.dart';
import 'package:motion_ai/feature/rag_chatbot/domain/entities/chat_message_entity.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.text,
    required this.isUser,
    required this.pending,
    required this.failed,
    this.notes,
    this.onNoteTap,
  });

  final String text;
  final bool isUser;
  final bool pending;
  final bool failed;
  final List<ChatNoteRef>? notes;
  final void Function(ChatNoteRef note)? onNoteTap;

  @override
  Widget build(BuildContext context) {
    final bg =
        isUser ? const Color(0xFFAEFB2A) : Colors.black.withOpacity(0.22);
    final fg = isUser ? Colors.black : Colors.white;
    final hasNotes = !isUser && notes != null && notes!.isNotEmpty;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border:
              isUser ? null : Border.all(color: Colors.white.withOpacity(0.10)),
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              text.isEmpty ? "..." : text,
              style: TextStyle(
                color: fg,
                fontFamily: 'sf_pro',
                fontSize: 15,
                height: 1.4,
              ),
            ),
            if (hasNotes) ...[
              const SizedBox(height: 10),
              ...notes!.map((note) => _NoteCard(
                    note: note,
                    onTap: () => onNoteTap?.call(note),
                  )),
            ],
            if (isUser && (pending || failed)) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (pending)
                    const Text(
                      "Sending…",
                      style: TextStyle(
                        color: Colors.black54,
                        fontFamily: 'sf_pro',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  if (failed)
                    const Text(
                      "Tap to retry",
                      style: TextStyle(
                        color: Colors.black54,
                        fontFamily: 'sf_pro',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note, required this.onTap});
  final ChatNoteRef note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: const Color(0xFFAEFB2A).withOpacity(0.35)),
          ),
          child: Row(
            children: [
              const Icon(Icons.description_outlined,
                  size: 15, color: Color(0xFFAEFB2A)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  note.title.isEmpty ? "Untitled" : note.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'sf_pro',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.chevron_right,
                  size: 16, color: Color(0xFFAEFB2A)),
            ],
          ),
        ),
      ),
    );
  }
}
