import 'package:flutter/material.dart';
import 'package:motion_ai/feature/home/presentation/pages/widgets/gradient_scaffold_widget.dart';
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

            const SizedBox(height: 40),
            Container(
              width: 200,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF2A2A2A)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Meeting header
                  Row(
                    children: [
                      Icon(Icons.mic, color: Color(0xFFAEFB2A), size: 20),
                      SizedBox(width: 10),
                      Container(
                        width: 100,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Transcript line
                  Row(
                    children: [
                      Icon(Icons.notes, color: Color(0xFFAEFB2A), size: 20),
                      SizedBox(width: 10),
                      Container(
                        width: 70,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Summary line
                  Row(
                    children: [
                      Icon(Icons.summarize_outlined,
                          color: Colors.white38, size: 20),
                      SizedBox(width: 10),
                      Container(
                        width: 85,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Transcription indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.graphic_eq,
                          color: Color(0xFFAEFB2A), size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Transcribing',
                        style: TextStyle(
                          fontFamily: 'sf_pro',
                          color: Color(0xFFAEFB2A),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

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
