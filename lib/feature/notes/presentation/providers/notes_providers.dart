import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motion_ai/feature/notes/data/providers/note_repository_provider.dart';
import 'package:motion_ai/feature/notes/domain/usecases/create_notes_usecase.dart';
import 'package:motion_ai/feature/notes/domain/usecases/delete_note_usecase.dart';
import 'package:motion_ai/feature/notes/domain/usecases/get_workspace_notes_usecase.dart';
import 'package:motion_ai/feature/notes/domain/usecases/update_note_usecase.dart';

final getWorkspaceNotesUseCaseProvider = Provider<GetWorkspaceNotesUseCase>((
  ref,
) {
  return GetWorkspaceNotesUseCase(ref.read(noteRepositoryProvider));
});

final createNoteUseCaseProvider = Provider<CreateNoteUseCase>((ref) {
  return CreateNoteUseCase(ref.read(noteRepositoryProvider));
});

final updateNoteUseCaseProvider = Provider<UpdateNoteUseCase>((ref) {
  return UpdateNoteUseCase(ref.read(noteRepositoryProvider));
});

final deleteNoteUseCaseProvider = Provider<DeleteNoteUseCase>((ref) {
  return DeleteNoteUseCase(ref.read(noteRepositoryProvider));
});
