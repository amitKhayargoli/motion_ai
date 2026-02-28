import '../../domain/entities/chat_message_entity.dart';

class ChatAnswerApiModel {
  final String kind;
  final String answer;
  final List<dynamic> sources;
  final List<ChatNoteRef> notes;

  ChatAnswerApiModel({
    required this.kind,
    required this.answer,
    required this.sources,
    required this.notes,
  });

  factory ChatAnswerApiModel.fromJson(Map<String, dynamic> json) {
    final rawNotes = json["notes"] as List?;
    return ChatAnswerApiModel(
      kind: (json["kind"] ?? "").toString(),
      answer: (json["answer"] ?? "").toString(),
      sources: (json["sources"] as List?) ?? const [],
      notes: rawNotes
              ?.map((n) => ChatNoteRef(
                    id: (n["id"] ?? "").toString(),
                    title: (n["title"] ?? "Untitled").toString(),
                  ))
              .toList() ??
          const [],
    );
  }
}
