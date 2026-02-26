import 'package:flutter_riverpod/legacy.dart';

enum RecordingState { idle, recording, uploading, error }

final recordingStateProvider = StateProvider<RecordingState>(
  (_) => RecordingState.idle,
);

final recordingSecondsProvider = StateProvider<int>((_) => 0);

final uploadProgressProvider = StateProvider<double>((_) => 0.0);
