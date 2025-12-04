import 'package:flutter/material.dart';
import 'package:motion_ai/screens/onboarding_screen.dart';
import 'package:motion_ai/screens/splash_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}
