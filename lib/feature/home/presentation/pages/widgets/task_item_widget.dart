import 'package:flutter/material.dart';

class TaskItemWidget extends StatelessWidget {
  final String task;
  final bool isCompleted;

  const TaskItemWidget({
    super.key,
    required this.task,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check,
                      color: Colors.white,
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
          Text(
            task,
            style: const TextStyle(
                fontFamily: 'sf_pro', color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
