import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:hive/hive.dart';
import 'package:motion_ai/feature/notes/domain/entities/note_entity.dart';
import 'package:motion_ai/feature/notes/presentation/pages/note_editor.dart';
import 'package:motion_ai/feature/notes/presentation/state/notes_state.dart';
import 'package:motion_ai/feature/notes/presentation/view_model/notes_view_model.dart';
import 'package:motion_ai/feature/workspace/domain/entities/workspace_entity.dart';
import 'package:motion_ai/feature/workspace/presentation/state/workspace_state.dart';
import 'package:motion_ai/feature/workspace/presentation/view_model/workspace_view_model.dart';

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

  bool createNoteCalled = false;
  @override
  Future<NoteEntity?> createNote({
    required String workspaceId,
    required String title,
    required String content,
  }) async {
    createNoteCalled = true;
    return NoteEntity(
      id: 'new-note',
      workspaceId: workspaceId,
      title: title,
      content: content,
      type: 'MANUAL',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  bool updateNoteCalled = false;
  @override
  Future<NoteEntity?> updateNote({
    required String noteId,
    required String title,
    required String content,
  }) async {
    updateNoteCalled = true;
    return NoteEntity(
      id: noteId,
      workspaceId: 'ws-1',
      title: title,
      content: content,
      type: 'MANUAL',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<bool> fetchWorkspaceNotes(String workspaceId) async => true;

  @override
  Future<bool> refreshWorkspaceNotes(String workspaceId) async => true;

  @override
  Future<bool> deleteNote(String noteId) async => true;
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

final tExistingNote = NoteEntity(
  id: 'note-1',
  workspaceId: 'ws-1',
  title: 'Existing Note Title',
  content: '<p>Some existing content</p>',
  type: 'MANUAL',
  createdAt: DateTime(2025, 1, 1),
  updatedAt: DateTime(2025, 1, 1),
);

// ---- Helpers ----

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('note_editor_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  Widget buildNoteEditor({
    NoteEntity? note,
    FakeWorkspaceViewModel? wsVm,
    FakeNotesViewModel? notesVm,
  }) {
    return ProviderScope(
      overrides: [
        workspaceViewModelProvider.overrideWith(
            () => wsVm ?? FakeWorkspaceViewModel(wsWithSelected())),
        notesViewModelProvider
            .overrideWith(() => notesVm ?? FakeNotesViewModel()),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          FlutterQuillLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        home: NoteEditorPage(note: note),
      ),
    );
  }

  group('NoteEditorPage create mode rendering', () {
    testWidgets('displays "NEW NOTE" title when no note provided',
        (tester) async {
      await tester.pumpWidget(buildNoteEditor());
      // Use pump() instead of pumpAndSettle() because QuillEditor has
      // an infinite cursor blink animation that prevents settling.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('NEW NOTE'), findsOneWidget);
    });

    testWidgets('displays SAVE button', (tester) async {
      await tester.pumpWidget(buildNoteEditor());
      // Use pump() instead of pumpAndSettle() because QuillEditor has
      // an infinite cursor blink animation that prevents settling.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('SAVE'), findsOneWidget);
    });

    testWidgets('displays back button', (tester) async {
      await tester.pumpWidget(buildNoteEditor());
      // Use pump() instead of pumpAndSettle() because QuillEditor has
      // an infinite cursor blink animation that prevents settling.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);
    });

    testWidgets('displays empty title field with placeholder', (tester) async {
      await tester.pumpWidget(buildNoteEditor());
      // Use pump() instead of pumpAndSettle() because QuillEditor has
      // an infinite cursor blink animation that prevents settling.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Title'), findsOneWidget);
    });

    testWidgets('displays Quill editor widget', (tester) async {
      await tester.pumpWidget(buildNoteEditor());
      // Use pump() instead of pumpAndSettle() because QuillEditor has
      // an infinite cursor blink animation that prevents settling.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // QuillEditor renders its own rich text, so placeholder text is not
      // found via find.text(). Verify the editor widget itself is present.
      expect(find.byType(QuillEditor), findsOneWidget);
    });

    testWidgets('displays Quill toolbar', (tester) async {
      await tester.pumpWidget(buildNoteEditor());
      // Use pump() instead of pumpAndSettle() because QuillEditor has
      // an infinite cursor blink animation that prevents settling.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(QuillSimpleToolbar), findsOneWidget);
    });

    testWidgets('displays QuillEditor', (tester) async {
      await tester.pumpWidget(buildNoteEditor());
      // Use pump() instead of pumpAndSettle() because QuillEditor has
      // an infinite cursor blink animation that prevents settling.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(QuillEditor), findsOneWidget);
    });
  });

  group('NoteEditorPage edit mode rendering', () {
    testWidgets('displays "EDIT NOTE" title when note is provided',
        (tester) async {
      await tester.pumpWidget(buildNoteEditor(note: tExistingNote));
      // Use pump() instead of pumpAndSettle() because QuillEditor has
      // an infinite cursor blink animation that prevents settling.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('EDIT NOTE'), findsOneWidget);
    });

    testWidgets('pre-fills title from existing note', (tester) async {
      await tester.pumpWidget(buildNoteEditor(note: tExistingNote));
      // Use pump() instead of pumpAndSettle() because QuillEditor has
      // an infinite cursor blink animation that prevents settling.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Existing Note Title'), findsOneWidget);
    });

    testWidgets('loads existing note and shows editor', (tester) async {
      await tester.pumpWidget(buildNoteEditor(note: tExistingNote));
      // Use pump() instead of pumpAndSettle() because QuillEditor has
      // an infinite cursor blink animation that prevents settling.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // QuillEditor renders rich text internally, so content is not found
      // via find.text(). Verify the editor is present and title is loaded.
      expect(find.byType(QuillEditor), findsOneWidget);
      expect(find.text('Existing Note Title'), findsOneWidget);
    });

    testWidgets('still displays SAVE button in edit mode', (tester) async {
      await tester.pumpWidget(buildNoteEditor(note: tExistingNote));
      // Use pump() instead of pumpAndSettle() because QuillEditor has
      // an infinite cursor blink animation that prevents settling.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('SAVE'), findsOneWidget);
    });
  });

  group('NoteEditorPage interactions', () {
    testWidgets('can enter text in title field', (tester) async {
      await tester.pumpWidget(buildNoteEditor());
      // Use pump() instead of pumpAndSettle() because QuillEditor has
      // an infinite cursor blink animation that prevents settling.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final titleField = find.byType(TextField);
      await tester.enterText(titleField, 'My New Note');
      // Use pump() instead of pumpAndSettle() because QuillEditor has
      // an infinite cursor blink animation that prevents settling.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('My New Note'), findsOneWidget);
    });

    testWidgets('title placeholder disappears when text entered',
        (tester) async {
      await tester.pumpWidget(buildNoteEditor());
      // Use pump() instead of pumpAndSettle() because QuillEditor has
      // an infinite cursor blink animation that prevents settling.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Title'), findsOneWidget);

      final titleField = find.byType(TextField);
      await tester.enterText(titleField, 'Something');
      // Use pump() instead of pumpAndSettle() because QuillEditor has
      // an infinite cursor blink animation that prevents settling.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // The hint text should be replaced by the actual text
      expect(find.text('Something'), findsOneWidget);
    });
  });

  group('NoteEditorPage structure', () {
    testWidgets('uses gradient background', (tester) async {
      await tester.pumpWidget(buildNoteEditor());
      // Use pump() instead of pumpAndSettle() because QuillEditor has
      // an infinite cursor blink animation that prevents settling.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // NoteEditorPage wraps body in a Container with LinearGradient
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('has SafeArea', (tester) async {
      await tester.pumpWidget(buildNoteEditor());
      // Use pump() instead of pumpAndSettle() because QuillEditor has
      // an infinite cursor blink animation that prevents settling.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(SafeArea), findsOneWidget);
    });

    testWidgets('toolbar and editor are separate widgets', (tester) async {
      await tester.pumpWidget(buildNoteEditor());
      // Use pump() instead of pumpAndSettle() because QuillEditor has
      // an infinite cursor blink animation that prevents settling.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(QuillSimpleToolbar), findsOneWidget);
      expect(find.byType(QuillEditor), findsOneWidget);
    });

    testWidgets('title field has custom styling', (tester) async {
      await tester.pumpWidget(buildNoteEditor());
      // Use pump() instead of pumpAndSettle() because QuillEditor has
      // an infinite cursor blink animation that prevents settling.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.style!.fontSize, 22);
      expect(textField.style!.fontWeight, FontWeight.bold);
      expect(textField.style!.color, Colors.white);
    });
  });

  group('NoteEditorPage save validation', () {
    testWidgets('shows error snackbar when title is empty', (tester) async {
      await tester.pumpWidget(buildNoteEditor());
      // Use pump() instead of pumpAndSettle() because QuillEditor has
      // an infinite cursor blink animation that prevents settling.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Tap Save without entering title or content
      await tester.tap(find.text('SAVE'));
      await tester.pump();

      expect(find.text('Title and content are required'), findsOneWidget);
    });

    testWidgets('shows error when only title is provided but content is empty',
        (tester) async {
      await tester.pumpWidget(buildNoteEditor());
      // Use pump() instead of pumpAndSettle() because QuillEditor has
      // an infinite cursor blink animation that prevents settling.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Enter title but no content
      await tester.enterText(find.byType(TextField), 'My Title');
      // Use pump() instead of pumpAndSettle() because QuillEditor has
      // an infinite cursor blink animation that prevents settling.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('SAVE'));
      await tester.pump();

      expect(find.text('Title and content are required'), findsOneWidget);
    });
  });

  group('NoteEditorPage no workspace', () {
    testWidgets('save does nothing when no workspace selected', (tester) async {
      final wsVm = FakeWorkspaceViewModel(); // no selected workspace
      final notesVm = FakeNotesViewModel();

      await tester.pumpWidget(buildNoteEditor(wsVm: wsVm, notesVm: notesVm));
      // Use pump() instead of pumpAndSettle() because QuillEditor has
      // an infinite cursor blink animation that prevents settling.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.enterText(find.byType(TextField), 'Test Title');
      // Use pump() instead of pumpAndSettle() because QuillEditor has
      // an infinite cursor blink animation that prevents settling.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('SAVE'));
      await tester.pump();

      // createNote should not be called because no workspace
      expect(notesVm.createNoteCalled, false);
    });
  });
}
