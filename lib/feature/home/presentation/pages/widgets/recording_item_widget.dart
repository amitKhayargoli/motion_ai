import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:motion_ai/feature/audio_file/data/models/audio_file_hive_model.dart';
import 'package:motion_ai/feature/audio_file/domain/entities/audio_file_entity.dart';

class RecordingItemWidget extends StatelessWidget {
  final AudioFileEntity audio;
  final VoidCallback? onTap;

  const RecordingItemWidget({super.key, required this.audio, this.onTap});

  @override
  Widget build(BuildContext context) {
    // Format: Fri, Nov 21
    final String dateStr = DateFormat('EEE, MMM d').format(audio.uploadedAt!);

    // Format: 8:34 PM
    final String timeStr = DateFormat('h:mm a').format(audio.uploadedAt!);

    // Calculate end time based on duration (optional, but matches your UI)
    final DateTime endTime = audio.uploadedAt!.add(
      Duration(seconds: audio.durationSeconds!),
    );

    // Get Initials from username instead of uploaderId
    final String initials = audio.username.length >= 2
        ? audio.username.substring(0, 2).toUpperCase()
        : 'AI';

    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFAEFB2A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.graphic_eq, color: Colors.black),
      ),
      title: Text(
        audio.fileName!.split('.').first,
        style: const TextStyle(
          fontFamily: 'sf_pro',
          color: Colors.white,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        '$dateStr  $timeStr',
        style: const TextStyle(
          fontFamily: 'sf_pro',
          color: Colors.white70,
          fontSize: 13,
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFC700),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 12,
            fontFamily: 'sf_pro',
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
