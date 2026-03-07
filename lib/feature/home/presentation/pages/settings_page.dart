import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motion_ai/core/utils/snackbar_utils.dart';
import 'package:motion_ai/feature/audio_file/presentation/providers/lift_to_stop_provider.dart';
import 'package:motion_ai/feature/auth/presentation/state/auth_state.dart';
import 'package:motion_ai/feature/auth/presentation/view_model/auth_viewmodel.dart';
import 'package:motion_ai/feature/home/presentation/providers/wave_to_switch_provider.dart';
import 'package:motion_ai/feature/notes/presentation/providers/shake_to_refresh_provider.dart';
import 'package:motion_ai/feature/workspace/presentation/view_model/workspace_view_model.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  static const String _appVersion = '1.0.0';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wsState = ref.watch(workspaceViewModelProvider);
    final selectedWorkspace = wsState.selected;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E3A0F), Color(0xFF2F5D15), Color(0xFF224210)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'SETTINGS',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white60,
                          letterSpacing: 2,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'sf_pro',
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    children: [
                      // Workspace section
                      if (selectedWorkspace != null)
                        _SectionCard(
                          title: 'Workspace',
                          children: [
                            _SettingsRow(
                              icon: Icons.workspaces_outlined,
                              label: selectedWorkspace.name,
                              trailing: const Icon(Icons.edit_outlined,
                                  color: Colors.white24, size: 18),
                              onTap: () => _showRenameDialog(context, ref,
                                  selectedWorkspace.id, selectedWorkspace.name),
                            ),
                          ],
                        ),

                      if (selectedWorkspace != null) const SizedBox(height: 20),

                      // Gestures section
                      _SectionCard(
                        title: 'Gestures',
                        children: [
                          Consumer(
                            builder: (context, ref, _) {
                              final enabled =
                                  ref.watch(waveToSwitchEnabledProvider);
                              return _SettingsRow(
                                icon: Icons.sensors,
                                label: 'Wave to Switch Workspace',
                                trailing: Switch.adaptive(
                                  value: enabled,
                                  activeColor: const Color(0xFFAEFB2A),
                                  onChanged: (val) => ref
                                      .read(
                                          waveToSwitchEnabledProvider.notifier)
                                      .state = val,
                                ),
                              );
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Sensors section
                      _SectionCard(
                        title: 'Sensors',
                        children: [
                          Consumer(
                            builder: (context, ref, _) {
                              final enabled =
                                  ref.watch(shakeToRefreshEnabledProvider);
                              return _SettingsRow(
                                icon: Icons.vibration,
                                label: 'Shake to Refresh Notes',
                                trailing: Switch.adaptive(
                                  value: enabled,
                                  activeColor: const Color(0xFFAEFB2A),
                                  onChanged: (val) => ref
                                      .read(shakeToRefreshEnabledProvider
                                          .notifier)
                                      .state = val,
                                ),
                              );
                            },
                          ),
                          const _CardDivider(),
                          Consumer(
                            builder: (context, ref, _) {
                              final enabled =
                                  ref.watch(liftToStopEnabledProvider);
                              return _SettingsRow(
                                icon: Icons.screen_rotation_outlined,
                                label: 'Lift to Stop Recording',
                                trailing: Switch.adaptive(
                                  value: enabled,
                                  activeColor: const Color(0xFFAEFB2A),
                                  onChanged: (val) => ref
                                      .read(liftToStopEnabledProvider.notifier)
                                      .state = val,
                                ),
                              );
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Security section
                      _SectionCard(
                        title: 'Security',
                        children: [
                          _SettingsRow(
                            icon: Icons.lock_outline,
                            label: 'Change Password',
                            trailing: const Icon(Icons.arrow_forward_ios,
                                color: Colors.white24, size: 16),
                            onTap: () =>
                                _showChangePasswordDialog(context, ref),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // General section
                      _SectionCard(
                        title: 'General',
                        children: [
                          _SettingsRow(
                            icon: Icons.info_outline,
                            label: 'App Version',
                            trailing: const Text(
                              _appVersion,
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 14,
                                fontFamily: 'sf_pro',
                              ),
                            ),
                          ),
                          const _CardDivider(),
                          _SettingsRow(
                            icon: Icons.description_outlined,
                            label: 'Terms of Service',
                            trailing: const Icon(Icons.arrow_forward_ios,
                                color: Colors.white24, size: 16),
                            onTap: () {},
                          ),
                          const _CardDivider(),
                          _SettingsRow(
                            icon: Icons.shield_outlined,
                            label: 'Privacy Policy',
                            trailing: const Icon(Icons.arrow_forward_ios,
                                color: Colors.white24, size: 16),
                            onTap: () {},
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // About section
                      _SectionCard(
                        title: 'About',
                        children: [
                          _SettingsRow(
                            icon: Icons.code,
                            label: 'Built with',
                            trailing: const Text(
                              'Flutter',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 14,
                                fontFamily: 'sf_pro',
                              ),
                            ),
                          ),
                          const _CardDivider(),
                          _SettingsRow(
                            icon: Icons.business,
                            label: 'Developer',
                            trailing: const Text(
                              'Motion AI Team',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 14,
                                fontFamily: 'sf_pro',
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),

                      // Footer
                      const Text(
                        'Motion AI v$_appVersion',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                          fontFamily: 'sf_pro',
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRenameDialog(
    BuildContext context,
    WidgetRef ref,
    String workspaceId,
    String currentName,
  ) {
    final controller = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E3A0F),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Rename Workspace',
            style: TextStyle(color: Colors.white, fontFamily: 'sf_pro'),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(color: Colors.white, fontFamily: 'sf_pro'),
            cursorColor: const Color(0xFFAEFB2A),
            decoration: InputDecoration(
              hintText: 'New workspace name',
              hintStyle: const TextStyle(color: Colors.white54),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFAEFB2A)),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel',
                  style:
                      TextStyle(color: Colors.white60, fontFamily: 'sf_pro')),
            ),
            TextButton(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isEmpty || name == currentName) {
                  Navigator.pop(dialogCtx);
                  return;
                }

                final ok = await ref
                    .read(workspaceViewModelProvider.notifier)
                    .updateWorkspace(workspaceId, name);

                if (!dialogCtx.mounted) return;

                if (!ok) {
                  final err = ref.read(workspaceViewModelProvider).error ??
                      "Failed to rename workspace";
                  SnackbarUtils.showError(dialogCtx, err);
                  return;
                }

                SnackbarUtils.showSuccess(dialogCtx, "Renamed to $name");
                Navigator.pop(dialogCtx);
              },
              child: const Text('Save',
                  style: TextStyle(
                      color: Color(0xFFAEFB2A), fontFamily: 'sf_pro')),
            ),
          ],
        );
      },
    );
  }

  void _showChangePasswordDialog(BuildContext context, WidgetRef ref) {
    final currentPasswordCtrl = TextEditingController();
    final newPasswordCtrl = TextEditingController();
    final confirmPasswordCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return _ChangePasswordDialog(
          currentPasswordCtrl: currentPasswordCtrl,
          newPasswordCtrl: newPasswordCtrl,
          confirmPasswordCtrl: confirmPasswordCtrl,
          onSave: () async {
            final current = currentPasswordCtrl.text.trim();
            final newPass = newPasswordCtrl.text.trim();
            final confirm = confirmPasswordCtrl.text.trim();

            if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
              SnackbarUtils.showError(dialogCtx, 'All fields are required');
              return;
            }
            if (newPass.length < 6) {
              SnackbarUtils.showError(
                  dialogCtx, 'Password must be at least 6 characters');
              return;
            }
            if (newPass != confirm) {
              SnackbarUtils.showError(
                  dialogCtx, 'New passwords do not match');
              return;
            }

            await ref
                .read(authViewModelProvider.notifier)
                .updateUser(password: newPass);

            if (!dialogCtx.mounted) return;

            final authState = ref.read(authViewModelProvider);
            if (authState.status == AuthStatus.error) {
              SnackbarUtils.showError(
                  dialogCtx, authState.errorMessage ?? 'Failed to update password');
              return;
            }

            SnackbarUtils.showSuccess(dialogCtx, 'Password updated successfully');
            Navigator.pop(dialogCtx);
          },
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              fontFamily: 'sf_pro',
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            color: Colors.white.withOpacity(0.05),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget trailing;
  final VoidCallback? onTap;

  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFAEFB2A), size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontFamily: 'sf_pro',
                ),
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _CardDivider extends StatelessWidget {
  const _CardDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(color: Colors.white.withOpacity(0.1), height: 1);
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  final TextEditingController currentPasswordCtrl;
  final TextEditingController newPasswordCtrl;
  final TextEditingController confirmPasswordCtrl;
  final VoidCallback onSave;

  const _ChangePasswordDialog({
    required this.currentPasswordCtrl,
    required this.newPasswordCtrl,
    required this.confirmPasswordCtrl,
    required this.onSave,
  });

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;

  InputDecoration _fieldDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38, fontFamily: 'sf_pro'),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFAEFB2A)),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E3A0F),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Change Password',
        style: TextStyle(color: Colors.white, fontFamily: 'sf_pro'),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Current password
          TextField(
            controller: widget.currentPasswordCtrl,
            obscureText: !_showCurrent,
            style: const TextStyle(color: Colors.white, fontFamily: 'sf_pro'),
            cursorColor: const Color(0xFFAEFB2A),
            decoration: _fieldDecoration('Current Password').copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  _showCurrent ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white38,
                  size: 20,
                ),
                onPressed: () => setState(() => _showCurrent = !_showCurrent),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // New password
          TextField(
            controller: widget.newPasswordCtrl,
            obscureText: !_showNew,
            style: const TextStyle(color: Colors.white, fontFamily: 'sf_pro'),
            cursorColor: const Color(0xFFAEFB2A),
            decoration: _fieldDecoration('New Password').copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  _showNew ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white38,
                  size: 20,
                ),
                onPressed: () => setState(() => _showNew = !_showNew),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Confirm new password
          TextField(
            controller: widget.confirmPasswordCtrl,
            obscureText: !_showConfirm,
            style: const TextStyle(color: Colors.white, fontFamily: 'sf_pro'),
            cursorColor: const Color(0xFFAEFB2A),
            decoration: _fieldDecoration('Confirm New Password').copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  _showConfirm ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white38,
                  size: 20,
                ),
                onPressed: () => setState(() => _showConfirm = !_showConfirm),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel',
              style: TextStyle(color: Colors.white60, fontFamily: 'sf_pro')),
        ),
        TextButton(
          onPressed: widget.onSave,
          child: const Text('Save',
              style:
                  TextStyle(color: Color(0xFFAEFB2A), fontFamily: 'sf_pro')),
        ),
      ],
    );
  }
}
