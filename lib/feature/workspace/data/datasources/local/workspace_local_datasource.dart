import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:motion_ai/feature/workspace/data/datasources/workspace_datasource.dart';
import 'package:motion_ai/feature/workspace/data/models/workspace_hive_model.dart';
import 'package:motion_ai/core/providers/providers.dart';

final workspaceLocalDatasourceProvider = Provider<IWorkspaceLocalDataSource>((
  ref,
) {
  final box = ref.read(workspaceBoxProvider);
  return WorkspaceLocalDataSource(box);
});

class WorkspaceLocalDataSource implements IWorkspaceLocalDataSource {
  final Box<WorkspaceHiveModel> _box;
  WorkspaceLocalDataSource(this._box);

  @override
  Future<void> createWorkspace(WorkspaceHiveModel workspace) async {
    await _box.put(workspace.id, workspace);
  }

  @override
  Future<List<WorkspaceHiveModel>> getAllWorkspaces() async {
    final list = _box.values.toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<WorkspaceHiveModel?> getWorkspaceById(String id) async {
    return _box.get(id);
  }

  @override
  Future<void> deleteWorkspace(String id) async {
    await _box.delete(id);
  }

  @override
  Future<void> upsertWorkspace(WorkspaceHiveModel workspace) async {
    await _box.put(workspace.id, workspace);
  }

  @override
  Future<void> replaceAll(List<WorkspaceHiveModel> workspaces) async {
    await _box.clear();
    for (final w in workspaces) {
      await _box.put(w.id, w);
    }
  }
}
