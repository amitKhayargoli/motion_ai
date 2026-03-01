import 'package:flutter/material.dart';

class NoteCard extends StatelessWidget {
  final String title;
  final String content; // plain-text preview
  final String category;
  final String time;
  final bool isPinned;
  final bool isSelected;

  const NoteCard({
    super.key,
    required this.title,
    this.content = '',
    required this.category,
    required this.time,
    this.isPinned = false,
    this.isSelected = false,
  });

  static const _accentGreen = Color(0xFFAEFB2A);

  static Color _categoryColor(String category) {
    switch (category) {
      case 'Voice Transcript':
        return const Color(0xFFFFB74D);
      case 'Meeting Summary':
        return const Color(0xFF64B5F6);
      case 'Manual Note':
        return _accentGreen;
      default:
        return Colors.white60;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isSelected
            ? _accentGreen.withOpacity(0.08)
            : Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isSelected
              ? _accentGreen.withOpacity(0.5)
              : Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle, color: _accentGreen, size: 20)
              else if (isPinned)
                const Icon(Icons.push_pin, color: _accentGreen, size: 18),
            ],
          ),
          if (content.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              content,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _categoryColor(category).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (category == 'Voice Transcript') ...[
                      Icon(Icons.mic,
                          size: 14, color: _categoryColor(category)),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      category,
                      style: TextStyle(
                          color: _categoryColor(category), fontSize: 13),
                    ),
                  ],
                ),
              ),
              Text(
                time,
                style: const TextStyle(color: Colors.white38, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
