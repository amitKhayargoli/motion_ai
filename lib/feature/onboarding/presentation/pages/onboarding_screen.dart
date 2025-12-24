import 'package:flutter/material.dart';
import 'package:motion_ai/feature/home/presentation/pages/widgets/gradient_scaffold_widget.dart';
import 'onboarding_meeting_notes_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "MOTION AI",
          style: TextStyle(
            fontFamily: 'sf_pro',
            fontWeight: FontWeight.w500,
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        actions: [
          Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(999),
            ),
            child: IconButton(
              icon: Icon(Icons.close, color: Colors.grey[800]),
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              Image.asset('assets/images/logo.png', height: 80),
              const Text(
                "Motion",
                style: TextStyle(
                  fontFamily: 'poppins_regular',
                  fontWeight: FontWeight.w500,
                  fontSize: 48,
                  color: Colors.white,
                ),
              ),
              Text(
                "Your ideas, perfectly in sync.",
                style: TextStyle(
                  fontFamily: 'sf_pro',
                  fontSize: 18,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                "“Every thought is a frame in motion \n — capture it, refine it, and let your \n day flow with quiet precision.”",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'play_fair_display',
                  fontSize: 20,
                  color: Color(0xFFF5F5F5),
                  height: 1.5,
                ),
              ),
              const Spacer(flex: 3),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MeetingNotesScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFAEFB2A),
                  minimumSize: const Size(double.infinity, 53),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Get started",
                  style: TextStyle(
                    fontFamily: 'sf_pro',
                    fontWeight: FontWeight.w500,
                    fontSize: 18,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
