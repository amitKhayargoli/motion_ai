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
  bool _ran = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_ran) return;
    _ran = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runRedirect();
    });
  }

  Future<void> _runRedirect() async {
    final ok = await ref
        .read(workspaceViewModelProvider.notifier)
        .fetchMyWorkspaces();

    if (!mounted) return;

    final wsState = ref.read(workspaceViewModelProvider);

    // If API failed, go onboarding fallback
    if (!ok) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WorkspaceOnboardingPage()),
      );
      return;
    }

    if (wsState.workspaces.isEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WorkspaceOnboardingPage()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardView()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
