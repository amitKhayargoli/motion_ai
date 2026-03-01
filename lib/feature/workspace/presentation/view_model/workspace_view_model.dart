import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motion_ai/feature/workspace/domain/entities/workspace_entity.dart';
import 'package:motion_ai/feature/workspace/domain/usecases/create_workspace_usecase.dart';
import 'package:motion_ai/feature/workspace/domain/usecases/get_workspace_usecase.dart';
import 'package:motion_ai/feature/workspace/domain/usecases/join_by_invite_link_usecase.dart';
import 'package:motion_ai/feature/workspace/domain/usecases/update_workspace_usecase.dart';
import 'package:motion_ai/feature/workspace/presentation/state/workspace_state.dart';

final workspaceViewModelProvider =
    NotifierProvider<WorkspaceViewModel, WorkspaceState>(
  WorkspaceViewModel.new,
);

class WorkspaceViewModel extends Notifier<WorkspaceState> {
  @override
  WorkspaceState build() {
    return WorkspaceState.initial();
  }

  Future<bool> fetchMyWorkspaces() async {
    // Always reset to clean state before fetching
    state = WorkspaceState.initial().copyWith(isLoading: true);

    final usecase = ref.read(getWorkspacesUsecaseProvider);
    final res = await usecase();

    return res.fold(
      (f) {
        state = state.copyWith(isLoading: false, error: f.message);
        return false;
      },
      (data) {
        final list = (data as List).cast<WorkspaceEntity>();
        state = state.copyWith(
          isLoading: false,
          workspaces: list,
          selected: list.isNotEmpty ? list.first : null,
        );
        return true;
      },
    );
  }

  Future<bool> createWorkspace(String name) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final usecase = ref.read(createWorkspaceUsecaseProvider);
    final res = await usecase(name);

    return res.fold(
      (f) {
        state = state.copyWith(isLoading: false, error: f.message);
        return false;
      },
      (data) {
        final ws = data as WorkspaceEntity;
        final updated = [ws, ...state.workspaces];
        state = state.copyWith(
          isLoading: false,
          workspaces: updated,
          selected: ws,
        );
        return true;
      },
    );
  }

  Future<bool> joinByInviteLink(String inviteLink) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final usecase = ref.read(joinByInviteLinkUsecaseProvider);
    final res = await usecase(inviteLink);

    return res.fold(
      (f) {
        state = state.copyWith(isLoading: false, error: f.message);
        return false;
      },
      (data) {
        final ws = data as WorkspaceEntity;
        final exists = state.workspaces.any((w) => w.id == ws.id);
        final updated = exists ? state.workspaces : [ws, ...state.workspaces];

        state = state.copyWith(
          isLoading: false,
          workspaces: updated,
          selected: ws,
        );
        return true;
      },
    );
  }

  void selectWorkspace(String workspaceId) {
    final found = state.workspaces.where((w) => w.id == workspaceId).toList();
    if (found.isEmpty) return;
    state = state.copyWith(selected: found.first);
  }

  /// Cycles to the next workspace in the list (wraps around).
  /// Returns the newly selected workspace, or null if cycling is not possible.
  WorkspaceEntity? cycleToNextWorkspace() {
    if (state.workspaces.length < 2) return null;
    if (state.selected == null) return null;

    final currentIndex = state.workspaces.indexWhere(
      (w) => w.id == state.selected!.id,
    );
    if (currentIndex == -1) return null;

    final nextIndex = (currentIndex + 1) % state.workspaces.length;
    final nextWorkspace = state.workspaces[nextIndex];

    state = state.copyWith(selected: nextWorkspace);
    return nextWorkspace;
  }

  Future<bool> updateWorkspace(String workspaceId, String name) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final usecase = ref.read(updateWorkspaceUsecaseProvider);
    final res = await usecase(
      UpdateWorkspaceParams(workspaceId: workspaceId, name: name),
    );

    return res.fold(
      (f) {
        state = state.copyWith(isLoading: false, error: f.message);
        return false;
      },
      (ws) {
        final updated =
            state.workspaces.map((w) => w.id == workspaceId ? ws : w).toList();
        state = state.copyWith(
          isLoading: false,
          workspaces: updated,
          selected: state.selected?.id == workspaceId ? ws : state.selected,
        );
        return true;
      },
    );
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}
