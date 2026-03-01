import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motion_ai/core/utils/snackbar_utils.dart';
import 'package:motion_ai/feature/workspace/presentation/view_model/workspace_view_model.dart';

const _green = Color(0xFF3F5F00);

void showWorkspaceSheet(BuildContext context, WidgetRef ref) {
  final nameController = TextEditingController();
  final inviteController = TextEditingController();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFFF5F6F9),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Consumer(
          builder: (context, ref, _) {
            final wsState = ref.watch(workspaceViewModelProvider);

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // drag handle
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 14),

                const Text(
                  "Workspaces",
                  style: TextStyle(
                    fontFamily: "sf_pro",
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _green,
                  ),
                ),

                const SizedBox(height: 12),

                // --- Workspace List (tap to select) ---
                if (wsState.workspaces.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      "No workspaces yet.",
                      style: TextStyle(
                        fontFamily: "sf_pro",
                        color: Colors.black54,
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: wsState.workspaces.length + 1, // + create tile
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      // Last item = Create Workspace tile
                      if (index == wsState.workspaces.length) {
                        return ListTile(
                          leading: const Icon(Icons.add, color: _green),
                          title: const Text(
                            "Create Workspace",
                            style: TextStyle(
                              fontFamily: "sf_pro",
                              fontWeight: FontWeight.w700,
                              color: _green,
                            ),
                          ),
                          onTap: () async {
                            await _showCreateDialog(ctx, ref, nameController);
                          },
                        );
                      }

                      final ws = wsState.workspaces[index];
                      final isSelected = wsState.selected?.id == ws.id;

                      return ListTile(
                        leading: Icon(
                          isSelected
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          color: isSelected ? _green : Colors.black38,
                        ),
                        title: Text(
                          ws.name,
                          style: TextStyle(
                            fontFamily: "sf_pro",
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        onTap: () {
                          ref
                              .read(workspaceViewModelProvider.notifier)
                              .selectWorkspace(ws.id);

                          SnackbarUtils.showSuccess(
                            ctx,
                            "Switched to ${ws.name}",
                          );
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),

                const SizedBox(height: 16),

                // --- Join Workspace Section ---
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Join by invite link",
                    style: TextStyle(
                      fontFamily: "sf_pro",
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _green.withOpacity(0.9),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                TextField(
                  controller: inviteController,
                  autofocus: false,
                  decoration: InputDecoration(
                    hintText: "Paste inviteLink (e.g. 8ed24428...)",
                    hintStyle: const TextStyle(
                      fontFamily: "sf_pro",
                      color: Colors.black38,
                    ),
                    prefixIcon: const Icon(Icons.link, color: _green),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _green.withOpacity(0.35)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _green, width: 1.5),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  style: const TextStyle(
                    fontFamily: "sf_pro",
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.group_add, color: Colors.white),
                    label: Text(
                      wsState.isLoading ? "Joining..." : "Join Workspace",
                      style: const TextStyle(
                        fontFamily: "sf_pro",
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    onPressed: wsState.isLoading
                        ? null
                        : () async {
                            final token = inviteController.text.trim();
                            if (token.isEmpty) {
                              SnackbarUtils.showError(
                                ctx,
                                "Invite link is required",
                              );
                              return;
                            }

                            final ok = await ref
                                .read(workspaceViewModelProvider.notifier)
                                .joinByInviteLink(token);

                            if (!ctx.mounted) return;

                            if (!ok) {
                              final err =
                                  ref.read(workspaceViewModelProvider).error ??
                                      "Failed to join workspace";
                              SnackbarUtils.showError(ctx, err);
                              return;
                            }

                            final selected =
                                ref.read(workspaceViewModelProvider).selected;
                            SnackbarUtils.showSuccess(
                              ctx,
                              "Joined ${selected?.name ?? "workspace"}",
                            );
                            Navigator.pop(ctx);
                          },
                  ),
                ),

                const SizedBox(height: 10),

                // Cancel button (green)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: _green,
                      textStyle: const TextStyle(
                        fontFamily: "sf_pro",
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("Cancel"),
                  ),
                ),
              ],
            );
          },
        ),
      );
    },
  );
}

Future<void> _showCreateDialog(
  BuildContext ctx,
  WidgetRef ref,
  TextEditingController controller,
) async {
  controller.clear();

  await showDialog(
    context: ctx,
    builder: (dialogCtx) {
      final wsState = ref.watch(workspaceViewModelProvider);

      return AlertDialog(
        title: const Text(
          "Create Workspace",
          style: TextStyle(
            fontFamily: "sf_pro",
            fontWeight: FontWeight.bold,
            color: _green,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: "Workspace name",
            hintStyle: const TextStyle(
              fontFamily: "sf_pro",
              color: Colors.black38,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _green.withOpacity(0.35)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _green, width: 1.5),
            ),
          ),
          style: const TextStyle(fontFamily: "sf_pro", color: Colors.black87),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: _green,
              textStyle: const TextStyle(
                fontFamily: "sf_pro",
                fontWeight: FontWeight.w600,
              ),
            ),
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _green),
            onPressed: wsState.isLoading
                ? null
                : () async {
                    final name = controller.text.trim();
                    if (name.isEmpty) {
                      SnackbarUtils.showError(dialogCtx, "Name is required");
                      return;
                    }

                    final ok = await ref
                        .read(workspaceViewModelProvider.notifier)
                        .createWorkspace(name);

                    if (!dialogCtx.mounted) return;

                    if (!ok) {
                      final err = ref.read(workspaceViewModelProvider).error ??
                          "Failed to create workspace";
                      SnackbarUtils.showError(dialogCtx, err);
                      return;
                    }

                    final selected =
                        ref.read(workspaceViewModelProvider).selected;
                    SnackbarUtils.showSuccess(
                      dialogCtx,
                      "Created ${selected?.name ?? "workspace"}",
                    );
                    Navigator.pop(dialogCtx); // close dialog
                    Navigator.pop(ctx); // close bottom sheet
                  },
            child: Text(
              wsState.isLoading ? "Creating..." : "Create",
              style: const TextStyle(
                fontFamily: "sf_pro",
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      );
    },
  );
}
