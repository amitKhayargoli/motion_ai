import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motion_ai/core/services/storage/user_session_service.dart';
import 'package:motion_ai/core/providers/providers.dart';
import 'package:motion_ai/feature/home/presentation/pages/dashboard_view.dart';
import 'package:motion_ai/routes/app_routes.dart';
import '../../../onboarding/presentation/pages/onboarding_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
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

    _navigateToNext();
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

  void _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    //check if user is already logged in
    final userSessionService = ref.read(userSessionServiceProvider);
    final isLoggedIn = userSessionService.isLoggedIn();

    if (isLoggedIn) {
      AppRoutes.pushReplacement(context, const DashboardView());
    } else {
      AppRoutes.pushReplacement(context, const OnboardingScreen());
    }
  }
}
