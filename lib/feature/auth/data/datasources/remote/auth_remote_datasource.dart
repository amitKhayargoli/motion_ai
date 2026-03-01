import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motion_ai/core/api/api_client.dart';
import 'package:motion_ai/core/api/api_endpoints.dart';
import 'package:motion_ai/core/providers/providers.dart';
import 'package:motion_ai/core/services/hive/hive_service.dart';
import 'package:motion_ai/core/services/storage/token_service.dart';
import 'package:motion_ai/core/services/storage/user_session_service.dart';
import 'package:motion_ai/feature/auth/data/datasources/auth_datasource.dart';
import 'package:motion_ai/feature/auth/data/models/auth_api_model.dart';

// Create provider
final authRemoteProvider = Provider<IAuthRemoteDataSource>((ref) {
  return AuthRemoteDatasource(
    apiClient: ref.read(apiClientProvider),
    userSessionService: ref.read(userSessionServiceProvider),
    tokenService: ref.read(tokenServiceProvider),
    hiveService: ref.read(hiveServiceProvider),
  );
});

class AuthRemoteDatasource implements IAuthRemoteDataSource {
  final ApiClient _apiClient;
  final UserSessionService _userSessionService;
  final TokenService _tokenService;
  final HiveService _hiveService;

  AuthRemoteDatasource({
    required ApiClient apiClient,
    required UserSessionService userSessionService,
    required TokenService tokenService,
    required HiveService hiveService, // ✅ add
  })  : _apiClient = apiClient,
        _userSessionService = userSessionService,
        _tokenService = tokenService,
        _hiveService = hiveService;

  @override
  Future<bool> deleteUser(String authId) {
    // TODO: implement deleteUser
    throw UnimplementedError();
  }

  @override
  Future<AuthApiModel?> getCurrentUser() async {
    final response = await _apiClient.get(ApiEndpoints.getMe);

    if (response.data['success'] == true) {
      final data = response.data['data'] as Map<String, dynamic>;
      return AuthApiModel.fromJson(data);
    }
    return null;
  }

  @override
  Future<AuthApiModel?> getUserByEmail(String email) {
    // TODO: implement getUserByEmail
    throw UnimplementedError();
  }

  @override
  Future<AuthApiModel?> getUserById(String authId) {
    // TODO: implement getUserById
    throw UnimplementedError();
  }

  @override
  Future<bool> isEmailExists(String email) {
    // TODO: implement isEmailExists
    throw UnimplementedError();
  }

  @override
  Future<AuthApiModel?> login(String email, String password) async {
    final response = await _apiClient.post(
      ApiEndpoints.login,
      data: {'email': email, 'password': password},
    );

    if (response.data['success'] == true) {
      final data = response.data['data'] as Map<String, dynamic>;
      final user = AuthApiModel.fromJson(data);

      // Save to session
      await _userSessionService.saveUserSession(
        userId: user.id!,
        userEmail: user.email,
        username: user.username!,
      );

      // Save token
      final token = response.data['token'] as String;
      await _tokenService.saveToken(token);

      await _hiveService.init();
      await _hiveService.setActiveUser(user.id!);

      return user;
    }

    return null;
  }

  @override
  Future<bool> logout() {
    // TODO: implement logout
    throw UnimplementedError();
  }

  @override
  Future<List<AuthApiModel>> getAllUsers() async {
    final response = await _apiClient.get(ApiEndpoints.getAllUsers);

    if (response.data['success'] == true) {
      final data = response.data['data'] as List<dynamic>;
      final users = data.map((user) => AuthApiModel.fromJson(user)).toList();
      return users;
    }
    return [];
  }

  @override
  Future<AuthApiModel> register(AuthApiModel user) async {
    final response = await _apiClient.post(
      ApiEndpoints.register,
      data: user.toJson(),
    );

    if (response.data['success'] == true) {
      final data = response.data['data'] as Map<String, dynamic>;
      final registeredUser = AuthApiModel.fromJson(data);
      return registeredUser;
    }
    return user;
  }

  @override
  Future<bool> updateUser(AuthApiModel user) async {
    final data = <String, dynamic>{};
    if (user.username != null) data['username'] = user.username;
    if (user.password != null && user.password!.isNotEmpty) {
      data['password'] = user.password;
    }

    final response = await _apiClient.put(
      ApiEndpoints.updateProfile,
      data: data,
    );

    return response.data['success'] == true;
  }

  @override
  Future<String> uploadImage(File image) async {
    final fileName = image.path.split('/').last;
    final formData = FormData.fromMap({
      "image": await MultipartFile.fromFile(image.path, filename: fileName),
    });
    final response = await _apiClient.updateFile(
      ApiEndpoints.updateProfile,
      formData: formData,
    );

    return response.data['data'];
  }
}
