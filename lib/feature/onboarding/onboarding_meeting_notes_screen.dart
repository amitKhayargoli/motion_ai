import 'package:flutter/material.dart';
import 'package:motion_ai/feature/home/view/widgets/gradient_scaffold_widget.dart';
import 'onboarding_mindspace_screen.dart';

class MeetingNotesScreen extends StatelessWidget {
  const MeetingNotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              child: ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(10)),
                child: LinearProgressIndicator(
                  value: 0.33,
                  backgroundColor: Color(0xFF3A3A3C),
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFAEFB2A)),
                  minHeight: 6,
                ),
              ),
            ),

            const Spacer(flex: 2),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Image.asset('assets/images/logo.png', height: 60),
                  const Text(
                    'Meeting Notes',
                    style: TextStyle(
                      fontFamily: 'poppins_regular',
                      fontSize: 34,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Meeting Summaries and Transcripts',
                    style: TextStyle(
                      fontFamily: 'sf_pro',
                      fontSize: 17,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 60),
            Image.asset('assets/images/meeting_notes.png'),

            const Spacer(flex: 3),

            const Text(
              'Record your meeting, \n generate a Transcript',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'sf_pro',
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.w100,
              ),
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const OnboardingMindspaceScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFAEFB2A),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(
                    fontFamily: 'sf_pro',
                    fontSize: 20,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
