import 'package:flutter/material.dart';
import 'package:motion_ai/feature/home/view/widgets/task_item_widget.dart';

class TodayCardWidget extends StatelessWidget {
  const TodayCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '21 NOV FRIDAY',
                    style: TextStyle(
                        fontFamily: 'sf_pro',
                        color: Colors.white70,
                        fontSize: 12),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Today',
                    style: TextStyle(
                        fontFamily: 'play_fair_display',
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: const Icon(
                  Icons.arrow_outward,
                  color: Colors.black,
                  size: 40,
                ),
              )
            ],
          ),
          const SizedBox(height: 20),
          const TaskItemWidget(task: 'Attend Sprint Meeting', isCompleted: true),
          const SizedBox(height: 10),
          const TaskItemWidget(task: 'Review Sprint Backlog', isCompleted: false),
        ],
      ),
    );
  }
}
