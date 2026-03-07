import 'dart:async';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:motion_ai/core/services/sensor/lift_detection_service.dart';
import 'package:motion_ai/feature/audio_file/presentation/providers/lift_to_stop_provider.dart';
import 'package:motion_ai/feature/audio_file/presentation/providers/recording_providers.dart';
import 'package:motion_ai/feature/audio_file/presentation/view_model/audio_view_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

class VoiceRecorderPage extends ConsumerStatefulWidget {
  const VoiceRecorderPage({super.key});

  @override
  ConsumerState<VoiceRecorderPage> createState() => _VoiceRecorderPageState();
}

class _VoiceRecorderPageState extends ConsumerState<VoiceRecorderPage>
    with SingleTickerProviderStateMixin {
  late final RecorderController _recorderController;
  late final LiftDetectionService _liftService;
  bool _isRecording = false;
  bool _hasRecorded = false;
  bool _liftToStopActive = false;
  int _secondsElapsed = 0;
  Timer? _timer;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _liftService = ref.read(liftDetectionServiceProvider);
    _recorderController = RecorderController()
      ..androidEncoder = AndroidEncoder.aac
      ..androidOutputFormat = AndroidOutputFormat.aac_adts
      ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
      ..sampleRate = 44100;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _liftService.stopMonitoring();
    _recorderController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  String _formatDuration(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _startRecording() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission required')),
        );
      }
      return;
    }

    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/${const Uuid().v4()}.aac';

    await _recorderController.record(path: filePath);

    _secondsElapsed = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _secondsElapsed++);
    });

    _pulseController.repeat(reverse: true);

    setState(() {
      _isRecording = true;
      _hasRecorded = false;
    });
    ref.read(recordingStateProvider.notifier).state = RecordingState.recording;

    // Start lift detection after 3s so the user can place the phone down
    final liftEnabled = ref.read(liftToStopEnabledProvider);
    if (liftEnabled) {
      Future.delayed(const Duration(seconds: 3), () {
        if (!mounted || !_isRecording) return;
        _liftService.startMonitoring(
          onLiftDetected: () {
            if (mounted && _isRecording) {
              _stopRecording();
            }
          },
        );
        if (mounted) setState(() => _liftToStopActive = true);
      });
    }
  }

  Future<void> _stopRecording() async {
    _liftService.stopMonitoring();

    final path = await _recorderController.stop();
    _timer?.cancel();
    _pulseController.stop();
    _pulseController.reset();

    setState(() {
      _isRecording = false;
      _hasRecorded = true;
      _liftToStopActive = false;
    });
    ref.read(recordingStateProvider.notifier).state = RecordingState.idle;

    if (path != null && mounted) {
      _showNamingDialog(path);
    }
  }

  void _showNamingDialog(String filePath) {
    final defaultName =
        'Recording ${DateFormat('MMM d, h:mm a').format(DateTime.now())}';
    final controller = TextEditingController(text: defaultName);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A2900),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Name Your Recording',
          style: TextStyle(color: Colors.white, fontFamily: 'sf_pro'),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontFamily: 'sf_pro'),
          decoration: InputDecoration(
            hintText: 'Enter recording name',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: Colors.white.withOpacity(0.08),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFFAEFB2A), width: 1.5),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
            },
            child: const Text(
              'Discard',
              style: TextStyle(color: Colors.white54, fontFamily: 'sf_pro'),
            ),
          ),
          FilledButton(
            onPressed: () {
              final title = controller.text.trim().isEmpty
                  ? defaultName
                  : controller.text.trim();
              Navigator.pop(ctx);
              _saveRecording(filePath, title);
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFAEFB2A),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Save',
              style:
                  TextStyle(fontFamily: 'sf_pro', fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveRecording(String filePath, String fileName) async {
    final viewModel = ref.read(audioViewModelProvider.notifier);
    await viewModel.saveRecording(
      filePath: filePath,
      durationSeconds: _secondsElapsed,
      fileName: fileName,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recording saved'),
          backgroundColor: Color(0xFF3F5F00),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Voice Recorder',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'sf_pro',
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          Consumer(
            builder: (context, ref, _) {
              final enabled = ref.watch(liftToStopEnabledProvider);
              return IconButton(
                icon: Icon(
                  enabled ? Icons.phone_android : Icons.phone_android_outlined,
                  color: enabled ? const Color(0xFFAEFB2A) : Colors.white38,
                ),
                tooltip: 'Lift to stop',
                onPressed: () => ref
                    .read(liftToStopEnabledProvider.notifier)
                    .state = !enabled,
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),

            // Timer display
            Text(
              _formatDuration(_secondsElapsed),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 56,
                fontWeight: FontWeight.w300,
                fontFamily: 'sf_pro',
                letterSpacing: 4,
              ),
            ),

            const SizedBox(height: 8),
            Text(
              _isRecording
                  ? 'Recording...'
                  : (_hasRecorded ? 'Recorded' : 'Tap to record'),
              style: TextStyle(
                color: _isRecording ? const Color(0xFFAEFB2A) : Colors.white54,
                fontSize: 16,
                fontFamily: 'sf_pro',
              ),
            ),

            if (_isRecording && _liftToStopActive)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.phone_android, size: 14, color: Colors.white38),
                    SizedBox(width: 4),
                    Text(
                      'Lift phone to stop',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                        fontFamily: 'sf_pro',
                      ),
                    ),
                  ],
                ),
              ),

            const Spacer(),

            // Waveform display
            if (_isRecording)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                height: 100,
                child: AudioWaveforms(
                  recorderController: _recorderController,
                  size: Size(MediaQuery.of(context).size.width - 48, 100),
                  waveStyle: const WaveStyle(
                    waveColor: Color(0xFFAEFB2A),
                    extendWaveform: true,
                    showMiddleLine: false,
                    spacing: 6.0,
                    waveThickness: 3.0,
                    showDurationLabel: false,
                  ),
                ),
              )
            else
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                height: 100,
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    30,
                    (i) => Container(
                      width: 3,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),

            const Spacer(),

            // Record / Stop button
            ScaleTransition(
              scale: _isRecording
                  ? _pulseAnimation
                  : const AlwaysStoppedAnimation(1.0),
              child: GestureDetector(
                onTap: _isRecording ? _stopRecording : _startRecording,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isRecording
                        ? const Color(0xFFFF3B30)
                        : const Color(0xFFAEFB2A),
                    boxShadow: [
                      BoxShadow(
                        color: (_isRecording
                                ? const Color(0xFFFF3B30)
                                : const Color(0xFFAEFB2A))
                            .withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(
                    _isRecording ? Icons.stop_rounded : Icons.mic,
                    color: _isRecording ? Colors.white : Colors.black,
                    size: 36,
                  ),
                ),
              ),
            ),

            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}
