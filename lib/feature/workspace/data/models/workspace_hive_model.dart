import 'package:hive/hive.dart';
import 'package:motion_ai/feature/workspace/domain/entities/workspace_entity.dart';

part 'workspace_hive_model.g.dart';

@HiveType(typeId: 20) // make sure this typeId is unique in your app
class WorkspaceHiveModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final DateTime createdAt;

  WorkspaceHiveModel({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  factory WorkspaceHiveModel.fromEntity(WorkspaceEntity e) {
    return WorkspaceHiveModel(id: e.id, name: e.name, createdAt: e.createdAt);
  }

  WorkspaceEntity toEntity() {
    return WorkspaceEntity(id: id, name: name, createdAt: createdAt);
  }
}
