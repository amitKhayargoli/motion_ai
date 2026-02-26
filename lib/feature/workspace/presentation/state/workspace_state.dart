import 'package:motion_ai/feature/workspace/domain/entities/workspace_entity.dart';

class WorkspaceState {
  final bool isLoading;
  final String? error;
  final List<WorkspaceEntity> workspaces;
  final WorkspaceEntity? selected;

  const WorkspaceState({
    required this.isLoading,
    required this.workspaces,
    required this.selected,
    required this.error,
  });

  factory WorkspaceState.initial() => const WorkspaceState(
    isLoading: false,
    workspaces: [],
    selected: null,
    error: null,
  );

  WorkspaceState copyWith({
    bool? isLoading,
    String? error,
    List<WorkspaceEntity>? workspaces,
    WorkspaceEntity? selected,
    bool clearError = false,
  }) {
    return WorkspaceState(
      isLoading: isLoading ?? this.isLoading,
      workspaces: workspaces ?? this.workspaces,
      selected: selected ?? this.selected,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
