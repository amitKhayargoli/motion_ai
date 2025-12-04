import 'package:flutter/material.dart';
class OnboardingMotionScreen extends StatelessWidget {
  const OnboardingMotionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF2E3D28),
              Color(0xFF000000),
            ], // Dark Green to Black
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
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

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                decoration: const BoxDecoration(

                ),
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      height: 60,
                    ),
                    // Heading
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
              const SizedBox(height: 60),

              Image.asset('assets/images/meeting_notes.png'),

              // const SizedBox(height: 60),
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
      ),
    );
  }
}
