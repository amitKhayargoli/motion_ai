import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motion_ai/core/api/api_client.dart';
import 'package:motion_ai/core/providers/providers.dart';
import 'package:motion_ai/core/services/hive/hive_service.dart';
import 'package:motion_ai/core/services/storage/user_session_service.dart';
import 'package:motion_ai/feature/auth/data/datasources/auth_datasource.dart';
import 'package:motion_ai/feature/auth/data/datasources/local/auth_local_datasource.dart';
import 'package:motion_ai/feature/auth/data/datasources/remote/auth_remote_datasource.dart';
import 'package:motion_ai/feature/auth/data/repositories/auth_repository.dart';
import 'package:motion_ai/core/services/connectivity/network_info.dart';
import 'package:motion_ai/feature/auth/domain/repositories/auth_repository.dart';

final authLocalDatasourceProvider = Provider<IAuthLocalDataSource>((ref) {
  final HiveService hive = ref.read(hiveServiceProvider);
  final UserSessionService session = ref.read(userSessionServiceProvider);

  return AuthLocalDatasource(hiveService: hive, userSessionService: session);
});

final authRemoteDatasourceProvider = Provider<IAuthRemoteDataSource>((ref) {
  return AuthRemoteDatasource(
    apiClient: ref.read(apiClientProvider),
    userSessionService: ref.read(userSessionServiceProvider),
    tokenService: ref.read(tokenServiceProvider),
    hiveService: ref.read(hiveServiceProvider),
  );
});

final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  return AuthRepository(
    authDatasource: ref.read(authLocalDatasourceProvider),
    authRemoteDataSource: ref.read(authRemoteDatasourceProvider),
    networkInfo: ref.read(networkInfoProvider),
  );
});
