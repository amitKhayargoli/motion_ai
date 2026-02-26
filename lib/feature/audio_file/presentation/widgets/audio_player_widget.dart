import 'dart:io';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String audioPath;
  final Color waveColor;
  final Color activeWaveColor;

  const AudioPlayerWidget({
    super.key,
    required this.audioPath,
    this.waveColor = const Color(0xFF3F5F00),
    this.activeWaveColor = const Color(0xFFAEFB2A),
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  late PlayerController _playerController;
  bool _isPlaying = false;
  bool _isPrepared = false;
  bool _hasError = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _playerController = PlayerController();
    _preparePlayer();
  }

  Future<void> _preparePlayer() async {
    try {
      final file = File(widget.audioPath);
      if (!file.existsSync()) {
        setState(() => _hasError = true);
        return;
      }

      await _playerController.preparePlayer(
        path: widget.audioPath,
        shouldExtractWaveform: true,
        noOfSamples: 100,
        volume: 1.0,
      );

      _playerController.onPlayerStateChanged.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state == PlayerState.playing;
          });
        }
      });

      _playerController.onCurrentDurationChanged.listen((duration) {
        if (mounted) {
          setState(() {
            _currentPosition = Duration(milliseconds: duration);
          });
        }
      });

      _playerController.onCurrentExtractedWaveformData.listen((_) {
        if (mounted) setState(() {});
      });

      final maxDuration = _playerController.maxDuration;
      _totalDuration = Duration(milliseconds: maxDuration);

      _playerController.onCompletion.listen((_) {
        if (mounted) {
          setState(() {
            _isPlaying = false;
            _currentPosition = Duration.zero;
          });
        }
      });

      setState(() => _isPrepared = true);
    } catch (e) {
      debugPrint('AudioPlayerWidget error: $e');
      setState(() => _hasError = true);
    }
  }

  @override
  void dispose() {
    _playerController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _togglePlayPause() async {
    if (_isPlaying) {
      await _playerController.pausePlayer();
    } else {
      await _playerController.startPlayer();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        padding: const EdgeInsets.all(12),
        child: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white38, size: 20),
            SizedBox(width: 8),
            Text(
              'Audio file unavailable',
              style: TextStyle(color: Colors.white38, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (!_isPrepared) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFFAEFB2A),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            // Play / Pause button
            GestureDetector(
              onTap: _togglePlayPause,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.activeWaveColor,
                ),
                child: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.black,
                  size: 20,
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Waveform
            Expanded(
              child: AudioFileWaveforms(
                playerController: _playerController,
                size: Size(MediaQuery.of(context).size.width - 140, 40),
                waveformType: WaveformType.fitWidth,
                playerWaveStyle: PlayerWaveStyle(
                  fixedWaveColor: widget.waveColor.withOpacity(0.4),
                  liveWaveColor: widget.activeWaveColor,
                  spacing: 5,
                  waveThickness: 2.5,
                  seekLineColor: Colors.transparent,
                  showSeekLine: false,
                ),
                enableSeekGesture: true,
              ),
            ),
          ],
        ),

        const SizedBox(height: 4),

        // Duration labels
        Padding(
          padding: const EdgeInsets.only(left: 48),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(_currentPosition),
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontFamily: 'sf_pro',
                ),
              ),
              Text(
                _formatDuration(_totalDuration),
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontFamily: 'sf_pro',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
