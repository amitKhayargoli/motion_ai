import 'package:flutter/material.dart';
import 'package:motion_ai/feature/home/presentation/pages/widgets/recording_item_widget.dart';

class MobileRecordingsWidget extends StatelessWidget {
  const MobileRecordingsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
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
                style: TextStyle(
                  fontFamily: 'sf_pro',
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        const RecordingItemWidget(),
        const SizedBox(height: 10),
        const RecordingItemWidget(),
        const SizedBox(height: 10),

      ],
    );
  }
}
