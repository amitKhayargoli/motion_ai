import 'package:flutter/material.dart';
import 'package:motion_ai/feature/home/view/widgets/mobile_recordings_widget.dart';
import 'package:motion_ai/feature/home/view/widgets/today_card_widget.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -1.2),
            radius: 2.2,
            colors: [
              Color(0xFF000000),
              Color(0xFF1A2900),
              Color(0xFF3F5F00),
              Color(0xFF232c16),
            ],
            stops: [0.0, 0.25, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                const Center(
                  child: Text(
                    'MOTION WORKSPACE',
                    style: TextStyle(
                      fontFamily: 'sf_pro',
                      color: Colors.white70,
                      fontSize: 14,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),

                const SizedBox(height: 30),
                const TodayCardWidget(),
                const SizedBox(height: 30),
                const MobileRecordingsWidget(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
