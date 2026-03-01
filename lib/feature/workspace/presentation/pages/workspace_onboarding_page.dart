import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motion_ai/core/utils/snackbar_utils.dart';
import 'package:motion_ai/feature/home/presentation/pages/dashboard_view.dart';
import 'package:motion_ai/feature/home/presentation/pages/widgets/gradient_scaffold_widget.dart';
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

    return GradientScaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 50),
              const Text(
                'Welcome',
                style: TextStyle(
                  fontFamily: 'sf_pro',
                  fontSize: 34,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Create your first workspace or join an existing one.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  fontFamily: 'sf_pro',
                ),
              ),
              const SizedBox(height: 32),

              // CREATE
              _buildTextField(
                label: 'Workspace name',
                hint: 'My Workspace',
                controller: _createController,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: canCreate ? _handleCreate : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFAEFB2A),
                    disabledBackgroundColor: const Color(0x66AEFB2A),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isLoading ? 'Creating...' : 'Create Workspace',
                    style: const TextStyle(
                      fontFamily: 'sf_pro',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(child: Container(height: 1, color: Colors.white12)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'OR',
                      style: TextStyle(
                        color: Colors.white38,
                        fontFamily: 'sf_pro',
                      ),
                    ),
                  ),
                  Expanded(child: Container(height: 1, color: Colors.white12)),
                ],
              ),
              const SizedBox(height: 28),

              // JOIN
              _buildTextField(
                label: 'Invite link',
                hint: 'Paste invite link',
                controller: _joinController,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: canJoin ? _handleJoin : null,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0x38FFFFFF)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    isLoading ? 'Joining...' : 'Join Workspace',
                    style: const TextStyle(
                      fontFamily: 'sf_pro',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
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

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'sf_pro',
            color: Colors.white70,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'sf_pro',
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Colors.white38,
              fontFamily: 'sf_pro',
              fontSize: 16,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF98C149)),
            ),
          ),
        ),
      ],
    );
  }
}
