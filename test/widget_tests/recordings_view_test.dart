import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motion_ai/core/sync/audio_auto_sync.dart';
import 'package:motion_ai/feature/audio_file/domain/entities/audio_file_entity.dart';
import 'package:motion_ai/feature/audio_file/presentation/pages/recordings_view.dart';
import 'package:motion_ai/feature/audio_file/presentation/state/audio_state.dart';
import 'package:motion_ai/feature/audio_file/presentation/view_model/audio_view_model.dart';

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

  bool deleteAudioCalled = false;
  String? lastDeletedId;
  @override
  Future<void> deleteAudio(String audioId) async {
    deleteAudioCalled = true;
    lastDeletedId = audioId;
    final updated = (state.audios ?? []).where((a) => a.id != audioId).toList();
    state = state.copyWith(audios: updated);
  }

  List<String>? lastBulkDeletedIds;
  @override
  Future<void> deleteMultipleAudios(List<String> audioIds) async {
    lastBulkDeletedIds = audioIds;
    final updated =
        (state.audios ?? []).where((a) => !audioIds.contains(a.id)).toList();
    state = state.copyWith(audios: updated);
  }

  bool updateAudioCalled = false;
  @override
  Future<void> updateAudio({required String audioId, String? title}) async {
    updateAudioCalled = true;
  }
}

class FakeAudioAutoSyncNotifier extends AudioAutoSyncNotifier {
  final AudioSyncState _initialState;
  FakeAudioAutoSyncNotifier([AudioSyncState? initial])
      : _initialState = initial ?? AudioSyncState.idle;
  @override
  AudioSyncState build() => _initialState;
  @override
  Future<void> trySync() async {}
}

// ---- Test data ----

final tAudio1 = AudioFileEntity(
  id: 'audio-1',
  title: 'Morning Standup',
  fileName: 'standup.aac',
  localPath: '/tmp/standup.aac',
  durationSeconds: 125,
  uploadedAt: DateTime(2025, 3, 15, 9, 30),
  uploaderId: 'user-1',
  username: 'testuser',
  syncStatus: 0,
);

final tAudio2 = AudioFileEntity(
  id: 'audio-2',
  title: 'Design Review',
  fileName: 'design.aac',
  localPath: '/tmp/design.aac',
  durationSeconds: 3600,
  uploadedAt: DateTime(2025, 3, 14, 14, 0),
  uploaderId: 'user-1',
  username: 'testuser',
  syncStatus: 0,
);

final tAudio3 = AudioFileEntity(
  id: 'audio-3',
  title: 'Quick Note',
  fileName: 'note.aac',
  localPath: '/tmp/note.aac',
  durationSeconds: 30,
  uploadedAt: DateTime(2025, 3, 13, 18, 45),
  uploaderId: 'user-1',
  username: 'testuser',
  syncStatus: 1, // pendingUpload
);

AudioState loadedWithAudios([List<AudioFileEntity>? audios]) => AudioState(
      status: AudioStatus.success,
      audios: audios ?? [tAudio1, tAudio2, tAudio3],
    );

// ---- Helpers ----

void main() {
  Widget buildRecordingsView({
    FakeAudioViewModel? audioVm,
    FakeAudioAutoSyncNotifier? syncNotifier,
  }) {
    return ProviderScope(
      overrides: [
        audioViewModelProvider
            .overrideWith(() => audioVm ?? FakeAudioViewModel()),
        audioAutoSyncProvider
            .overrideWith(() => syncNotifier ?? FakeAudioAutoSyncNotifier()),
      ],
      child: const MaterialApp(home: RecordingsView()),
    );
  }

  group('RecordingsView rendering', () {
    testWidgets('displays RECORDINGS header', (tester) async {
      await tester.pumpWidget(buildRecordingsView());
      expect(find.text('RECORDINGS'), findsOneWidget);
    });

    testWidgets('displays recording titles', (tester) async {
      final audioVm = FakeAudioViewModel(loadedWithAudios());
      await tester.pumpWidget(buildRecordingsView(audioVm: audioVm));

      expect(find.text('Morning Standup'), findsOneWidget);
      expect(find.text('Design Review'), findsOneWidget);
      expect(find.text('Quick Note'), findsOneWidget);
    });

    testWidgets('displays formatted durations', (tester) async {
      final audioVm = FakeAudioViewModel(loadedWithAudios());
      await tester.pumpWidget(buildRecordingsView(audioVm: audioVm));

      // 125 seconds = 02:05
      expect(find.text('02:05'), findsOneWidget);
      // 3600 seconds = 60:00
      expect(find.text('60:00'), findsOneWidget);
      // 30 seconds = 00:30
      expect(find.text('00:30'), findsOneWidget);
    });

    testWidgets('displays formatted dates', (tester) async {
      final audioVm = FakeAudioViewModel(loadedWithAudios());
      await tester.pumpWidget(buildRecordingsView(audioVm: audioVm));

      expect(find.textContaining('Mar 15'), findsOneWidget);
      expect(find.textContaining('Mar 14'), findsOneWidget);
      expect(find.textContaining('Mar 13'), findsOneWidget);
    });

    testWidgets('displays graphic_eq icons for each recording', (tester) async {
      final audioVm = FakeAudioViewModel(loadedWithAudios());
      await tester.pumpWidget(buildRecordingsView(audioVm: audioVm));

      expect(find.byIcon(Icons.graphic_eq), findsNWidgets(3));
    });

    testWidgets('displays edit and chevron icons for each recording',
        (tester) async {
      final audioVm = FakeAudioViewModel(loadedWithAudios());
      await tester.pumpWidget(buildRecordingsView(audioVm: audioVm));

      expect(find.byIcon(Icons.edit_outlined), findsNWidgets(3));
      expect(find.byIcon(Icons.chevron_right), findsNWidgets(3));
    });
  });

  group('RecordingsView empty state', () {
    testWidgets('shows "No recordings yet" when audios is null',
        (tester) async {
      await tester.pumpWidget(buildRecordingsView());
      expect(find.text('No recordings yet'), findsOneWidget);
    });

    testWidgets('shows mic_none icon when empty', (tester) async {
      await tester.pumpWidget(buildRecordingsView());
      expect(find.byIcon(Icons.mic_none), findsOneWidget);
    });

    testWidgets('shows tap hint text when empty', (tester) async {
      await tester.pumpWidget(buildRecordingsView());
      expect(
          find.text('Tap the mic button to start recording'), findsOneWidget);
    });

    testWidgets('shows "No recordings yet" when audios list is empty',
        (tester) async {
      final audioVm = FakeAudioViewModel(
          const AudioState(status: AudioStatus.success, audios: []));
      await tester.pumpWidget(buildRecordingsView(audioVm: audioVm));
      expect(find.text('No recordings yet'), findsOneWidget);
    });
  });

  group('RecordingsView loading state', () {
    testWidgets('shows CircularProgressIndicator when loading with no audios',
        (tester) async {
      final audioVm = FakeAudioViewModel(
          const AudioState(status: AudioStatus.loading, audios: null));
      await tester.pumpWidget(buildRecordingsView(audioVm: audioVm));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('RecordingsView sync status', () {
    testWidgets('shows Syncing pill when sync is in progress', (tester) async {
      final audioVm = FakeAudioViewModel(loadedWithAudios());
      final syncNotifier = FakeAudioAutoSyncNotifier(
        const AudioSyncState(isSyncing: true),
      );

      await tester.pumpWidget(
          buildRecordingsView(audioVm: audioVm, syncNotifier: syncNotifier));

      expect(find.text('Syncing'), findsOneWidget);
    });

    testWidgets('shows Synced pill after successful sync', (tester) async {
      final audioVm = FakeAudioViewModel(loadedWithAudios());
      final syncNotifier = FakeAudioAutoSyncNotifier(
        AudioSyncState(isSyncing: false, lastSuccessAt: DateTime.now()),
      );

      await tester.pumpWidget(
          buildRecordingsView(audioVm: audioVm, syncNotifier: syncNotifier));

      expect(find.text('Synced'), findsOneWidget);
    });

    testWidgets('shows no sync pill in idle state', (tester) async {
      final audioVm = FakeAudioViewModel(loadedWithAudios());
      await tester.pumpWidget(buildRecordingsView(audioVm: audioVm));

      expect(find.text('Syncing'), findsNothing);
      expect(find.text('Synced'), findsNothing);
    });
  });

  group('RecordingsView multi-select mode', () {
    testWidgets('long press enters multi-select mode', (tester) async {
      final audioVm = FakeAudioViewModel(loadedWithAudios());
      await tester.pumpWidget(buildRecordingsView(audioVm: audioVm));

      await tester.longPress(find.text('Morning Standup'));
      await tester.pumpAndSettle();

      expect(find.text('1 selected'), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('tapping another recording in multi-select adds to selection',
        (tester) async {
      final audioVm = FakeAudioViewModel(loadedWithAudios());
      await tester.pumpWidget(buildRecordingsView(audioVm: audioVm));

      await tester.longPress(find.text('Morning Standup'));
      await tester.pumpAndSettle();
      expect(find.text('1 selected'), findsOneWidget);

      await tester.tap(find.text('Design Review'));
      await tester.pumpAndSettle();
      expect(find.text('2 selected'), findsOneWidget);
    });

    testWidgets('close button exits multi-select mode', (tester) async {
      final audioVm = FakeAudioViewModel(loadedWithAudios());
      await tester.pumpWidget(buildRecordingsView(audioVm: audioVm));

      await tester.longPress(find.text('Morning Standup'));
      await tester.pumpAndSettle();
      expect(find.text('1 selected'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('1 selected'), findsNothing);
    });

    testWidgets('multi-select hides edit and chevron icons', (tester) async {
      final audioVm = FakeAudioViewModel(loadedWithAudios());
      await tester.pumpWidget(buildRecordingsView(audioVm: audioVm));

      // Before multi-select: edit icons visible
      expect(find.byIcon(Icons.edit_outlined), findsNWidgets(3));

      await tester.longPress(find.text('Morning Standup'));
      await tester.pumpAndSettle();

      // In multi-select: edit icons hidden, checkboxes shown
      expect(find.byIcon(Icons.edit_outlined), findsNothing);
      expect(find.byIcon(Icons.chevron_right), findsNothing);
      expect(find.byType(Checkbox), findsNWidgets(3));
    });

    testWidgets('deselecting last item exits multi-select mode',
        (tester) async {
      final audioVm = FakeAudioViewModel(loadedWithAudios());
      await tester.pumpWidget(buildRecordingsView(audioVm: audioVm));

      // Enter multi-select
      await tester.longPress(find.text('Morning Standup'));
      await tester.pumpAndSettle();
      expect(find.text('1 selected'), findsOneWidget);

      // Tap again to deselect
      await tester.tap(find.text('Morning Standup'));
      await tester.pumpAndSettle();

      // Multi-select should exit when no items selected
      expect(find.text('0 selected'), findsNothing);
      expect(find.byType(Checkbox), findsNothing);
    });
  });

  group('RecordingsView rename dialog', () {
    testWidgets('tapping edit icon shows rename dialog', (tester) async {
      final audioVm = FakeAudioViewModel(loadedWithAudios());
      await tester.pumpWidget(buildRecordingsView(audioVm: audioVm));

      // Tap the first edit icon
      await tester.tap(find.byIcon(Icons.edit_outlined).first);
      await tester.pumpAndSettle();

      expect(find.text('Rename Recording'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('rename dialog shows current name', (tester) async {
      final audioVm = FakeAudioViewModel(loadedWithAudios([tAudio1]));
      await tester.pumpWidget(buildRecordingsView(audioVm: audioVm));

      await tester.tap(find.byIcon(Icons.edit_outlined).first);
      await tester.pumpAndSettle();

      // TextField should have the current display name
      expect(find.text('Morning Standup'), findsAtLeast(1));
    });

    testWidgets('cancel button closes rename dialog', (tester) async {
      final audioVm = FakeAudioViewModel(loadedWithAudios());
      await tester.pumpWidget(buildRecordingsView(audioVm: audioVm));

      await tester.tap(find.byIcon(Icons.edit_outlined).first);
      await tester.pumpAndSettle();
      expect(find.text('Rename Recording'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Rename Recording'), findsNothing);
    });
  });

  group('RecordingsView delete dialog', () {
    testWidgets('bulk delete shows confirmation dialog', (tester) async {
      final audioVm = FakeAudioViewModel(loadedWithAudios());
      await tester.pumpWidget(buildRecordingsView(audioVm: audioVm));

      // Enter multi-select and select items
      await tester.longPress(find.text('Morning Standup'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Design Review'));
      await tester.pumpAndSettle();
      expect(find.text('2 selected'), findsOneWidget);

      // Tap delete
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.text('Delete Selected?'), findsOneWidget);
      expect(find.text('Delete 2 recording(s)?'), findsOneWidget);
      expect(find.text('Delete All'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('cancel closes bulk delete dialog', (tester) async {
      final audioVm = FakeAudioViewModel(loadedWithAudios());
      await tester.pumpWidget(buildRecordingsView(audioVm: audioVm));

      await tester.longPress(find.text('Morning Standup'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      expect(find.text('Delete Selected?'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Delete Selected?'), findsNothing);
    });
  });

  group('RecordingsView structure', () {
    testWidgets('uses GradientScaffold', (tester) async {
      await tester.pumpWidget(buildRecordingsView());
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('recordings are in a ListView when loaded', (tester) async {
      final audioVm = FakeAudioViewModel(loadedWithAudios());
      await tester.pumpWidget(buildRecordingsView(audioVm: audioVm));

      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('each recording card uses AnimatedContainer', (tester) async {
      final audioVm = FakeAudioViewModel(loadedWithAudios());
      await tester.pumpWidget(buildRecordingsView(audioVm: audioVm));

      expect(find.byType(AnimatedContainer), findsNWidgets(3));
    });
  });
}
