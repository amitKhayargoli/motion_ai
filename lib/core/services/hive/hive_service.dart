import 'package:hive/hive.dart';
import 'package:motion_ai/core/constants/hive_table_constant.dart';
import 'package:motion_ai/feature/auth/data/models/user_hive_model.dart';
import 'package:path_provider/path_provider.dart';

class HiveService {
  Future<void> init() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/${HiveTableConstant.dbName}';

    Hive.init(path);
    _registerAdapters();
    await _openBoxes();
  }

  void _registerAdapters() {
    if (!Hive.isAdapterRegistered(HiveTableConstant.userTypeId)) {
      Hive.registerAdapter(UserHiveModelAdapter());
    }
  }

  Future<void> _openBoxes() async {
    await Hive.openBox<UserHiveModel>(HiveTableConstant.userTable);
  }

  // Delete all users
  Future<void> deleteAllUsers() async {
    await _userBox.clear();
  }

  // Close all boxes
  Future<void> close() async {
    await Hive.close();
  }

  // =============== User CRUD Operations ====================

  // Get User Box
  Box<UserHiveModel> get _userBox =>
      Hive.box<UserHiveModel>(HiveTableConstant.userTable);

  // Create a new user (Register)
  Future<UserHiveModel> registerUser(UserHiveModel user) async {
    await _userBox.put(user.userId, user);
    return user;
  }

  // Get all users
  List<UserHiveModel> getAllUsers() {
    return _userBox.values.toList();
  }

  // Get user by ID
  UserHiveModel? getUserById(String userId) {
    return _userBox.get(userId);
  }

  // update user
  Future<void> updateUser(UserHiveModel user) async {
    await _userBox.put(user.userId, user);
  }

  // delete user
  Future<void> deleteUser(String userId) async {
    await _userBox.delete(userId);
  }
}
