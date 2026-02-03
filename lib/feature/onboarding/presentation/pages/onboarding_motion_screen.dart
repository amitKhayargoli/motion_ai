import 'package:flutter/material.dart';
import 'package:motion_ai/feature/home/presentation/pages/widgets/gradient_scaffold_widget.dart';
import '../../../auth/presentation/pages/login_page.dart';

class OnboardingMotionScreen extends StatelessWidget {
  const OnboardingMotionScreen({super.key});

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
                  value: 1,
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
                    'Motion',
                    style: TextStyle(
                      fontFamily: 'poppins_regular',
                      fontSize: 34,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Your ideas, perfectly in sync.',
                    style: TextStyle(
                      fontFamily: 'poppins_regular',
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
                  // Note item 1 - completed
                  Row(
                    children: [
                      Icon(Icons.check_circle,
                          color: Color(0xFFAEFB2A), size: 20),
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
                  // Note item 2 - completed
                  Row(
                    children: [
                      Icon(Icons.check_circle,
                          color: Color(0xFFAEFB2A), size: 20),
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
                  // Note item 3 - in progress
                  Row(
                    children: [
                      Icon(Icons.radio_button_unchecked,
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
                  // Sync indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.sync, color: Color(0xFFAEFB2A), size: 16),
                      SizedBox(width: 6),
                      Text(
                        'In sync',
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
              'Quiet Productivity \n No Noise. Just Notes.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'sf_pro',
                fontWeight: FontWeight.w400,
                fontSize: 28,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
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
                    fontWeight: FontWeight.w400,
                    fontSize: 20,
                    color: Colors.black,
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
