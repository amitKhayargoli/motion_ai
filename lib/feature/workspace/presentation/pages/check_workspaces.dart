import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motion_ai/feature/home/presentation/pages/dashboard_view.dart';
import 'package:motion_ai/feature/workspace/presentation/pages/workspace_onboarding_page.dart';
import 'package:motion_ai/feature/workspace/presentation/view_model/workspace_view_model.dart';

class CheckWorkspaces extends ConsumerStatefulWidget {
  const CheckWorkspaces({super.key});

  @override
  ConsumerState<CheckWorkspaces> createState() => _CheckWorkspacesState();
}

class _CheckWorkspacesState extends ConsumerState<CheckWorkspaces> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runRedirect());
  }

  Future<void> _runRedirect() async {
    final ok =
        await ref.read(workspaceViewModelProvider.notifier).fetchMyWorkspaces();

    if (!mounted) return;

    if (!ok) {
      _go(const WorkspaceOnboardingPage());
      return;
    }

    // Read state AFTER fetch completes
    final workspaces = ref.read(workspaceViewModelProvider).workspaces;

    if (workspaces.isEmpty) {
      _go(const WorkspaceOnboardingPage());
    } else {
      _go(const DashboardView());
    }
  }

  void _go(Widget page) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
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
          child: Image.asset("assets/images/logo.png", width: 150),
        ),
      ),
    );
  }
}
