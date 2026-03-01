import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motion_ai/core/services/sensor/shake_detection_service.dart';
import 'package:motion_ai/core/sync/notes_auto_sync.dart';
import 'package:motion_ai/feature/home/presentation/pages/widgets/notes_card_widget.dart';
import 'package:motion_ai/feature/notes/domain/entities/note_entity.dart';
import 'package:motion_ai/feature/notes/presentation/pages/notes_view.dart';
import 'package:motion_ai/feature/notes/presentation/view_model/notes_view_model.dart';
import 'package:motion_ai/feature/notes/presentation/state/notes_state.dart';
import 'package:motion_ai/feature/workspace/domain/entities/workspace_entity.dart';
import 'package:motion_ai/feature/workspace/presentation/view_model/workspace_view_model.dart';
import 'package:motion_ai/feature/workspace/presentation/state/workspace_state.dart';

// ---- Fakes ----

class FakeWorkspaceViewModel extends WorkspaceViewModel {
  final WorkspaceState _initialState;
  FakeWorkspaceViewModel([WorkspaceState? initial])
      : _initialState = initial ?? WorkspaceState.initial();
  @override
  WorkspaceState build() => _initialState;
}

class FakeNotesViewModel extends NotesViewModel {
  final NotesState _initialState;
  FakeNotesViewModel([NotesState? initial])
      : _initialState = initial ?? NotesState.initial();

  @override
  NotesState build() => _initialState;

  @override
  Future<bool> fetchWorkspaceNotes(String workspaceId) async => true;

  @override
  Future<bool> refreshWorkspaceNotes(String workspaceId) async => true;

  @override
  Future<bool> deleteNote(String noteId) async {
    final updated = state.notes.where((n) => n.id != noteId).toList();
    state = state.copyWith(status: NotesStatus.loaded, notes: updated);
    return true;
  }
}

class FakeNotesAutoSyncNotifier extends NotesAutoSyncNotifier {
  final NotesSyncState _initialState;
  FakeNotesAutoSyncNotifier([NotesSyncState? initial])
      : _initialState = initial ?? NotesSyncState.idle;
  @override
  NotesSyncState build() => _initialState;
  @override
  Future<void> trySync() async {}
}

class FakeShakeDetectionService extends ShakeDetectionService {
  @override
  void startListening({required OnShakeDetected onShakeDetected}) {}
  @override
  void stopListening() {}
}

// ---- Test data ----

final tWorkspace = WorkspaceEntity(
  id: 'ws-1',
  name: 'Test Workspace',
  createdAt: DateTime(2025, 1, 1),
);

WorkspaceState wsWithSelected() => WorkspaceState(
      isLoading: false,
      workspaces: [tWorkspace],
      selected: tWorkspace,
      error: null,
    );

final tNote1 = NoteEntity(
  id: 'note-1',
  workspaceId: 'ws-1',
  title: 'First Note',
  content: '<p>Hello world content</p>',
  type: 'MANUAL',
  createdAt: DateTime(2025, 1, 1),
  updatedAt: DateTime(2025, 1, 1),
);

final tNote2 = NoteEntity(
  id: 'note-2',
  workspaceId: 'ws-1',
  title: 'Second Note',
  content: '<p>Voice transcript data</p>',
  type: 'VOICE_TRANSCRIPT',
  createdAt: DateTime(2025, 1, 2),
  updatedAt: DateTime(2025, 1, 2),
);

final tNote3 = NoteEntity(
  id: 'note-3',
  workspaceId: 'ws-1',
  title: 'Meeting Minutes',
  content: '<p>Discussion about project</p>',
  type: 'MEETING_SUMMARY',
  createdAt: DateTime(2025, 1, 3),
  updatedAt: DateTime(2025, 1, 3),
);

NotesState loadedWithNotes([List<NoteEntity>? notes]) => NotesState(
      status: NotesStatus.loaded,
      notes: notes ?? [tNote1, tNote2, tNote3],
      workspaceId: 'ws-1',
      error: null,
    );

// ---- Helpers ----

void main() {
  Widget buildNotesView({
    FakeWorkspaceViewModel? wsVm,
    FakeNotesViewModel? notesVm,
    FakeNotesAutoSyncNotifier? syncNotifier,
  }) {
    return ProviderScope(
      overrides: [
        workspaceViewModelProvider
            .overrideWith(() => wsVm ?? FakeWorkspaceViewModel()),
        notesViewModelProvider
            .overrideWith(() => notesVm ?? FakeNotesViewModel()),
        notesAutoSyncProvider
            .overrideWith(() => syncNotifier ?? FakeNotesAutoSyncNotifier()),
        shakeDetectionServiceProvider
            .overrideWithValue(FakeShakeDetectionService()),
      ],
      child: const MaterialApp(home: NotesListView()),
    );
  }

  group('NotesListView rendering', () {
    testWidgets('displays NOTES title', (tester) async {
      await tester.pumpWidget(buildNotesView());
      expect(find.textContaining('NOTES'), findsOneWidget);
    });

    testWidgets('displays search icon', (tester) async {
      await tester.pumpWidget(buildNotesView());
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('displays filter chips', (tester) async {
      await tester.pumpWidget(buildNotesView());

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Manual'), findsOneWidget);
      expect(find.text('Transcript'), findsOneWidget);
      expect(find.text('Meeting'), findsOneWidget);
    });

    testWidgets('displays filter chip icons', (tester) async {
      await tester.pumpWidget(buildNotesView());

      expect(find.byIcon(Icons.edit_note), findsOneWidget);
      expect(find.byIcon(Icons.mic), findsOneWidget);
      expect(find.byIcon(Icons.groups), findsOneWidget);
    });
  });

  group('NotesListView empty / no-workspace states', () {
    testWidgets('shows "Select a workspace" when no workspace is selected',
        (tester) async {
      await tester.pumpWidget(buildNotesView());
      expect(find.text('Select a workspace to see notes'), findsOneWidget);
    });

    testWidgets('shows "No notes yet" when workspace selected but no notes',
        (tester) async {
      final wsVm = FakeWorkspaceViewModel(wsWithSelected());
      final notesVm = FakeNotesViewModel(NotesState(
        status: NotesStatus.loaded,
        notes: [],
        workspaceId: 'ws-1',
        error: null,
      ));

      await tester.pumpWidget(buildNotesView(wsVm: wsVm, notesVm: notesVm));
      expect(find.text('No notes yet'), findsOneWidget);
    });

    testWidgets('shows error message when status is error', (tester) async {
      final wsVm = FakeWorkspaceViewModel(wsWithSelected());
      final notesVm = FakeNotesViewModel(const NotesState(
        status: NotesStatus.error,
        notes: [],
        workspaceId: 'ws-1',
        error: 'Failed to load notes',
      ));

      await tester.pumpWidget(buildNotesView(wsVm: wsVm, notesVm: notesVm));
      expect(find.text('Failed to load notes'), findsOneWidget);
    });

    testWidgets('shows loading spinner when status is loading', (tester) async {
      final wsVm = FakeWorkspaceViewModel(wsWithSelected());
      final notesVm = FakeNotesViewModel(const NotesState(
        status: NotesStatus.loading,
        notes: [],
        workspaceId: 'ws-1',
        error: null,
      ));

      await tester.pumpWidget(buildNotesView(wsVm: wsVm, notesVm: notesVm));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('NotesListView with notes', () {
    testWidgets('displays NoteCard for each note', (tester) async {
      final wsVm = FakeWorkspaceViewModel(wsWithSelected());
      final notesVm = FakeNotesViewModel(loadedWithNotes());

      await tester.pumpWidget(buildNotesView(wsVm: wsVm, notesVm: notesVm));

      expect(find.byType(NoteCard), findsNWidgets(3));
    });

    testWidgets('displays note titles', (tester) async {
      final wsVm = FakeWorkspaceViewModel(wsWithSelected());
      final notesVm = FakeNotesViewModel(loadedWithNotes());

      await tester.pumpWidget(buildNotesView(wsVm: wsVm, notesVm: notesVm));

      expect(find.text('First Note'), findsOneWidget);
      expect(find.text('Second Note'), findsOneWidget);
      expect(find.text('Meeting Minutes'), findsOneWidget);
    });

    testWidgets('displays note type category labels', (tester) async {
      final wsVm = FakeWorkspaceViewModel(wsWithSelected());
      final notesVm = FakeNotesViewModel(loadedWithNotes());

      await tester.pumpWidget(buildNotesView(wsVm: wsVm, notesVm: notesVm));

      expect(find.text('Manual Note'), findsOneWidget);
      expect(find.text('Voice Transcript'), findsOneWidget);
      expect(find.text('Meeting Summary'), findsOneWidget);
    });

    testWidgets('displays plain-text preview from HTML content', (tester) async {
      final wsVm = FakeWorkspaceViewModel(wsWithSelected());
      final notesVm = FakeNotesViewModel(loadedWithNotes([tNote1]));

      await tester.pumpWidget(buildNotesView(wsVm: wsVm, notesVm: notesVm));

      expect(find.text('Hello world content'), findsOneWidget);
    });

    testWidgets('displays formatted timestamp', (tester) async {
      final wsVm = FakeWorkspaceViewModel(wsWithSelected());
      final notesVm = FakeNotesViewModel(loadedWithNotes([tNote1]));

      await tester.pumpWidget(buildNotesView(wsVm: wsVm, notesVm: notesVm));

      // DateTime(2025, 1, 1) formatted as "01 Jan 2025 • 00:00"
      expect(find.textContaining('01 Jan 2025'), findsOneWidget);
    });
  });

  group('NotesListView search', () {
    testWidgets('tapping search icon shows search field', (tester) async {
      final wsVm = FakeWorkspaceViewModel(wsWithSelected());
      final notesVm = FakeNotesViewModel(loadedWithNotes());

      await tester.pumpWidget(buildNotesView(wsVm: wsVm, notesVm: notesVm));

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      expect(find.text('Search notes...'), findsOneWidget);
      expect(find.textContaining('NOTES'), findsNothing);
    });

    testWidgets('search filters notes by title', (tester) async {
      final wsVm = FakeWorkspaceViewModel(wsWithSelected());
      final notesVm = FakeNotesViewModel(loadedWithNotes());

      await tester.pumpWidget(buildNotesView(wsVm: wsVm, notesVm: notesVm));

      // Open search
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Type search query
      await tester.enterText(find.byType(TextField), 'First');
      await tester.pumpAndSettle();

      expect(find.text('First Note'), findsOneWidget);
      expect(find.text('Second Note'), findsNothing);
      expect(find.text('Meeting Minutes'), findsNothing);
    });

    testWidgets('shows no results message for unmatched query', (tester) async {
      final wsVm = FakeWorkspaceViewModel(wsWithSelected());
      final notesVm = FakeNotesViewModel(loadedWithNotes());

      await tester.pumpWidget(buildNotesView(wsVm: wsVm, notesVm: notesVm));

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'zzzzz');
      await tester.pumpAndSettle();

      expect(find.textContaining('No results for'), findsOneWidget);
    });

    testWidgets('closing search restores NOTES title', (tester) async {
      final wsVm = FakeWorkspaceViewModel(wsWithSelected());
      final notesVm = FakeNotesViewModel(loadedWithNotes());

      await tester.pumpWidget(buildNotesView(wsVm: wsVm, notesVm: notesVm));

      // Open search
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      expect(find.textContaining('NOTES'), findsNothing);

      // Close search via the close button
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.textContaining('NOTES'), findsOneWidget);
    });
  });

  group('NotesListView filter chips', () {
    testWidgets('tapping Manual filter shows only manual notes', (tester) async {
      final wsVm = FakeWorkspaceViewModel(wsWithSelected());
      final notesVm = FakeNotesViewModel(loadedWithNotes());

      await tester.pumpWidget(buildNotesView(wsVm: wsVm, notesVm: notesVm));

      await tester.tap(find.text('Manual'));
      await tester.pumpAndSettle();

      expect(find.text('First Note'), findsOneWidget);
      expect(find.text('Second Note'), findsNothing);
      expect(find.text('Meeting Minutes'), findsNothing);
    });

    testWidgets('tapping Transcript filter shows only transcript notes',
        (tester) async {
      final wsVm = FakeWorkspaceViewModel(wsWithSelected());
      final notesVm = FakeNotesViewModel(loadedWithNotes());

      await tester.pumpWidget(buildNotesView(wsVm: wsVm, notesVm: notesVm));

      await tester.tap(find.text('Transcript'));
      await tester.pumpAndSettle();

      expect(find.text('First Note'), findsNothing);
      expect(find.text('Second Note'), findsOneWidget);
      expect(find.text('Meeting Minutes'), findsNothing);
    });

    testWidgets('tapping Meeting filter shows only meeting notes',
        (tester) async {
      final wsVm = FakeWorkspaceViewModel(wsWithSelected());
      final notesVm = FakeNotesViewModel(loadedWithNotes());

      await tester.pumpWidget(buildNotesView(wsVm: wsVm, notesVm: notesVm));

      await tester.tap(find.text('Meeting'));
      await tester.pumpAndSettle();

      expect(find.text('First Note'), findsNothing);
      expect(find.text('Second Note'), findsNothing);
      expect(find.text('Meeting Minutes'), findsOneWidget);
    });

    testWidgets('tapping All filter restores all notes', (tester) async {
      final wsVm = FakeWorkspaceViewModel(wsWithSelected());
      final notesVm = FakeNotesViewModel(loadedWithNotes());

      await tester.pumpWidget(buildNotesView(wsVm: wsVm, notesVm: notesVm));

      // First filter to Manual
      await tester.tap(find.text('Manual'));
      await tester.pumpAndSettle();
      expect(find.byType(NoteCard), findsOneWidget);

      // Then switch back to All
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();
      expect(find.byType(NoteCard), findsNWidgets(3));
    });
  });

  group('NotesListView selection mode', () {
    testWidgets('long press enters selection mode', (tester) async {
      final wsVm = FakeWorkspaceViewModel(wsWithSelected());
      final notesVm = FakeNotesViewModel(loadedWithNotes());

      await tester.pumpWidget(buildNotesView(wsVm: wsVm, notesVm: notesVm));

      // Long press the first note
      await tester.longPress(find.text('First Note'));
      await tester.pumpAndSettle();

      // Selection bar should appear with "1 selected"
      expect(find.text('1 selected'), findsOneWidget);
      // Delete icon should appear in selection mode
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });

    testWidgets('tapping another note in selection mode selects it',
        (tester) async {
      final wsVm = FakeWorkspaceViewModel(wsWithSelected());
      final notesVm = FakeNotesViewModel(loadedWithNotes());

      await tester.pumpWidget(buildNotesView(wsVm: wsVm, notesVm: notesVm));

      // Long press to enter selection mode
      await tester.longPress(find.text('First Note'));
      await tester.pumpAndSettle();
      expect(find.text('1 selected'), findsOneWidget);

      // Tap second note to add to selection
      await tester.tap(find.text('Second Note'));
      await tester.pumpAndSettle();
      expect(find.text('2 selected'), findsOneWidget);
    });

    testWidgets('close button exits selection mode', (tester) async {
      final wsVm = FakeWorkspaceViewModel(wsWithSelected());
      final notesVm = FakeNotesViewModel(loadedWithNotes());

      await tester.pumpWidget(buildNotesView(wsVm: wsVm, notesVm: notesVm));

      // Long press to enter selection mode
      await tester.longPress(find.text('First Note'));
      await tester.pumpAndSettle();
      expect(find.text('1 selected'), findsOneWidget);

      // Tap close button
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Selection bar gone, NOTES title back
      expect(find.text('1 selected'), findsNothing);
      expect(find.textContaining('NOTES'), findsOneWidget);
    });

    testWidgets('selection mode hides filter chips', (tester) async {
      final wsVm = FakeWorkspaceViewModel(wsWithSelected());
      final notesVm = FakeNotesViewModel(loadedWithNotes());

      await tester.pumpWidget(buildNotesView(wsVm: wsVm, notesVm: notesVm));

      // Verify filter chips visible
      expect(find.text('Manual'), findsOneWidget);

      // Enter selection
      await tester.longPress(find.text('First Note'));
      await tester.pumpAndSettle();

      // Filter chips should be hidden
      expect(find.text('Manual'), findsNothing);
    });
  });

  group('NotesListView syncing state', () {
    testWidgets('shows Syncing pill when sync is in progress', (tester) async {
      final wsVm = FakeWorkspaceViewModel(wsWithSelected());
      final notesVm = FakeNotesViewModel(loadedWithNotes());
      final syncNotifier = FakeNotesAutoSyncNotifier(
        const NotesSyncState(isSyncing: true),
      );

      await tester.pumpWidget(buildNotesView(
        wsVm: wsVm,
        notesVm: notesVm,
        syncNotifier: syncNotifier,
      ));

      expect(find.text('Syncing…'), findsOneWidget);
    });
  });
}
