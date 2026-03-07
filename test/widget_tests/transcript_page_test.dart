import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motion_ai/feature/notes/domain/entities/note_entity.dart';
import 'package:motion_ai/feature/notes/presentation/pages/transcript_page.dart';
import 'package:motion_ai/feature/notes/presentation/state/transcript_state.dart';
import 'package:motion_ai/feature/notes/presentation/view_model/transcript_view_model.dart';

// ---- Fakes ----

class FakeTranscriptViewModel extends TranscriptViewModel {
  final TranscriptState _initialState;
  FakeTranscriptViewModel([TranscriptState? initial])
      : _initialState = initial ?? TranscriptState.initial();

  @override
  TranscriptState build() => _initialState;

  @override
  Future<void> fetchTranscript(String audioFileId) async {}

  @override
  Future<bool> transcribeAudio({
    required String audioFileId,
    required String workspaceId,
    String? noteTitle,
  }) async {
    return true;
  }
}

// ---- Test data ----

final tTranscriptNote = NoteEntity(
  id: 'note-t1',
  workspaceId: 'ws-1',
  title: 'Meeting Transcript',
  content: '<p>This is the transcript content from the meeting.</p>',
  type: 'VOICE_TRANSCRIPT',
  status: 'PUBLISHED',
  createdAt: DateTime(2025, 3, 1, 14, 30),
  updatedAt: DateTime(2025, 3, 1, 14, 30),
);

final tProcessingNote = NoteEntity(
  id: 'note-t2',
  workspaceId: 'ws-1',
  title: 'Processing Transcript',
  content: '',
  type: 'VOICE_TRANSCRIPT',
  status: 'PROCESSING',
  createdAt: DateTime(2025, 3, 1),
  updatedAt: DateTime(2025, 3, 1),
);

// ---- Helpers ----

void main() {
  Widget buildTranscriptPage({
    required FakeTranscriptViewModel vm,
    String audioFileId = 'audio-1',
    String? headerTitle,
  }) {
    return ProviderScope(
      overrides: [
        transcriptViewModelProvider.overrideWith(() => vm),
      ],
      child: MaterialApp(
        home: TranscriptPage(
          audioFileId: audioFileId,
          headerTitle: headerTitle,
        ),
      ),
    );
  }

  group('TranscriptPage loading state', () {
    testWidgets('shows CircularProgressIndicator when loading', (tester) async {
      final vm = FakeTranscriptViewModel(
        TranscriptState.initial().copyWith(status: TranscriptStatus.loading),
      );

      await tester.pumpWidget(buildTranscriptPage(vm: vm));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('TranscriptPage error state', () {
    testWidgets('shows error message when error and no note', (tester) async {
      final vm = FakeTranscriptViewModel(
        const TranscriptState(
          status: TranscriptStatus.error,
          note: null,
          error: 'Failed to load transcript',
        ),
      );

      await tester.pumpWidget(buildTranscriptPage(vm: vm));
      expect(find.text('Failed to load transcript'), findsOneWidget);
    });

    testWidgets('shows default error when error message is null',
        (tester) async {
      final vm = FakeTranscriptViewModel(
        const TranscriptState(
          status: TranscriptStatus.error,
          note: null,
          error: null,
        ),
      );

      await tester.pumpWidget(buildTranscriptPage(vm: vm));
      expect(find.text('Failed to load transcript'), findsOneWidget);
    });
  });

  group('TranscriptPage empty state', () {
    testWidgets('shows "No transcript found" when note is null and initial',
        (tester) async {
      final vm = FakeTranscriptViewModel(TranscriptState.initial());

      await tester.pumpWidget(buildTranscriptPage(vm: vm));
      expect(
        find.text('No transcript found for this recording yet.'),
        findsOneWidget,
      );
    });
  });

  group('TranscriptPage loaded state', () {
    testWidgets('displays transcript text with HTML stripped', (tester) async {
      final vm = FakeTranscriptViewModel(
        TranscriptState(
          status: TranscriptStatus.loaded,
          note: tTranscriptNote,
          error: null,
        ),
      );

      await tester.pumpWidget(buildTranscriptPage(vm: vm));

      expect(
        find.text('This is the transcript content from the meeting.'),
        findsOneWidget,
      );
    });

    testWidgets('displays the header title from parameter', (tester) async {
      final vm = FakeTranscriptViewModel(
        TranscriptState(
          status: TranscriptStatus.loaded,
          note: tTranscriptNote,
          error: null,
        ),
      );

      await tester.pumpWidget(
        buildTranscriptPage(vm: vm, headerTitle: 'Custom Title'),
      );

      expect(find.text('Custom Title'), findsOneWidget);
    });

    testWidgets('displays the note title when no header title provided',
        (tester) async {
      final vm = FakeTranscriptViewModel(
        TranscriptState(
          status: TranscriptStatus.loaded,
          note: tTranscriptNote,
          error: null,
        ),
      );

      await tester.pumpWidget(buildTranscriptPage(vm: vm));
      expect(find.text('Meeting Transcript'), findsOneWidget);
    });

    testWidgets('displays status chip with PUBLISHED label', (tester) async {
      final vm = FakeTranscriptViewModel(
        TranscriptState(
          status: TranscriptStatus.loaded,
          note: tTranscriptNote,
          error: null,
        ),
      );

      await tester.pumpWidget(buildTranscriptPage(vm: vm));
      expect(find.text('PUBLISHED'), findsOneWidget);
    });

    testWidgets('displays formatted timestamp', (tester) async {
      final vm = FakeTranscriptViewModel(
        TranscriptState(
          status: TranscriptStatus.loaded,
          note: tTranscriptNote,
          error: null,
        ),
      );

      await tester.pumpWidget(buildTranscriptPage(vm: vm));
      expect(find.textContaining('01 Mar 2025'), findsOneWidget);
    });
  });

  group('TranscriptPage processing state', () {
    testWidgets('shows "Transcribing..." when note status is PROCESSING',
        (tester) async {
      final vm = FakeTranscriptViewModel(
        TranscriptState(
          status: TranscriptStatus.loaded,
          note: tProcessingNote,
          error: null,
        ),
      );

      await tester.pumpWidget(buildTranscriptPage(vm: vm));
      expect(find.text('Transcribing... Please wait.'), findsOneWidget);
    });

    testWidgets('displays PROCESSING status chip', (tester) async {
      final vm = FakeTranscriptViewModel(
        TranscriptState(
          status: TranscriptStatus.loaded,
          note: tProcessingNote,
          error: null,
        ),
      );

      await tester.pumpWidget(buildTranscriptPage(vm: vm));
      expect(find.text('PROCESSING'), findsOneWidget);
    });
  });

  group('TranscriptPage navigation', () {
    testWidgets('displays back button', (tester) async {
      final vm = FakeTranscriptViewModel(TranscriptState.initial());

      await tester.pumpWidget(buildTranscriptPage(vm: vm));
      expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);
    });

    testWidgets('displays refresh button', (tester) async {
      final vm = FakeTranscriptViewModel(TranscriptState.initial());

      await tester.pumpWidget(buildTranscriptPage(vm: vm));
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });
  });
}
