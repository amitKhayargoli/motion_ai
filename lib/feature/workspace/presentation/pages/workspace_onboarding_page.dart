import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motion_ai/core/utils/snackbar_utils.dart';
import 'package:motion_ai/feature/home/presentation/pages/dashboard_view.dart';
import 'package:motion_ai/feature/workspace/presentation/view_model/workspace_view_model.dart';

class WorkspaceOnboardingPage extends ConsumerStatefulWidget {
  const WorkspaceOnboardingPage({super.key});

  @override
  ConsumerState<WorkspaceOnboardingPage> createState() =>
      _WorkspaceOnboardingPageState();
}

class _WorkspaceOnboardingPageState
    extends ConsumerState<WorkspaceOnboardingPage> {
  final _createController = TextEditingController();
  final _joinController = TextEditingController();

  @override
  void dispose() {
    _createController.dispose();
    _joinController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    final name = _createController.text.trim();
    if (name.isEmpty) {
      SnackbarUtils.showError(context, "Workspace name is required");
      return;
    }

    final ok = await ref
        .read(workspaceViewModelProvider.notifier)
        .createWorkspace(name);

    final state = ref.read(workspaceViewModelProvider);
    if (!ok) {
      SnackbarUtils.showError(context, state.error ?? "Failed to create");
      return;
    }

    _createController.clear();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const DashboardView()),
    );
  }

  Future<void> _handleJoin() async {
    final inviteLink = _joinController.text.trim();
    if (inviteLink.isEmpty) {
      SnackbarUtils.showError(context, "Invite link is required");
      return;
    }

    final ok = await ref
        .read(workspaceViewModelProvider.notifier)
        .joinByInviteLink(inviteLink);

    final state = ref.read(workspaceViewModelProvider);
    if (!ok) {
      SnackbarUtils.showError(context, state.error ?? "Failed to join");
      return;
    }

    _joinController.clear();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const DashboardView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wsState = ref.watch(workspaceViewModelProvider);
    final isLoading = wsState.isLoading;

    final canCreate = _createController.text.trim().isNotEmpty && !isLoading;
    final canJoin = _joinController.text.trim().isNotEmpty && !isLoading;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E3A0F), Color(0xFF2F5D15), Color(0xFF224210)],
            stops: [0.0, 0.4, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Container(
                width: 420,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "👋 Welcome",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontFamily: 'sf_pro',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Create your first workspace or join an existing one.",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontFamily: 'sf_pro',
                      ),
                    ),
                    const SizedBox(height: 18),

                    // CREATE
                    const Text(
                      "Workspace name",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontFamily: 'sf_pro',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _createController,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "My Workspace",
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.08),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: canCreate ? _handleCreate : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFAEFB2A),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          isLoading ? "Creating..." : "Create Workspace",
                          style: const TextStyle(
                            fontFamily: 'sf_pro',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: Container(height: 1, color: Colors.white12),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            "OR",
                            style: TextStyle(color: Colors.white38),
                          ),
                        ),
                        Expanded(
                          child: Container(height: 1, color: Colors.white12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // JOIN
                    const Text(
                      "Invite link",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontFamily: 'sf_pro',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _joinController,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Paste invite link",
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.08),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: canJoin ? _handleJoin : null,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.22),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          isLoading ? "Joining..." : "Join Workspace",
                          style: const TextStyle(
                            fontFamily: 'sf_pro',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                    if (wsState.error != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        wsState.error!,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
