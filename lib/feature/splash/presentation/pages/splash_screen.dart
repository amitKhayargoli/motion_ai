import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motion_ai/core/services/storage/user_session_service.dart';
import 'package:motion_ai/core/providers/providers.dart';
import 'package:motion_ai/feature/auth/presentation/pages/login_page.dart';
import 'package:motion_ai/feature/auth/presentation/view_model/auth_viewmodel.dart';
import 'package:motion_ai/feature/home/presentation/pages/dashboard_view.dart';
import 'package:motion_ai/feature/workspace/presentation/pages/workspace_onboarding_page.dart';
import 'package:motion_ai/feature/workspace/presentation/view_model/workspace_view_model.dart';
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

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _opacity = 1;
        _scale = 1;
      });
    });

    _navigateToNext();
  }

  void _navigateToNext() async {
    final session = ref.read(userSessionServiceProvider);
    final isLoggedIn = session.isLoggedIn();
    final userId = isLoggedIn ? session.getUserId() : null;

    // Start Hive init and the animation delay concurrently
    final hiveFuture = (userId != null && userId.isNotEmpty)
        ? () async {
            final hive = ref.read(hiveServiceProvider);
            await hive.init();
            await hive.setActiveUser(userId);
          }()
        : Future<void>.value();

    await Future.wait([
      Future.delayed(const Duration(milliseconds: 1500)),
      hiveFuture,
    ]);

    if (!mounted) return;

    // Not logged in → onboarding
    if (!isLoggedIn) {
      AppRoutes.pushReplacement(context, const OnboardingScreen());
      return;
    }

    if (userId == null || userId.isEmpty) {
      // session is inconsistent -> force logout flow
      await session.clearUserSession();
      AppRoutes.pushReplacement(context, const OnboardingScreen());
      return;
    }

    // Load user profile into AuthState (returns from Hive instantly)
    await ref.read(authViewModelProvider.notifier).getCurrentUser();

    // Fetch workspaces (returns from Hive instantly if cached)
    final ok =
        await ref.read(workspaceViewModelProvider.notifier).fetchMyWorkspaces();

    if (!mounted) return;

    if (!ok || ref.read(workspaceViewModelProvider).workspaces.isEmpty) {
      AppRoutes.pushReplacement(context, const WorkspaceOnboardingPage());
    } else {
      AppRoutes.pushReplacement(context, const DashboardView());
    }
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
