import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motion_ai/core/services/connectivity/network_info.dart';
import 'package:motion_ai/feature/tasks/data/datasources/local/task_local_datasource.dart';
import 'package:motion_ai/feature/tasks/data/datasources/remote/task_remote_datasource.dart';
import 'package:motion_ai/feature/tasks/data/repositories/task_repository.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final local = ref.read(taskLocalDatasourceProvider);
  final remote = ref.read(taskRemoteDatasourceProvider);
  final networkInfo = ref.read(networkInfoProvider);

  return TaskRepository(local: local, remote: remote, networkInfo: networkInfo);
});
