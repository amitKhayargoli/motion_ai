import 'package:motion_ai/feature/workspace/data/models/workspace_api_model.dart';
import 'package:motion_ai/feature/workspace/data/models/workspace_hive_model.dart';

abstract class IWorkspaceRemoteDataSource {
  Future<WorkspaceApiModel> createWorkspace(String name);
  Future<List<WorkspaceApiModel>> getMyWorkspaces();
  Future<WorkspaceApiModel?> getWorkspaceById(String id);
  Future<WorkspaceApiModel> updateWorkspace(String id, String name);
  Future<void> deleteWorkspace(String id);
  Future<WorkspaceApiModel> joinByInviteLink(String inviteLink);
}

abstract class IWorkspaceLocalDataSource {
  Future<void> createWorkspace(WorkspaceHiveModel workspace);
  Future<List<WorkspaceHiveModel>> getAllWorkspaces();
  Future<WorkspaceHiveModel?> getWorkspaceById(String id);
  Future<void> deleteWorkspace(String id);
  Future<void> upsertWorkspace(WorkspaceHiveModel workspace);
  Future<void> replaceAll(List<WorkspaceHiveModel> workspaces);
}
