import 'package:flutter/material.dart';

class RecordingItemWidget extends StatelessWidget {
  const RecordingItemWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFAEFB2A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.graphic_eq, color: Colors.black),
      ),
      title: const Text(
        'Weekly Meeting',
        style: TextStyle(
          fontFamily: 'sf_pro',
          color: Colors.white,
          fontSize: 16,
        ),
      ),
      subtitle: const Text(
        'Fri, Nov 21 8:34-8:35 PM',
        style: TextStyle(
          fontFamily: 'sf_pro',
          color: Colors.white70,
          fontSize: 13,
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFC700),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'AK',
          style: TextStyle(
            fontSize: 14,
            fontFamily: 'sf_pro',
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
