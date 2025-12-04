import 'package:flutter/material.dart';
import 'package:motion_ai/feature/onboarding/view/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _opacity = 0;
  double _scale = 0.6;

  @override
  void initState() {
    super.initState();

    // Start logo fade + scale animation
    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        _opacity = 1;
        _scale = 1;
      });
    });

    // Navigate after animation duration
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2E3D28), Color(0xFF000000)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeInOut,
            opacity: _opacity,
            child: AnimatedScale(
              scale: _scale,
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutBack,
              child: Image.asset("assets/images/logo.png", width: 150),
            ),
          ),
        ),
      ),
    );
  }
}
