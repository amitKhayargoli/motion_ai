import 'package:flutter/material.dart';

class GradientScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final bool extendBody;
  final bool extendBodyBehindAppBar;
  final bool useDashboardGradient;

  const GradientScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.extendBody = false,
    this.extendBodyBehindAppBar = true,
    this.useDashboardGradient = false, // default to onboarding gradient
  });

  // Default onboarding linear gradient (matches login/signup pages)
  static const LinearGradient onboardingGradient = LinearGradient(
    colors: [Color(0xFF273E00), Color(0xFF020200)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.54],
  );

  // Default Dashboard Radial Gradient
  static const RadialGradient dashboardGradient = RadialGradient(
    center: Alignment(0, -1.2),
    radius: 2.2,
    colors: [
      Color(0xFF000000),
      Color(0xFF1A2900),
      Color(0xFF3F5F00),
      Color(0xFF232c16),
    ],
    stops: [0.0, 0.25, 0.55, 1.0],
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: useDashboardGradient ? dashboardGradient : onboardingGradient,
      ),
      child: Scaffold(
        extendBody: extendBody,
        extendBodyBehindAppBar: extendBodyBehindAppBar,
        backgroundColor: Colors.transparent,
        appBar: appBar,
        bottomNavigationBar: bottomNavigationBar,
        body: body,
      ),
    );
  }
}
