import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motion_ai/feature/audio_file/presentation/view_model/audio_view_model.dart';
import 'package:motion_ai/feature/home/presentation/pages/widgets/recording_item_widget.dart';

class MobileRecordingsWidget extends ConsumerWidget {
  const MobileRecordingsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(audioViewModelProvider);

    // Use a local variable with a null check
    final audios = audioState.audios;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Mobile Recordings',
              style: TextStyle(
                fontFamily: 'sf_pro',
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'View all',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ),
          ],
        ),

        // 1. Handle the Null/Loading state
        if (audios == null)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(color: Color(0xFFAEFB2A)),
            ),
          )
        // 2. Handle the Empty state
        else if (audios.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text(
              "No recordings yet",
              style: TextStyle(color: Colors.white54),
            ),
          )
        // 3. Display the Data
        else
          ...audios
              .take(6)
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: RecordingItemWidget(audio: item),
                ),
              ),
      ],
    );
  }
}
