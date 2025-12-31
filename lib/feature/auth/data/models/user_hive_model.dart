import 'package:hive/hive.dart';
import 'package:motion_ai/core/constants/hive_table_constant.dart';
import 'package:motion_ai/feature/auth/domain/entities/user_entity.dart';
import 'package:uuid/uuid.dart';
part 'user_hive_model.g.dart';

// dart run build_runner build -d

@HiveType(typeId: HiveTableConstant.userTypeId)
class UserHiveModel extends HiveObject {
  @HiveField(0)
  final String? userId;
  @HiveField(1)
  final String email;
  @HiveField(2)
  final String password;
  @HiveField(3)
  final userRole? role;
  @HiveField(4)
  final DateTime? createdAt;

  UserHiveModel({
    String? userId,
    required this.email,
    required this.password,
    userRole? role,
    DateTime? createdAt,
  }) : userId = userId ?? Uuid().v4(),
       role = role ?? userRole.user,
       createdAt = createdAt ?? DateTime.now();

  UserEntity toEntity() {
    return UserEntity(
      userId: userId,
      email: email,
      password: password,
      role: role,
      createdAt: createdAt,
    );
  }

  factory UserHiveModel.fromEntity(UserEntity entity) {
    return UserHiveModel(email: entity.email, password: entity.password);
  }

  static List<UserEntity> toEntityList(List<UserHiveModel> models) {
    return models.map((model) => model.toEntity()).toList();
  }
}
