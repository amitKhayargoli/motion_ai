import 'package:flutter_test/flutter_test.dart';
import 'package:motion_ai/core/services/hive/hive_service.dart';
import 'package:motion_ai/core/services/storage/token_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockHiveService extends HiveService {
  MockHiveService() : super(); // only if HiveService has a zero-arg constructor
  // implement any methods you need, or leave empty
}

class MockSharedPreferences extends Fake implements SharedPreferences {}

class MockTokenService extends Fake implements TokenService {}
