import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motion_ai/feature/workspace/data/repositories/workspace_repository.dart';
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
    state = state.copyWith(isLoading: true, clearError: true);

    final repo = ref.read(workspaceRepositoryProvider);
    final res = await repo.getMyWorkspaces();

    return res.fold(
      (f) {
        state = state.copyWith(isLoading: false, error: f.message);
        return false;
      },
      (list) {
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

    final repo = ref.read(workspaceRepositoryProvider);
    final res = await repo.createWorkspace(name);

    return res.fold(
      (f) {
        state = state.copyWith(isLoading: false, error: f.message);
        return false;
      },
      (ws) {
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

    final repo = ref.read(workspaceRepositoryProvider);
    final res = await repo.joinByInviteLink(inviteLink);

    return res.fold(
      (f) {
        state = state.copyWith(isLoading: false, error: f.message);
        return false;
      },
      (ws) {
        // avoid duplicates
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

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}
