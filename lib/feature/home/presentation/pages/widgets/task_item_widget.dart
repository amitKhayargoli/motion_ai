import 'package:flutter/material.dart';

class TaskItemWidget extends StatelessWidget {
  final String task;
  final bool isCompleted;
  final VoidCallback? onTap;

  const TaskItemWidget({
    super.key,
    required this.task,
    required this.isCompleted,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            isCompleted
                ? Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Color(0xFFAEFB2A),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.check,
                        color: Colors.black,
                        size: 14,
                      ),
                    ),
                  )
                : Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white70)),
                  ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                task,
                style: TextStyle(
                  fontFamily: 'sf_pro',
                  color: Colors.white,
                  fontSize: 16,
                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                  decorationColor: Colors.white54,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
