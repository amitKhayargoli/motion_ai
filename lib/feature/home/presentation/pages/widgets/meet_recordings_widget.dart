import 'package:flutter/material.dart';
import 'package:motion_ai/feature/home/presentation/pages/widgets/meet_recording_item_widget.dart';
import 'package:motion_ai/feature/home/presentation/pages/widgets/recording_item_widget.dart';

class MeetRecordingsWidget extends StatelessWidget {
  const MeetRecordingsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Meeting Recordings',
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
                style: TextStyle(
                  fontFamily: 'sf_pro',
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        const MeetRecordingItemWidget(),
        const SizedBox(height: 10),
        const MeetRecordingItemWidget(),
      ],
    );
  }
}
