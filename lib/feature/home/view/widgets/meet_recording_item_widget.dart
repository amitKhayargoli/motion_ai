import 'package:flutter/material.dart';

class MeetRecordingItemWidget extends StatelessWidget {
  const MeetRecordingItemWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: ClipRRect(
        child: SizedBox(
          width: 56,
          height: 56,
          child: Container(
            child: Image.asset(
              'assets/images/google_meet.png',
              fit: BoxFit.contain, // ensures the image scales inside
            ),
          ),
        ),
      ),

      title: const Text(
        'Google Meet Recording',
        style: TextStyle(
          fontFamily: 'sf_pro',
          color: Colors.white,
          fontSize: 16,
        ),
      ),
      subtitle: const Text(
        'Mon, Dec 5 10:00-11:00 AM',
        style: TextStyle(
          fontFamily: 'sf_pro',
          color: Colors.white70,
          fontSize: 13,
        ),
      ),

    );
  }
}
