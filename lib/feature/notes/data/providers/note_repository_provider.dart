import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motion_ai/core/providers/providers.dart';
import 'package:motion_ai/core/services/connectivity/network_info.dart';
import 'package:motion_ai/feature/notes/data/datasources/local/note_local_datasource.dart';
import 'package:motion_ai/feature/notes/data/datasources/remote/note_remote_datasource.dart';
import 'package:motion_ai/feature/notes/data/repositories/note_repository.dart';

final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  final local = ref.read(noteLocalDatasourceProvider);
  final remote = ref.read(noteRemoteDatasourceProvider);
  final networkInfo = ref.read(networkInfoProvider);

  return NoteRepository(local: local, remote: remote, networkInfo: networkInfo);
});
