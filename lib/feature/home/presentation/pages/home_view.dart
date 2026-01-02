import 'package:flutter/material.dart';
import 'package:motion_ai/feature/home/presentation/pages/widgets/gradient_scaffold_widget.dart';
import 'package:motion_ai/feature/home/presentation/pages/widgets/mobile_recordings_widget.dart';
import 'package:motion_ai/feature/home/presentation/pages/widgets/today_card_widget.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      useDashboardGradient: true, // Use the radial dashboard gradient
      extendBody: true,
      body: SafeArea(
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
    );
  }
}
