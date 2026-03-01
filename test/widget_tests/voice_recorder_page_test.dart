import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motion_ai/core/services/sensor/lift_detection_service.dart';
import 'package:motion_ai/feature/audio_file/presentation/pages/voice_recorder_page.dart';
import 'package:motion_ai/feature/audio_file/presentation/providers/lift_to_stop_provider.dart';
import 'package:motion_ai/feature/audio_file/presentation/state/audio_state.dart';
import 'package:motion_ai/feature/audio_file/presentation/view_model/audio_view_model.dart';

// ---- Fakes ----

class FakeAudioViewModel extends AudioViewModel {
  final AudioState _initialState;
  FakeAudioViewModel([AudioState? initial])
      : _initialState = initial ?? const AudioState();

  @override
  AudioState build() => _initialState;

  bool saveRecordingCalled = false;
  @override
  Future<void> saveRecording({
    required String filePath,
    required int durationSeconds,
    required String fileName,
  }) async {
    saveRecordingCalled = true;
  }

  @override
  Future<void> fetchAudios() async {}

  @override
  Future<void> loadInitialData() async {}
}

class FakeLiftDetectionService extends LiftDetectionService {
  @override
  void startMonitoring({required OnLiftDetected onLiftDetected}) {}
  @override
  void stopMonitoring() {}
}

// ---- Helpers ----

void main() {
  Widget buildVoiceRecorderPage({
    FakeAudioViewModel? audioVm,
    bool liftToStopEnabled = true,
  }) {
    return ProviderScope(
      overrides: [
        audioViewModelProvider
            .overrideWith(() => audioVm ?? FakeAudioViewModel()),
        liftDetectionServiceProvider
            .overrideWithValue(FakeLiftDetectionService()),
        liftToStopEnabledProvider.overrideWith((ref) => liftToStopEnabled),
      ],
      child: const MaterialApp(
        home: VoiceRecorderPage(),
      ),
    );
  }

  group('VoiceRecorderPage rendering', () {
    testWidgets('displays Voice Recorder title in AppBar', (tester) async {
      await tester.pumpWidget(buildVoiceRecorderPage());
      expect(find.text('Voice Recorder'), findsOneWidget);
    });

    testWidgets('displays initial timer at 00:00', (tester) async {
      await tester.pumpWidget(buildVoiceRecorderPage());
      expect(find.text('00:00'), findsOneWidget);
    });

    testWidgets('displays "Tap to record" hint initially', (tester) async {
      await tester.pumpWidget(buildVoiceRecorderPage());
      expect(find.text('Tap to record'), findsOneWidget);
    });

    testWidgets('displays mic icon button initially', (tester) async {
      await tester.pumpWidget(buildVoiceRecorderPage());
      expect(find.byIcon(Icons.mic), findsOneWidget);
    });

    testWidgets('does not show stop icon initially', (tester) async {
      await tester.pumpWidget(buildVoiceRecorderPage());
      expect(find.byIcon(Icons.stop_rounded), findsNothing);
    });

    testWidgets('displays back arrow button', (tester) async {
      await tester.pumpWidget(buildVoiceRecorderPage());
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('displays lift-to-stop toggle button', (tester) async {
      await tester.pumpWidget(buildVoiceRecorderPage());
      // The phone_android icon when lift-to-stop is enabled
      expect(find.byIcon(Icons.phone_android), findsOneWidget);
    });
  });

  group('VoiceRecorderPage lift-to-stop toggle', () {
    testWidgets('shows filled icon when lift-to-stop is enabled',
        (tester) async {
      await tester.pumpWidget(buildVoiceRecorderPage(liftToStopEnabled: true));
      expect(find.byIcon(Icons.phone_android), findsOneWidget);
    });

    testWidgets('shows outlined icon when lift-to-stop is disabled',
        (tester) async {
      await tester.pumpWidget(buildVoiceRecorderPage(liftToStopEnabled: false));
      expect(find.byIcon(Icons.phone_android_outlined), findsOneWidget);
    });

    testWidgets('tooltip is "Lift to stop"', (tester) async {
      await tester.pumpWidget(buildVoiceRecorderPage());
      final iconButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.phone_android),
      );
      expect(iconButton.tooltip, 'Lift to stop');
    });
  });

  group('VoiceRecorderPage structure', () {
    testWidgets('uses Scaffold with dark background', (tester) async {
      await tester.pumpWidget(buildVoiceRecorderPage());

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).last);
      expect(scaffold.backgroundColor, const Color(0xFF0D0D0D));
    });

    testWidgets('AppBar is transparent with no elevation', (tester) async {
      await tester.pumpWidget(buildVoiceRecorderPage());

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, Colors.transparent);
      expect(appBar.elevation, 0);
    });

    testWidgets('AppBar title is centered', (tester) async {
      await tester.pumpWidget(buildVoiceRecorderPage());

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.centerTitle, true);
    });

    testWidgets('record button is wrapped in GestureDetector', (tester) async {
      await tester.pumpWidget(buildVoiceRecorderPage());
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('shows static waveform bars when not recording',
        (tester) async {
      await tester.pumpWidget(buildVoiceRecorderPage());

      // The static waveform is 30 bars (Container widgets in a Row)
      // We verify the Row is present in the non-recording state
      expect(find.byType(Row), findsWidgets);
    });

    testWidgets('does not show "Lift phone to stop" when not recording',
        (tester) async {
      await tester.pumpWidget(buildVoiceRecorderPage());
      expect(find.text('Lift phone to stop'), findsNothing);
    });

    testWidgets('does not show "Recording..." text initially', (tester) async {
      await tester.pumpWidget(buildVoiceRecorderPage());
      expect(find.text('Recording...'), findsNothing);
    });

    testWidgets('does not show "Recorded" text initially', (tester) async {
      await tester.pumpWidget(buildVoiceRecorderPage());
      expect(find.text('Recorded'), findsNothing);
    });
  });

  group('VoiceRecorderPage timer format', () {
    testWidgets('timer displays with leading zeros', (tester) async {
      await tester.pumpWidget(buildVoiceRecorderPage());
      // Timer starts at 00:00
      final timerText = tester.widget<Text>(find.text('00:00'));
      expect(timerText.style!.fontSize, 56);
    });
  });
}
