import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:just_audio/just_audio.dart';
import 'package:motion_ai/core/utils/snackbar_utils.dart';
import 'package:motion_ai/feature/audio_file/data/datasources/audio_file_datasource.dart';
import 'package:motion_ai/feature/audio_file/data/models/audio_file_hive_model.dart';
import 'package:motion_ai/feature/audio_file/presentation/state/audio_state.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import 'package:motion_ai/core/providers/providers.dart';
import 'package:motion_ai/feature/audio_file/presentation/view_model/audio_view_model.dart';

enum UploadStatus { pending, uploading, success, failed }

class AudioFileWithStatus {
  AudioFileHiveModel audio;
  UploadStatus status;
  double progress;
  AudioFileWithStatus({
    required this.audio,
    this.status = UploadStatus.pending,
    this.progress = 0.0,
  });
}

class AudioManagerWidget extends ConsumerStatefulWidget {
  const AudioManagerWidget({super.key});

  @override
  ConsumerState<AudioManagerWidget> createState() => _AudioManagerWidgetState();
}

class _AudioManagerWidgetState extends ConsumerState<AudioManagerWidget> {
  final recorder = FlutterSoundRecorder();
  final player = FlutterSoundPlayer();
  bool isRecording = false;
  String? recordedFilePath;
  List<AudioFileWithStatus> audioQueue = [];

  // Optional: Watch the view model's state for global status
  late final AudioState audioState = ref.watch(audioViewModelProvider);

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await initRecorder();
      await player.openPlayer();
      await _loadAudioFilesFromHive();
    } catch (e, stackTrace) {
      if (mounted) {
        setState(() {
          // errorMessage = 'Initialization failed: $e';
          // isLoading = false;
        });
      }
    }
  }

  Future<void> initRecorder() async {
    try {
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        throw Exception('Microphone permission not granted');
      }
      await recorder.openRecorder();
    } catch (e, stackTrace) {
      rethrow;
    }
  }

  Future<void> _loadAudioFilesFromHive() async {
    final viewModel = ref.read(audioViewModelProvider.notifier);
    await viewModel.fetchAudios();

    // Populate audioQueue from the view model's state
    final audioState = ref.read(audioViewModelProvider);
    if (audioState.audios != null) {
      audioQueue = audioState.audios!.map((entity) {
        // Assuming AudioFileEntity has toHiveModel()
        final hiveModel = entity.toHiveModel();
        final needsUpload = hiveModel.localPath == hiveModel.cloudUrl;
        return AudioFileWithStatus(
          audio: hiveModel,
          status: needsUpload ? UploadStatus.pending : UploadStatus.success,
        );
      }).toList();
    }

    // Set loading to false after populating
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    recorder.closeRecorder();
    player.closePlayer();
    super.dispose();
  }

  Future<void> startRecording() async {
    try {
      if (!recorder.isRecording) {
        final directory = await Directory.systemTemp.createTemp();
        final filePath = '${directory.path}/${const Uuid().v4()}.aac';
        await recorder.startRecorder(toFile: filePath, codec: Codec.aacADTS);
        if (mounted) {
          setState(() {
            isRecording = true;
            recordedFilePath = filePath;
            // errorMessage = null;
          });
        }
      }
    } catch (e, stackTrace) {
      if (mounted) {
        setState(() => {});
        SnackbarUtils.showError(context, 'Failed to start recording: $e');
      }
    }
  }

  Future<void> stopRecording() async {
    try {
      final tempPath = await recorder.stopRecorder();
      setState(() => isRecording = false);

      if (tempPath == null) throw Exception('Recording path is null');

      final persistentPath = await _moveFileToPersistent(tempPath);
      final duration = await getAudioDuration(persistentPath);
      final audio = await _createAndSaveAudioModel(persistentPath, duration);

      if (mounted) {
        audioQueue.insert(0, AudioFileWithStatus(audio: audio));
        setState(() {});

        // Use your success utility here
        SnackbarUtils.showSuccess(context, 'Audio saved! Uploading...');
      }

      // Process the queue for uploading
      unawaited(_processQueue());
    } catch (e) {
      if (mounted) {
        // Use your error utility here
        // Providing specific feedback for that Timeout error
        String errorMsg = e.toString().contains('connectionTimeout')
            ? 'Upload timed out. Check server connection.'
            : 'Failed to save recording: $e';

        SnackbarUtils.showError(context, errorMsg);
      }
    }
  }

  Future<String> _moveFileToPersistent(String tempPath) async {
    final tempFile = File(tempPath);
    if (!await tempFile.exists()) throw Exception('Recording file missing');
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = tempPath.split('/').last;
    final persistentPath = '${appDir.path}/$fileName';
    await tempFile.rename(persistentPath);
    return persistentPath;
  }

  Future<AudioFileHiveModel> _createAndSaveAudioModel(
    String persistentPath,
    Duration duration,
  ) async {
    final userId =
        ref.read(userSessionServiceProvider).getUserId() ?? 'local_user';
    final localDatasource = ref.read(audioLocalDatasourceProvider);
    final fileName = persistentPath.split('/').last;
    final audio = AudioFileHiveModel(
      id: const Uuid().v4(),
      fileName: fileName,
      localPath: persistentPath,
      cloudUrl: persistentPath,
      durationSeconds: duration.inSeconds > 0 ? duration.inSeconds : 1,
      mimeType: 'audio/aac',
      uploadedAt: DateTime.now(),
      uploaderId: userId,
    );
    await localDatasource.saveAudio(audio);
    return audio;
  }

  Future<void> _processQueue() async {
    final remote = ref.read(audioRemoteProvider);
    final localDatasource = ref.read(audioLocalDatasourceProvider);

    for (var item in audioQueue) {
      if (item.status == UploadStatus.pending ||
          item.status == UploadStatus.failed) {
        if (mounted) setState(() => item.status = UploadStatus.uploading);
        await _handleUpload(item, localDatasource);
      }
    }
  }

  Future<void> _handleUpload(
    AudioFileWithStatus item,
    IAudioLocalDatasource localDatasource,
  ) async {
    try {
      final file = File(item.audio.localPath);
      if (!await file.exists())
        throw Exception('File not found at: ${item.audio.localPath}');

      // Use the view model instead of direct usecase call
      final viewModel = ref.read(audioViewModelProvider.notifier);
      await viewModel.uploadAudio(
        filePath: item.audio.localPath,
        durationSeconds: item.audio.durationSeconds,
      );

      // Watch the updated state after upload
      final audioState = ref.watch(audioViewModelProvider);

      // Retrieve the uploaded audio from the state
      final uploadedAudio = audioState.status == AudioStatus.success
          ? audioState
          : null;
      if (uploadedAudio == null) {
        throw Exception('Upload completed but no audio entity returned');
      }

      final updatedAudio = AudioFileHiveModel(
        id: item.audio.id,
        fileName: item.audio.fileName,
        localPath: item.audio.localPath,
        cloudUrl: item.audio.cloudUrl, // Use cloudUrl from entity
        durationSeconds: item.audio.durationSeconds,
        mimeType: item.audio.mimeType,
        uploadedAt: item.audio.uploadedAt,
        uploaderId: item.audio.uploaderId,
      );

      await localDatasource.saveAudio(updatedAudio);
      if (mounted)
        setState(() {
          item.audio = updatedAudio;
          item.status = UploadStatus.success;
        });
    } catch (e, stackTrace) {
      if (mounted) setState(() => item.status = UploadStatus.failed);
    }
  }

  Future<Duration> getAudioDuration(String filePath) async {
    final player = AudioPlayer();
    try {
      await player.setFilePath(filePath);
      final duration = player.duration;
      if (duration != null && duration.inSeconds > 0) return duration;

      final completer = Completer<Duration>();
      final sub = player.durationStream.listen((d) {
        if (d != null && !completer.isCompleted) completer.complete(d);
      });
      return await completer.future.timeout(
        const Duration(seconds: 2),
        onTimeout: () => Duration.zero,
      );
    } catch (e) {
      return Duration.zero;
    } finally {
      await player.dispose();
    }
  }

  Future<void> _playAudio(AudioFileHiveModel audio) async {
    try {
      await _stopCurrentPlayback();
      final playbackUrl = _getPlaybackUrl(audio);
      final isRemote = playbackUrl.startsWith('http');
      await player.startPlayer(
        fromURI: playbackUrl,
        codec: isRemote ? Codec.defaultCodec : Codec.aacADTS,
        whenFinished: () => mounted ? setState(() {}) : null,
      );
    } catch (e, stackTrace) {
      if (mounted) {
        SnackbarUtils.showError(context, "Failed to play audio: $e");
      }
    }
  }

  Future<void> _stopCurrentPlayback() async {
    if (player.isPlaying) {
      await player.stopPlayer();
      // await _playerSubscription?.cancel();
    }
  }

  String _getPlaybackUrl(AudioFileHiveModel audio) {
    return (audio.cloudUrl != audio.localPath && audio.cloudUrl.isNotEmpty)
        ? audio.cloudUrl
        : audio.localPath;
  }

  Future<void> _deleteAudio(int index) async {
    try {
      final item = audioQueue[index];
      final localDatasource = ref.read(audioLocalDatasourceProvider);
      await localDatasource.deleteAudio(item.audio.id);
      await _deleteLocalFile(item.audio.localPath);
      if (mounted) {
        setState(() => audioQueue.removeAt(index));
        SnackbarUtils.showSuccess(context, 'Audio deleted successfully');
      }
    } catch (e, stackTrace) {
      if (mounted) {
        SnackbarUtils.showError(context, 'Failed to delete audio: $e');
      }
    }
  }

  Future<void> _deleteLocalFile(String localPath) async {
    final localFile = File(localPath);
    if (await localFile.exists()) await localFile.delete();
  }

  // Optional: Use audioState in the build method for global loading/error UI
  @override
  Widget build(BuildContext context) {
    final audioState = ref.watch(audioViewModelProvider);

    // Use view model's status for loading/error
    if (audioState.status == AudioStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (audioState.status == AudioStatus.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: ${audioState.errorMessage}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadAudioFilesFromHive(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        ElevatedButton(
          onPressed: isRecording ? stopRecording : startRecording,
          child: Text(isRecording ? 'Stop Recording' : 'Start Recording'),
        ),
        const SizedBox(height: 12),
        if (audioQueue.isEmpty)
          const Expanded(child: Center(child: Text('No audio recordings yet')))
        else
          Expanded(
            child: ListView.builder(
              itemCount: audioQueue.length,
              itemBuilder: (context, index) {
                final item = audioQueue[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: ListTile(
                    title: Text(item.audio.fileName),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Duration: ${item.audio.durationSeconds}s'),
                        Text('Status: ${item.status.name}'),
                        if (item.status == UploadStatus.uploading)
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: LinearProgressIndicator(),
                          ),
                        if (item.status == UploadStatus.failed)
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text(
                              'Upload failed - tap to retry',
                              style: TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                    leading: IconButton(
                      icon: Icon(
                        player.isPlaying ? Icons.stop : Icons.play_arrow,
                      ),
                      onPressed: () => _playAudio(item.audio),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (item.status == UploadStatus.failed)
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: () => _processQueue(),
                          ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteAudio(index),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  void unawaited(Future<void> future) {
    // Helper function to explicitly mark futures as unawaited
  }
}
