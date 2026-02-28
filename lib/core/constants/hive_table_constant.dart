class HiveTableConstant {
  HiveTableConstant._();

  static const String dbName = "app_database";

  static const int workspaceTypeId = 0;
  static const String workspaceTable = 'workspace_table';

  static const int taskTypeId = 1;
  static const String taskTable = 'task_table';

  static const int notesTypeId = 2;
  static const String notesTable = 'notes_table';

  static const int userTypeId = 3;
  static const String userTable = 'user_table';

  static const int meetingLink = 4;
  static const String meetingLinkTable = 'meeting_link_table';

  static const int audioFileTypeId = 5;
  static const String audioFileTable = "audio_files";

  static const int chatThreadTypeId = 6;
  static const int chatMessageTypeId = 7;
  static const String chatThreadTable = "chat_threads";
  static const String chatMessageTable = "chat_messages";
}
