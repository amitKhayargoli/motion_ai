import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motion_ai/core/api/api_client.dart';
import 'package:motion_ai/core/api/api_endpoints.dart';
import 'package:motion_ai/feature/workspace/data/datasources/workspace_datasource.dart';
import 'package:motion_ai/feature/workspace/data/models/workspace_api_model.dart';

final workspaceRemoteDatasourceProvider = Provider<IWorkspaceRemoteDataSource>((
  ref,
) {
  final api = ref.read(apiClientProvider);
  return WorkspaceRemoteDataSource(api);
});

class WorkspaceRemoteDataSource implements IWorkspaceRemoteDataSource {
  final ApiClient _api;
  WorkspaceRemoteDataSource(this._api);

  Map<String, dynamic> _extractData(dynamic resData) {
    if (resData is Map && resData['data'] != null) {
      return Map<String, dynamic>.from(resData['data']);
    }
    return Map<String, dynamic>.from(resData as Map);
  }

  List _extractList(dynamic resData) {
    if (resData is Map && resData['data'] != null) {
      return resData['data'] as List;
    }
    return resData as List;
  }

  @override
  Future<WorkspaceApiModel> createWorkspace(String name) async {
    final res = await _api.post(
      ApiEndpoints.createWorkspace,
      data: {'name': name},
    );

    final data = _extractData(res.data);
    return WorkspaceApiModel.fromJson(data);
  }

  @override
  Future<List<WorkspaceApiModel>> getMyWorkspaces() async {
    final res = await _api.get(ApiEndpoints.myWorkspaces);
    final list = _extractList(res.data);

    return list
        .map((e) => WorkspaceApiModel.fromJson(Map<String, dynamic>.from(e)))
        .toList()
        .cast<WorkspaceApiModel>();
  }

  @override
  Future<WorkspaceApiModel?> getWorkspaceById(String id) async {
    final res = await _api.get(ApiEndpoints.workspaceById(id));
    final data = _extractData(res.data);
    return WorkspaceApiModel.fromJson(data);
  }

  @override
  Future<void> deleteWorkspace(String id) async {
    await _api.delete(ApiEndpoints.deleteWorkspace(id));
  }

  @override
  Future<WorkspaceApiModel> joinByInviteLink(String inviteLink) async {
    final res = await _api.post(
      ApiEndpoints.joinWorkspace,
      queryParameters: {'inviteLink': inviteLink},
    );

    final data = _extractData(res.data);
    return WorkspaceApiModel.fromJson(data);
  }
}
