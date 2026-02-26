import 'dart:io';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:motion_ai/feature/audio_file/domain/entities/audio_file_entity.dart';
import 'package:motion_ai/feature/audio_file/presentation/view_model/audio_view_model.dart';
import 'package:motion_ai/feature/home/presentation/pages/widgets/gradient_scaffold_widget.dart';
import 'package:motion_ai/feature/notes/presentation/pages/transcript_page.dart';
import 'package:motion_ai/feature/notes/presentation/state/transcript_state.dart';
import 'package:motion_ai/feature/notes/presentation/view_model/transcript_view_model.dart';
import 'package:motion_ai/feature/workspace/presentation/view_model/workspace_view_model.dart';

class AudioPlayerPage extends ConsumerStatefulWidget {
  const AudioPlayerPage({super.key, required this.audio});

  final AudioFileEntity audio;

  @override
  ConsumerState<AudioPlayerPage> createState() => _AudioPlayerPageState();
}

class _AudioPlayerPageState extends ConsumerState<AudioPlayerPage> {
  late final PlayerController _playerController;

  bool _isPlaying = false;
  bool _isPrepared = false;
  bool _hasError = false;

  // prevents the waveform drag from fighting the duration listener updates
  bool _isUserSeeking = false;

  // remember state so drag end can resume if needed
  bool _wasPlayingBeforeSeek = false;

  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  bool _isTranscribing = false;

  @override
  void initState() {
    super.initState();
    _playerController = PlayerController();

    // smoother progress updates
    _playerController.updateFrequency = UpdateFrequency.high;

    _preparePlayer();

    // Check if transcript already exists for this audio
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(transcriptViewModelProvider.notifier)
          .fetchTranscript(widget.audio.id);
    });
  }

  Future<void> _preparePlayer() async {
    final path = widget.audio.localPath;

    if (path.isEmpty) {
      if (mounted) setState(() => _hasError = true);
      return;
    }

    try {
      final file = File(path);
      if (!file.existsSync()) {
        if (mounted) setState(() => _hasError = true);
        return;
      }

      await _playerController.preparePlayer(
        path: path,
        shouldExtractWaveform: true,
        noOfSamples: 200,
        volume: 1.0,
      );

      // Read duration safely
      final maxMs = await _playerController.getDuration(DurationType.max);
      _totalDuration = Duration(milliseconds: maxMs < 0 ? 0 : maxMs);

      _playerController.onPlayerStateChanged.listen((s) {
        if (!mounted) return;
        setState(() => _isPlaying = s == PlayerState.playing);
      });

      _playerController.onCurrentDurationChanged.listen((ms) {
        if (!mounted) return;

        // While user is dragging, don't override UI position
        if (_isUserSeeking) return;

        setState(() => _currentPosition = Duration(milliseconds: ms));
      });

      _playerController.onCompletion.listen((_) async {
        if (!mounted) return;

        // snap to end (not 0) on completion
        setState(() {
          _isPlaying = false;
          _currentPosition = _totalDuration;
        });
      });

      if (mounted) setState(() => _isPrepared = true);
    } catch (e) {
      debugPrint('AudioPlayerPage error: $e');
      if (mounted) setState(() => _hasError = true);
    }
  }

  @override
  void dispose() {
    _playerController.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final totalSeconds = d.inSeconds;
    if (totalSeconds < 0) return "00:00";
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _togglePlayPause() async {
    if (!_isPrepared || _hasError) return;

    if (_isPlaying) {
      await _playerController.pausePlayer();
    } else {
      // IMPORTANT: forceRefresh=false prevents resetting to 0:00 on resume
      await _playerController.startPlayer(forceRefresh: false);
    }
  }

  static final _objectIdRegex = RegExp(r'^[a-fA-F0-9]{24}$');

  Future<void> _onGenerateTranscript() async {
    // The widget may hold a stale local UUID — look up the latest from state
    var audioId = widget.audio.id;
    final audios = ref.read(audioViewModelProvider).audios ?? [];

    // Try to find a synced version of this audio by matching localPath or title
    for (final a in audios) {
      if (a.localPath == widget.audio.localPath &&
          a.localPath.isNotEmpty &&
          _objectIdRegex.hasMatch(a.id)) {
        audioId = a.id;
        break;
      }
    }

    if (audioId.isEmpty || !_objectIdRegex.hasMatch(audioId)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Audio must be uploaded to the server before transcribing'),
        ),
      );
      return;
    }

    final workspaceState = ref.read(workspaceViewModelProvider);
    final workspaceId = workspaceState.selected?.id;

    if (workspaceId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No workspace selected')),
      );
      return;
    }

    setState(() => _isTranscribing = true);

    final success =
        await ref.read(transcriptViewModelProvider.notifier).transcribeAudio(
              audioFileId: audioId,
              workspaceId: workspaceId,
              noteTitle: widget.audio.displayName,
            );

    if (!mounted) return;
    setState(() => _isTranscribing = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transcript generated successfully')),
      );
    } else {
      final error = ref.read(transcriptViewModelProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Failed to generate transcript')),
      );
    }
  }

  void _onViewTranscript() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TranscriptPage(
          audioFileId: widget.audio.id,
          headerTitle: widget.audio.displayName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final audio = widget.audio;
    final transcriptState = ref.watch(transcriptViewModelProvider);
    final hasTranscript = transcriptState.status == TranscriptStatus.loaded &&
        transcriptState.note != null;

    return GradientScaffold(
      useDashboardGradient: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          audio.displayName,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'sf_pro',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),

            // Record icon
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFAEFB2A).withOpacity(0.10),
                border: Border.all(
                  color: const Color(0xFFAEFB2A).withOpacity(0.25),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.graphic_eq,
                color: Color(0xFFAEFB2A),
                size: 44,
              ),
            ),

            const SizedBox(height: 28),

            // File name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                audio.displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'sf_pro',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(height: 8),

            // Date
            if (audio.uploadedAt != null)
              Text(
                DateFormat('MMM d, yyyy · h:mm a').format(audio.uploadedAt!),
                style: const TextStyle(
                  color: Colors.white38,
                  fontFamily: 'sf_pro',
                  fontSize: 13,
                ),
              ),

            const Spacer(),

            // Waveform
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildWaveform(context),
            ),

            const SizedBox(height: 10),

            // Timestamps
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _fmt(_currentPosition),
                    style: const TextStyle(
                      color: Colors.white54,
                      fontFamily: 'sf_pro',
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    _fmt(_totalDuration),
                    style: const TextStyle(
                      color: Colors.white54,
                      fontFamily: 'sf_pro',
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Play / Pause button
            GestureDetector(
              onTap: _togglePlayPause,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isPrepared && !_hasError
                      ? const Color(0xFFAEFB2A)
                      : const Color(0xFFAEFB2A).withOpacity(0.25),
                  boxShadow: _isPrepared && !_hasError
                      ? [
                          BoxShadow(
                            color: const Color(0xFFAEFB2A).withOpacity(0.35),
                            blurRadius: 28,
                            spreadRadius: 4,
                          ),
                        ]
                      : null,
                ),
                child: (_isPrepared && !_hasError)
                    ? Icon(
                        _isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.black,
                        size: 38,
                      )
                    : const Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black54,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 24),

            // Transcript buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: hasTranscript
                  ? _buildViewTranscriptButton()
                  : _buildGenerateTranscriptButton(),
            ),

            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerateTranscriptButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: _isTranscribing ? null : _onGenerateTranscript,
        icon: _isTranscribing
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFFAEFB2A),
                ),
              )
            : const Icon(Icons.auto_awesome, size: 20),
        label: Text(
          _isTranscribing ? 'Generating...' : 'Generate Transcript',
          style: const TextStyle(
            color: Color(0xFFAEFB2A),
            fontFamily: 'sf_pro',
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFAEFB2A),
          side: const BorderSide(color: Color(0xFFAEFB2A), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _buildViewTranscriptButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton.icon(
        onPressed: _onViewTranscript,
        icon: const Icon(Icons.description_outlined, size: 20),
        label: const Text(
          'View Transcript',
          style: TextStyle(
            fontFamily: 'sf_pro',
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFAEFB2A),
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _buildWaveform(BuildContext context) {
    if (_hasError) {
      return Container(
        height: 72,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_outlined, color: Colors.white38, size: 20),
            SizedBox(width: 8),
            Text(
              'Audio file not available locally',
              style: TextStyle(
                color: Colors.white38,
                fontFamily: 'sf_pro',
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    // Loading skeleton waveform
    if (!_isPrepared) {
      return SizedBox(
        height: 72,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            48,
            (i) => Container(
              width: 3,
              height: (i % 3 == 0
                  ? 36.0
                  : i % 2 == 0
                      ? 22.0
                      : 14.0),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.10),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      );
    }

    final width = MediaQuery.of(context).size.width - 48;

    return AudioFileWaveforms(
      playerController: _playerController,
      size: Size(width, 80),

      // auto-scroll while playing (like recording feel)
      waveformType: WaveformType.long,

      // manual seek
      enableSeekGesture: true,

      // smoother visual motion
      animationDuration: const Duration(milliseconds: 120),
      animationCurve: Curves.easeOut,

      // avoid "snap back to 0" and jitter while dragging
      onDragStart: (_) async {
        _isUserSeeking = true;
        _wasPlayingBeforeSeek = _isPlaying;

        // pause during drag (optional but feels best)
        if (_isPlaying) {
          await _playerController.pausePlayer();
        }
      },

      onDragEnd: (_) async {
        _isUserSeeking = false;

        // resync UI to actual player current duration after seek
        final curMs = await _playerController.getDuration(DurationType.current);
        if (!mounted) return;
        setState(() {
          _currentPosition = Duration(milliseconds: curMs < 0 ? 0 : curMs);
        });

        // resume if it was playing before user started dragging
        if (_wasPlayingBeforeSeek) {
          await _playerController.startPlayer(forceRefresh: false);
        }
      },

      playerWaveStyle: const PlayerWaveStyle(
        fixedWaveColor: Color(0xFF3F5F00),
        liveWaveColor: Color(0xFFAEFB2A),
        spacing: 5.5,
        waveThickness: 3.0,
        seekLineColor: Color(0xFFAEFB2A),
        seekLineThickness: 1.5,
        showSeekLine: true,
      ),
    );
  }
}
