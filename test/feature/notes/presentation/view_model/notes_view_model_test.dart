import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:motion_ai/core/error/failures.dart';
import 'package:motion_ai/feature/notes/domain/entities/note_entity.dart';
import 'package:motion_ai/feature/notes/domain/usecases/create_notes_usecase.dart';
import 'package:motion_ai/feature/notes/domain/usecases/delete_note_usecase.dart';
import 'package:motion_ai/feature/notes/domain/usecases/get_workspace_notes_usecase.dart';
import 'package:motion_ai/feature/notes/domain/usecases/update_note_usecase.dart';
import 'package:motion_ai/feature/notes/presentation/providers/notes_providers.dart';
import 'package:motion_ai/feature/notes/presentation/state/notes_state.dart';
import 'package:motion_ai/feature/notes/presentation/view_model/notes_view_model.dart';

// --- Mocks ---
class MockGetWorkspaceNotesUseCase extends Mock
    implements GetWorkspaceNotesUseCase {}

class MockCreateNoteUseCase extends Mock implements CreateNoteUseCase {}

class MockUpdateNoteUseCase extends Mock implements UpdateNoteUseCase {}

class MockDeleteNoteUseCase extends Mock implements DeleteNoteUseCase {}

void main() {
  setUpAll(() {
    registerFallbackValue(const GetWorkspaceNotesParams(''));
    registerFallbackValue(
      const CreateNoteParams(workspaceId: '', title: '', content: ''),
    );
    registerFallbackValue(
      const UpdateNoteParams(noteId: '', title: '', content: ''),
    );
    registerFallbackValue(const DeleteNoteParams(''));
  });

  late MockGetWorkspaceNotesUseCase mockGetWorkspaceNotes;
  late MockCreateNoteUseCase mockCreateNote;
  late MockUpdateNoteUseCase mockUpdateNote;
  late MockDeleteNoteUseCase mockDeleteNote;
  late ProviderContainer container;

  const tWorkspaceId = 'ws-123';

  final tNote1 = NoteEntity(
    id: 'note-1',
    workspaceId: tWorkspaceId,
    title: 'Note 1',
    content: 'Content 1',
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
  );

  final tNote2 = NoteEntity(
    id: 'note-2',
    workspaceId: tWorkspaceId,
    title: 'Note 2',
    content: 'Content 2',
    createdAt: DateTime(2025, 1, 2),
    updatedAt: DateTime(2025, 1, 2),
  );

  setUp(() {
    mockGetWorkspaceNotes = MockGetWorkspaceNotesUseCase();
    mockCreateNote = MockCreateNoteUseCase();
    mockUpdateNote = MockUpdateNoteUseCase();
    mockDeleteNote = MockDeleteNoteUseCase();

    container = ProviderContainer(
      overrides: [
        getWorkspaceNotesUseCaseProvider
            .overrideWithValue(mockGetWorkspaceNotes),
        createNoteUseCaseProvider.overrideWithValue(mockCreateNote),
        updateNoteUseCaseProvider.overrideWithValue(mockUpdateNote),
        deleteNoteUseCaseProvider.overrideWithValue(mockDeleteNote),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  NotesState readState() => container.read(notesViewModelProvider);
  NotesViewModel readNotifier() =>
      container.read(notesViewModelProvider.notifier);

  // ─── initial state ──────────────────────────────────────────────────

  group('initial state', () {
    test('should have correct initial values', () {
      final state = readState();
      expect(state.status, NotesStatus.initial);
      expect(state.notes, isEmpty);
      expect(state.workspaceId, isNull);
      expect(state.error, isNull);
    });
  });

  // ─── fetchWorkspaceNotes ────────────────────────────────────────────

  group('fetchWorkspaceNotes', () {
    test('should set state to loaded with sorted notes on success', () async {
      // arrange
      when(() => mockGetWorkspaceNotes(any()))
          .thenAnswer((_) async => Right([tNote1, tNote2]));

      // act
      final result = await readNotifier().fetchWorkspaceNotes(tWorkspaceId);

      // assert
      expect(result, true);
      final state = readState();
      expect(state.status, NotesStatus.loaded);
      expect(state.notes.length, 2);
      // newest first (note2 has later date)
      expect(state.notes.first.id, 'note-2');
      expect(state.workspaceId, tWorkspaceId);
      expect(state.error, isNull);
    });

    test('should set state to error on failure', () async {
      // arrange
      const failure = ApiFailure(message: 'Server error');
      when(() => mockGetWorkspaceNotes(any()))
          .thenAnswer((_) async => const Left(failure));

      // act
      final result = await readNotifier().fetchWorkspaceNotes(tWorkspaceId);

      // assert
      expect(result, false);
      final state = readState();
      expect(state.status, NotesStatus.error);
      expect(state.error, 'Server error');
    });

    test('should skip fetch if same workspace already loaded', () async {
      // arrange — first load
      when(() => mockGetWorkspaceNotes(any()))
          .thenAnswer((_) async => Right([tNote1]));
      await readNotifier().fetchWorkspaceNotes(tWorkspaceId);
      expect(readState().status, NotesStatus.loaded);

      // act — second call with same workspace
      final result = await readNotifier().fetchWorkspaceNotes(tWorkspaceId);

      // assert — should return true without calling usecase again
      expect(result, true);
      verify(() => mockGetWorkspaceNotes(any())).called(1); // only once
    });

    test('should refetch when workspace id changes', () async {
      // arrange — first load
      when(() => mockGetWorkspaceNotes(any()))
          .thenAnswer((_) async => Right([tNote1]));
      await readNotifier().fetchWorkspaceNotes(tWorkspaceId);

      // act — different workspace
      await readNotifier().fetchWorkspaceNotes('ws-456');

      // assert — called twice (different workspace ids)
      verify(() => mockGetWorkspaceNotes(any())).called(2);
    });

    test('should pass correct params to usecase', () async {
      // arrange
      when(() => mockGetWorkspaceNotes(any()))
          .thenAnswer((_) async => const Right([]));

      // act
      await readNotifier().fetchWorkspaceNotes(tWorkspaceId);

      // assert
      final captured =
          verify(() => mockGetWorkspaceNotes(captureAny())).captured;
      expect(captured.length, 1);
      final params = captured.first as GetWorkspaceNotesParams;
      expect(params.workspaceId, tWorkspaceId);
      expect(params.forceRefresh, false);
    });
  });

  // ─── refreshWorkspaceNotes ──────────────────────────────────────────

  group('refreshWorkspaceNotes', () {
    test('should set state to loaded with notes on success', () async {
      // arrange
      when(() => mockGetWorkspaceNotes(any()))
          .thenAnswer((_) async => Right([tNote1]));

      // act
      final result = await readNotifier().refreshWorkspaceNotes(tWorkspaceId);

      // assert
      expect(result, true);
      expect(readState().status, NotesStatus.loaded);
      expect(readState().notes.length, 1);
    });

    test('should pass forceRefresh=true to usecase', () async {
      // arrange
      when(() => mockGetWorkspaceNotes(any()))
          .thenAnswer((_) async => const Right([]));

      // act
      await readNotifier().refreshWorkspaceNotes(tWorkspaceId);

      // assert
      final captured =
          verify(() => mockGetWorkspaceNotes(captureAny())).captured;
      expect(captured.length, 1);
      final params = captured.first as GetWorkspaceNotesParams;
      expect(params.workspaceId, tWorkspaceId);
      expect(params.forceRefresh, true);
    });

    test('should set state to error on failure', () async {
      // arrange
      const failure = NetworkFailure();
      when(() => mockGetWorkspaceNotes(any()))
          .thenAnswer((_) async => const Left(failure));

      // act
      final result = await readNotifier().refreshWorkspaceNotes(tWorkspaceId);

      // assert
      expect(result, false);
      expect(readState().status, NotesStatus.error);
      expect(readState().error, 'Network connection failed');
    });
  });

  // ─── createNote ─────────────────────────────────────────────────────

  group('createNote', () {
    test('should prepend new note to list and return it on success', () async {
      // arrange — start with one existing note
      when(() => mockGetWorkspaceNotes(any()))
          .thenAnswer((_) async => Right([tNote1]));
      await readNotifier().fetchWorkspaceNotes(tWorkspaceId);

      final newNote = NoteEntity(
        id: 'note-new',
        workspaceId: tWorkspaceId,
        title: 'New Note',
        content: 'New Content',
        createdAt: DateTime(2025, 2, 1),
      );
      when(() => mockCreateNote(any())).thenAnswer((_) async => Right(newNote));

      // act
      final result = await readNotifier().createNote(
        workspaceId: tWorkspaceId,
        title: 'New Note',
        content: 'New Content',
      );

      // assert
      expect(result, isNotNull);
      expect(result!.id, 'note-new');
      final state = readState();
      expect(state.status, NotesStatus.loaded);
      expect(state.notes.first.id, 'note-new'); // prepended
      expect(state.notes.length, 2);
    });

    test('should return null and set error on failure', () async {
      // arrange
      const failure = ApiFailure(message: 'Create failed');
      when(() => mockCreateNote(any()))
          .thenAnswer((_) async => const Left(failure));

      // act
      final result = await readNotifier().createNote(
        workspaceId: tWorkspaceId,
        title: 'Title',
        content: 'Content',
      );

      // assert
      expect(result, isNull);
      expect(readState().status, NotesStatus.error);
      expect(readState().error, 'Create failed');
    });

    test('should set status to creating before the call', () async {
      // arrange
      NotesStatus? capturedStatus;
      when(() => mockCreateNote(any())).thenAnswer((_) async {
        capturedStatus = readState().status;
        return Right(tNote1);
      });

      // act
      await readNotifier().createNote(
        workspaceId: tWorkspaceId,
        title: 'Title',
        content: 'Content',
      );

      // assert
      expect(capturedStatus, NotesStatus.creating);
    });

    test('should pass correct params to usecase', () async {
      // arrange
      when(() => mockCreateNote(any())).thenAnswer((_) async => Right(tNote1));

      // act
      await readNotifier().createNote(
        workspaceId: tWorkspaceId,
        title: 'My Title',
        content: 'My Content',
      );

      // assert
      final captured =
          verify(() => mockCreateNote(captureAny())).captured;
      expect(captured.length, 1);
      final params = captured.first as CreateNoteParams;
      expect(params.workspaceId, tWorkspaceId);
      expect(params.title, 'My Title');
      expect(params.content, 'My Content');
    });
  });

  // ─── updateNote ─────────────────────────────────────────────────────

  group('updateNote', () {
    test('should replace note in list and return it on success', () async {
      // arrange — load initial notes
      when(() => mockGetWorkspaceNotes(any()))
          .thenAnswer((_) async => Right([tNote1, tNote2]));
      await readNotifier().fetchWorkspaceNotes(tWorkspaceId);

      final updatedNote = NoteEntity(
        id: 'note-1',
        workspaceId: tWorkspaceId,
        title: 'Updated Title',
        content: 'Updated Content',
        updatedAt: DateTime(2025, 2, 1),
      );
      when(() => mockUpdateNote(any()))
          .thenAnswer((_) async => Right(updatedNote));

      // act
      final result = await readNotifier().updateNote(
        noteId: 'note-1',
        title: 'Updated Title',
        content: 'Updated Content',
      );

      // assert
      expect(result, isNotNull);
      expect(result!.title, 'Updated Title');
      final state = readState();
      expect(state.status, NotesStatus.loaded);
      final note = state.notes.firstWhere((n) => n.id == 'note-1');
      expect(note.title, 'Updated Title');
      expect(state.notes.length, 2); // same count
    });

    test('should return null and set error on failure', () async {
      // arrange
      const failure = ApiFailure(message: 'Update failed');
      when(() => mockUpdateNote(any()))
          .thenAnswer((_) async => const Left(failure));

      // act
      final result = await readNotifier().updateNote(
        noteId: 'note-1',
        title: 'Title',
        content: 'Content',
      );

      // assert
      expect(result, isNull);
      expect(readState().status, NotesStatus.error);
      expect(readState().error, 'Update failed');
    });

    test('should set status to updating before the call', () async {
      // arrange
      NotesStatus? capturedStatus;
      when(() => mockUpdateNote(any())).thenAnswer((_) async {
        capturedStatus = readState().status;
        return Right(tNote1);
      });

      // act
      await readNotifier().updateNote(
        noteId: 'note-1',
        title: 'Title',
        content: 'Content',
      );

      // assert
      expect(capturedStatus, NotesStatus.updating);
    });
  });

  // ─── deleteNote ─────────────────────────────────────────────────────

  group('deleteNote', () {
    test('should remove note from list on success', () async {
      // arrange — load initial notes
      when(() => mockGetWorkspaceNotes(any()))
          .thenAnswer((_) async => Right([tNote1, tNote2]));
      await readNotifier().fetchWorkspaceNotes(tWorkspaceId);
      expect(readState().notes.length, 2);

      when(() => mockDeleteNote(any()))
          .thenAnswer((_) async => const Right(true));

      // act
      final result = await readNotifier().deleteNote('note-1');

      // assert
      expect(result, true);
      final state = readState();
      expect(state.status, NotesStatus.loaded);
      expect(state.notes.length, 1);
      expect(state.notes.first.id, 'note-2');
    });

    test('should return false and set error on failure', () async {
      // arrange
      const failure = ApiFailure(message: 'Delete failed');
      when(() => mockDeleteNote(any()))
          .thenAnswer((_) async => const Left(failure));

      // act
      final result = await readNotifier().deleteNote('note-1');

      // assert
      expect(result, false);
      expect(readState().status, NotesStatus.error);
      expect(readState().error, 'Delete failed');
    });

    test('should set status to deleting before the call', () async {
      // arrange
      NotesStatus? capturedStatus;
      when(() => mockDeleteNote(any())).thenAnswer((_) async {
        capturedStatus = readState().status;
        return const Right(true);
      });

      // act
      await readNotifier().deleteNote('note-1');

      // assert
      expect(capturedStatus, NotesStatus.deleting);
    });

    test('should pass correct noteId to usecase', () async {
      // arrange
      when(() => mockDeleteNote(any()))
          .thenAnswer((_) async => const Right(true));

      // act
      await readNotifier().deleteNote('note-1');

      // assert
      final captured =
          verify(() => mockDeleteNote(captureAny())).captured;
      expect(captured.length, 1);
      final params = captured.first as DeleteNoteParams;
      expect(params.noteId, 'note-1');
    });
  });

  // ─── clearError ─────────────────────────────────────────────────────

  group('clearError', () {
    test('should clear error from state', () async {
      // arrange — put into error state
      const failure = ApiFailure(message: 'some error');
      when(() => mockDeleteNote(any()))
          .thenAnswer((_) async => const Left(failure));
      await readNotifier().deleteNote('x');
      expect(readState().error, 'some error');

      // act
      readNotifier().clearError();

      // assert
      expect(readState().error, isNull);
    });
  });
}
