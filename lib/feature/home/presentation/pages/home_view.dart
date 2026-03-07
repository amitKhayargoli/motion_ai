import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motion_ai/feature/home/presentation/pages/user_profile_view.dart';
import 'package:motion_ai/feature/home/presentation/pages/widgets/gradient_scaffold_widget.dart';
import 'package:motion_ai/feature/home/presentation/pages/widgets/mobile_recordings_widget.dart';
import 'package:motion_ai/feature/home/presentation/pages/widgets/workspace_bottom_sheet.dart';
import 'package:motion_ai/feature/tasks/presentation/widgets/today_card_widget.dart';
import 'package:motion_ai/feature/workspace/presentation/view_model/workspace_view_model.dart';

class HomeView extends ConsumerWidget {
  const HomeView({super.key, this.onViewAllRecordings});

  final VoidCallback? onViewAllRecordings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wsState = ref.watch(workspaceViewModelProvider);

    final workspaceName = wsState.selected?.name ??
        (wsState.workspaces.isNotEmpty
            ? wsState.workspaces.first.name
            : "MOTION WORKSPACE");

    return GradientScaffold(
      useDashboardGradient: true,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Top row: [+]   WorkspaceName   [Profile]
              Row(
                children: [
                  // Left: workspace switch button
                  GestureDetector(
                    onTap: () => showWorkspaceSheet(context, ref),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Icon(
                        Icons.apps_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Center: current workspace name
                  Expanded(
                    child: Text(
                      workspaceName.toUpperCase(),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'sf_pro',
                        color: Colors.white70,
                        fontSize: 14,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Right: profile icon
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProfileScreen(),
                        ),
                      );
                    },
                    child: const CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.person, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),
              const TodayCardWidget(),
              const SizedBox(height: 30),
              MobileRecordingsWidget(
                onViewAll: onViewAllRecordings,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
