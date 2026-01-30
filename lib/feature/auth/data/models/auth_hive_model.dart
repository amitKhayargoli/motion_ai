import 'package:hive/hive.dart';
import 'package:motion_ai/core/constants/hive_table_constant.dart';
import 'package:motion_ai/feature/auth/domain/entities/auth_entity.dart';

import 'package:uuid/uuid.dart';
part 'auth_hive_model.g.dart';

// dart run build_runner build -d

@HiveType(typeId: HiveTableConstant.userTypeId)
class AuthHiveModel extends HiveObject {
  @HiveField(0)
  final String? userId;
  @HiveField(1)
  final String email;
  @HiveField(2)
  final String? password;
  @HiveField(3)
  final DateTime? createdAt;
  //username
  @HiveField(4)
  final String? username;

  AuthHiveModel({
    String? userId,
    required this.email,
    required this.password,
    this.username,

    DateTime? createdAt,
  }) : userId = userId ?? Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  AuthEntity toEntity() {
    return AuthEntity(
      userId: userId,
      email: email,
      password: password,
      createdAt: createdAt,
      username: username,
    );
  }

  factory AuthHiveModel.fromEntity(AuthEntity entity) {
    return AuthHiveModel(
      email: entity.email,
      password: entity.password,
      username: entity.username,
      userId: entity.userId,
      createdAt: entity.createdAt,
    );
  }

  static List<AuthEntity> toEntityList(List<AuthHiveModel> models) {
    return models.map((model) => model.toEntity()).toList();
  }
}
