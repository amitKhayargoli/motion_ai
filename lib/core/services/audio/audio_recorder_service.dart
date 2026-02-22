import 'dart:async';

class AudioRecorderService {
  String? _filePath;
  Timer? _timer;

  Future<String> startRecording({
    required void Function(int seconds) onTick,
  }) async {
    int seconds = 0;
    _filePath = '/tmp/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      seconds++;
      onTick(seconds);
    });

    return _filePath!;
  }

  Future<int> stopRecording() async {
    _timer?.cancel();
    return 0; // duration handled externally
  }

  void cancel() {
    _timer?.cancel();
  }
}
