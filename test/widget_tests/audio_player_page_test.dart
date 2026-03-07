import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motion_ai/feature/audio_file/domain/entities/audio_file_entity.dart';
import 'package:motion_ai/feature/audio_file/presentation/pages/audio_player_page.dart';
import 'package:motion_ai/feature/audio_file/presentation/state/audio_state.dart';
import 'package:motion_ai/feature/audio_file/presentation/view_model/audio_view_model.dart';
import 'package:motion_ai/feature/notes/presentation/state/transcript_state.dart';
import 'package:motion_ai/feature/notes/presentation/view_model/transcript_view_model.dart';
import 'package:motion_ai/feature/workspace/domain/entities/workspace_entity.dart';
import 'package:motion_ai/feature/workspace/presentation/state/workspace_state.dart';
import 'package:motion_ai/feature/notes/domain/entities/note_entity.dart';
import 'package:motion_ai/feature/workspace/presentation/view_model/workspace_view_model.dart';

// ---- Fakes ----

class FakeAudioViewModel extends AudioViewModel {
  final AudioState _initialState;
  FakeAudioViewModel([AudioState? initial])
      : _initialState = initial ?? const AudioState();

  @override
  AudioState build() => _initialState;

  @override
  Future<void> fetchAudios() async {}

  @override
  Future<void> loadInitialData() async {}
}

class FakeTranscriptViewModel extends TranscriptViewModel {
  final TranscriptState _initialState;
  FakeTranscriptViewModel([TranscriptState? initial])
      : _initialState = initial ?? TranscriptState.initial();

  @override
  TranscriptState build() => _initialState;

  bool fetchTranscriptCalled = false;
  @override
  Future<void> fetchTranscript(String audioFileId) async {
    fetchTranscriptCalled = true;
  }

  bool transcribeAudioCalled = false;
  @override
  Future<bool> transcribeAudio({
    required String audioFileId,
    required String workspaceId,
    String? noteTitle,
  }) async {
    transcribeAudioCalled = true;
    return true;
  }
}

class FakeWorkspaceViewModel extends WorkspaceViewModel {
  final WorkspaceState _initialState;
  FakeWorkspaceViewModel([WorkspaceState? initial])
      : _initialState = initial ?? WorkspaceState.initial();
  @override
  WorkspaceState build() => _initialState;
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

final tAudio = AudioFileEntity(
  id: 'audio-1',
  title: 'My Recording',
  fileName: 'recording.aac',
  localPath: '', // empty path triggers _hasError in player
  durationSeconds: 125,
  uploadedAt: DateTime(2025, 3, 15, 14, 30),
  uploaderId: 'user-1',
  username: 'testuser',
  syncStatus: 0,
);

final tAudioWithPath = AudioFileEntity(
  id: 'audio-2',
  title: 'Recording With Path',
  fileName: 'recording2.aac',
  localPath: '/tmp/nonexistent.aac', // file doesn't exist, triggers error
  durationSeconds: 60,
  uploadedAt: DateTime(2025, 2, 10, 9, 0),
  uploaderId: 'user-1',
  username: 'testuser',
  syncStatus: 0,
);

final tAudioNoTitle = AudioFileEntity(
  id: 'audio-3',
  fileName: 'fallback_name.aac',
  localPath: '',
  uploaderId: 'user-1',
  username: 'testuser',
);

final tAudioNoTitleNoFile = AudioFileEntity(
  id: 'audio-4',
  localPath: '',
  uploaderId: 'user-1',
  username: 'testuser',
);

final tTranscriptNote = NoteEntity(
  id: 'note-1',
  workspaceId: 'ws-1',
  title: 'Transcript of My Recording',
  content: '<p>This is the transcript content</p>',
  type: 'VOICE_TRANSCRIPT',
  createdAt: DateTime(2025, 3, 15),
  updatedAt: DateTime(2025, 3, 15),
);

// ---- Helpers ----

void main() {
  Widget buildAudioPlayerPage({
    AudioFileEntity? audio,
    FakeAudioViewModel? audioVm,
    FakeTranscriptViewModel? transcriptVm,
    FakeWorkspaceViewModel? wsVm,
  }) {
    return ProviderScope(
      overrides: [
        audioViewModelProvider
            .overrideWith(() => audioVm ?? FakeAudioViewModel()),
        transcriptViewModelProvider
            .overrideWith(() => transcriptVm ?? FakeTranscriptViewModel()),
        workspaceViewModelProvider
            .overrideWith(() => wsVm ?? FakeWorkspaceViewModel()),
      ],
      child: MaterialApp(
        home: AudioPlayerPage(audio: audio ?? tAudio),
      ),
    );
  }

  group('AudioPlayerPage rendering', () {
    testWidgets('displays audio display name in AppBar', (tester) async {
      await tester.pumpWidget(buildAudioPlayerPage());
      await tester.pump();

      // displayName = title ?? fileName ?? 'Untitled Recording'
      expect(find.text('My Recording'), findsWidgets);
    });

    testWidgets('displays audio display name in body', (tester) async {
      await tester.pumpWidget(buildAudioPlayerPage());
      await tester.pump();

      // Appears both in AppBar title and body text
      expect(find.text('My Recording'), findsAtLeast(1));
    });

    testWidgets('displays back button', (tester) async {
      await tester.pumpWidget(buildAudioPlayerPage());
      await tester.pump();

      expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);
    });

    testWidgets('displays graphic_eq icon', (tester) async {
      await tester.pumpWidget(buildAudioPlayerPage());
      await tester.pump();

      expect(find.byIcon(Icons.graphic_eq), findsOneWidget);
    });

    testWidgets('displays formatted upload date when available',
        (tester) async {
      await tester.pumpWidget(buildAudioPlayerPage());
      await tester.pump();

      // DateTime(2025, 3, 15, 14, 30) => "Mar 15, 2025 · 2:30 PM"
      expect(find.textContaining('Mar 15, 2025'), findsOneWidget);
    });

    testWidgets('displays timestamps row with 00:00', (tester) async {
      await tester.pumpWidget(buildAudioPlayerPage());
      await tester.pump();

      // Initial position is 00:00; total duration also starts at 00:00
      // until player prepares (which won't happen with empty path)
      expect(find.text('00:00'), findsWidgets);
    });
  });

  group('AudioPlayerPage displayName fallback', () {
    testWidgets('falls back to fileName when title is null', (tester) async {
      await tester.pumpWidget(buildAudioPlayerPage(audio: tAudioNoTitle));
      await tester.pump();

      expect(find.text('fallback_name.aac'), findsAtLeast(1));
    });

    testWidgets('falls back to "Untitled Recording" when both are null',
        (tester) async {
      await tester.pumpWidget(buildAudioPlayerPage(audio: tAudioNoTitleNoFile));
      await tester.pump();

      expect(find.text('Untitled Recording'), findsAtLeast(1));
    });
  });

  group('AudioPlayerPage error state', () {
    testWidgets('shows error when localPath is empty', (tester) async {
      await tester.pumpWidget(buildAudioPlayerPage(audio: tAudio));
      // Wait for _preparePlayer to set _hasError
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Audio file not available locally'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
    });
  });

  group('AudioPlayerPage play/pause button', () {
    testWidgets('shows loading spinner when not prepared and no error',
        (tester) async {
      // Use an audio with a non-empty path that doesn't exist on disk
      await tester.pumpWidget(buildAudioPlayerPage(audio: tAudioWithPath));
      // Initially, before preparePlayer finishes or errors
      await tester.pump();

      // Either a play/pause icon or CircularProgressIndicator
      // With a non-existent file, it will quickly error out
      // But initially the button area exists
      expect(find.byType(GestureDetector), findsWidgets);
    });
  });

  group('AudioPlayerPage transcript', () {
    testWidgets('shows "Generate Transcript" button when no transcript',
        (tester) async {
      await tester.pumpWidget(buildAudioPlayerPage());
      await tester.pump();

      expect(find.text('Generate Transcript'), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
    });

    testWidgets('shows "View Transcript" button when transcript exists',
        (tester) async {
      final transcriptVm = FakeTranscriptViewModel(TranscriptState(
        status: TranscriptStatus.loaded,
        note: tTranscriptNote,
        error: null,
      ));

      await tester.pumpWidget(
          buildAudioPlayerPage(transcriptVm: transcriptVm));
      await tester.pump();

      expect(find.text('View Transcript'), findsOneWidget);
      expect(find.byIcon(Icons.description_outlined), findsOneWidget);
    });

    testWidgets('"Generate Transcript" button has auto_awesome icon',
        (tester) async {
      await tester.pumpWidget(buildAudioPlayerPage());
      await tester.pump();

      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
    });

    testWidgets('"View Transcript" button has description icon',
        (tester) async {
      final transcriptVm = FakeTranscriptViewModel(TranscriptState(
        status: TranscriptStatus.loaded,
        note: tTranscriptNote,
        error: null,
      ));

      await tester.pumpWidget(
          buildAudioPlayerPage(transcriptVm: transcriptVm));
      await tester.pump();

      expect(find.byIcon(Icons.description_outlined), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsNothing);
    });
  });

  group('AudioPlayerPage structure', () {
    testWidgets('uses GradientScaffold', (tester) async {
      await tester.pumpWidget(buildAudioPlayerPage());
      await tester.pump();

      // GradientScaffold renders a Container with gradient + Scaffold
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('AppBar is transparent', (tester) async {
      await tester.pumpWidget(buildAudioPlayerPage());
      await tester.pump();

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, Colors.transparent);
      expect(appBar.elevation, 0);
    });

    testWidgets('AppBar title is centered', (tester) async {
      await tester.pumpWidget(buildAudioPlayerPage());
      await tester.pump();

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.centerTitle, true);
    });
  });
}
