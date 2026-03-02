import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motion_ai/core/services/connectivity/network_info.dart';
import 'package:motion_ai/core/providers/providers.dart';
import 'package:motion_ai/feature/rag_chatbot/data/datasources/local/rag_chatbot_local_datasource.dart';
import 'package:motion_ai/feature/rag_chatbot/data/datasources/remote/rag_chatbot_remote_datasource.dart';
import 'package:motion_ai/feature/rag_chatbot/data/repositories/rag_chatbot_repository.dart';

import '../../domain/repositories/rag_chatbot_repository.dart';

final ragChatbotRepositoryProvider = Provider<IRagChatbotRepository>((ref) {
  return RagChatbotRepositoryImpl(
    local: ref.read(ragChatbotLocalDatasourceProvider),
    remote: ref.read(ragChatbotRemoteDatasourceProvider),
    networkInfo: ref.read(networkInfoProvider),
  );
});
