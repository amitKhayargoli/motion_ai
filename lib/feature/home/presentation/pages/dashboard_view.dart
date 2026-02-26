import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:motion_ai/core/providers/providers.dart';
import 'package:motion_ai/core/utils/snackbar_utils.dart';
import 'package:motion_ai/feature/audio_file/data/models/audio_file_hive_model.dart';
import 'package:motion_ai/feature/audio_file/presentation/view_model/audio_view_model.dart';
import 'package:motion_ai/feature/home/presentation/pages/home_view.dart';
import 'package:motion_ai/feature/home/presentation/pages/meetings_view.dart';
import 'package:motion_ai/feature/home/presentation/pages/mindspace_view.dart';
import 'package:motion_ai/feature/home/presentation/pages/notes_view.dart';
import 'package:motion_ai/feature/home/presentation/pages/widgets/bottom_nav_widget.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

class DashboardView extends ConsumerStatefulWidget {
  const DashboardView({super.key});

  @override
  ConsumerState<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends ConsumerState<DashboardView> {
  // --- Recording Logic Variables ---
  final recorder = FlutterSoundRecorder();
  bool isRecording = false;
  bool isRecorderReady = false;
  int _selectedIndex = 0;

  // Timer Logic
  Timer? _stopwatchTimer;
  int _secondsElapsed = 0;

  @override
  void initState() {
    super.initState();
    _initRecorder();
  }

  @override
  void dispose() {
    recorder.closeRecorder();
    _stopwatchTimer?.cancel();
    super.dispose();
  }

  // --- Core Methods ---

  Future<void> _initRecorder() async {
    try {
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        throw 'Microphone permission not granted';
      }
      await recorder.openRecorder();
      setState(() => isRecorderReady = true); // Set ready after opening
    } catch (e) {
      debugPrint("Error initializing recorder: $e");
      SnackbarUtils.showError(context, 'Failed to initialize recorder: $e');
    }
  }

  void _startTimer() {
    _secondsElapsed = 0;
    _stopwatchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _secondsElapsed++);
    });
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds / 60).floor().toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return "$minutes:$secs";
  }

  Future<void> _handleStartRecording() async {
    if (!isRecorderReady) {
      SnackbarUtils.showError(context, 'Recorder not ready. Please wait.');
      return;
    }

    try {
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/${const Uuid().v4()}.aac';
      await recorder.startRecorder(toFile: filePath, codec: Codec.aacADTS);

      _startTimer();
      setState(() => isRecording = true);
    } catch (e) {
      debugPrint("Error starting record: $e");
      SnackbarUtils.showError(context, 'Failed to start recording: $e');
    }
  }

  Future<void> _handleStopRecording() async {
    try {
      final path = await recorder.stopRecorder();
      _stopwatchTimer?.cancel();
      setState(() => isRecording = false);

      if (path != null) {
        // Trigger the upload logic via the ViewModel
        final viewModel = ref.read(audioViewModelProvider.notifier);
        await viewModel.uploadAudio(
          filePath: path,
          durationSeconds: _secondsElapsed,
        );

        SnackbarUtils.showSuccess(context, 'Recording saved and uploading...');
      }
    } catch (e) {
      debugPrint("Error stopping record: $e");
      SnackbarUtils.showError(context, 'Failed to stop recording: $e');
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  List<Widget> pages = [
    const HomeView(),
    const MeetingsView(),
    const MindspaceView(),
    const NotesListView(),
  ];

  @override
  Widget build(BuildContext context) {
    final double expandedWidth = MediaQuery.of(context).size.width - 40;

    return Scaffold(
      extendBody: true,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: (_selectedIndex == 0 || _selectedIndex == 3)
          ? AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.fastOutSlowIn,
              width: isRecording ? expandedWidth : 140,
              height: 72,
              decoration: BoxDecoration(
                color: isRecording
                    ? const Color(0xFFE8EBF9)
                    : const Color(0xFF3F5F00),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: isRecording ? _buildRecordingUI() : _buildIdleUI(),
                ),
              ),
            )
          : null,
      bottomNavigationBar: BottomNavWidget(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
      body: pages[_selectedIndex],
    );
  }

  Widget _buildIdleUI() {
    return InkWell(
      key: const ValueKey('idle'),
      onTap: isRecorderReady
          ? _handleStartRecording
          : null, // Disable if not ready
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.graphic_eq,
            color: isRecorderReady
                ? Colors.white
                : Colors.white54, // Visual feedback
            size: 24,
          ),
          const SizedBox(width: 8),
          Text(
            isRecorderReady ? "Record" : "Initializing...",
            style: TextStyle(
              color: isRecorderReady ? Colors.white : Colors.white54,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingUI() {
    return Row(
      key: const ValueKey('recording'),
      children: [
        const Icon(Icons.graphic_eq, color: Color(0xFF3F5F00), size: 28),
        const SizedBox(width: 12),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _formatDuration(_secondsElapsed),
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              "Recording",
              style: TextStyle(
                color: Colors.black54,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const Spacer(),
        CircleAvatar(
          backgroundColor: Colors.black12,
          radius: 20,
          child: IconButton(
            icon: const Icon(Icons.mic, color: Colors.black87, size: 20),
            onPressed: () {}, // Implement mute logic if needed
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: _handleStopRecording,
          child: Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFF3F5F00),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.stop, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }
}
