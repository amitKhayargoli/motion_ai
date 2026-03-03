import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:motion_ai/feature/audio_file/domain/entities/audio_file_entity.dart';
import 'package:motion_ai/feature/audio_file/presentation/pages/audio_player_page.dart';
import 'package:motion_ai/feature/audio_file/presentation/view_model/audio_view_model.dart';

class MobileRecordingsWidget extends ConsumerWidget {
  const MobileRecordingsWidget({super.key, this.onViewAll});

  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(audioViewModelProvider);
    final audios = audioState.audios;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'MOBILE RECORDINGS',
              style: TextStyle(
                fontFamily: 'sf_pro',
                color: Colors.white70,
                fontSize: 14,
                letterSpacing: 1.5,
              ),
            ),
            if (audios != null && audios.length > 3)
              TextButton(
                onPressed: onViewAll,
                child: const Text(
                  'VIEW ALL',
                  style: TextStyle(
                    fontFamily: 'sf_pro',
                    color: Colors.white70,
                    fontSize: 14,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
          ],
        ),
        if (audios == null)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(color: Color(0xFFAEFB2A)),
            ),
          )
        else if (audios.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text(
              "No recordings yet",
              style: TextStyle(color: Colors.white54),
            ),
          )
        else
          ...audios.take(3).map(
                (audio) => _RecordingCard(audio: audio),
              ),
      ],
    );
  }
}

class _RecordingCard extends StatelessWidget {
  const _RecordingCard({required this.audio});

  final AudioFileEntity audio;

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('MMM d, h:mm a').format(date);
  }

  String _formatSeconds(int? seconds) {
    if (seconds == null) return '--:--';
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AudioPlayerPage(audio: audio),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Recording icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFAEFB2A).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.graphic_eq,
                color: Color(0xFFAEFB2A),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            // Title + metadata
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    audio.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'sf_pro',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _formatSeconds(audio.durationSeconds),
                          style: const TextStyle(
                            color: Colors.white54,
                            fontFamily: 'sf_pro',
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(audio.uploadedAt),
                        style: const TextStyle(
                          color: Colors.white38,
                          fontFamily: 'sf_pro',
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Play hint
            const Icon(
              Icons.chevron_right,
              color: Colors.white24,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
