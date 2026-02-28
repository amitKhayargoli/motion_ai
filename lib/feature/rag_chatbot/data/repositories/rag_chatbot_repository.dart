import 'dart:async';
import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:hive/hive.dart';
import 'package:motion_ai/core/error/failures.dart';
import 'package:motion_ai/core/services/connectivity/network_info.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/chat_message_entity.dart';
import '../../domain/entities/chat_thread_entity.dart';
import '../../domain/repositories/rag_chatbot_repository.dart';
import '../datasources/rag_chatbot_datasource.dart';
import '../models/chat_message_hive_model.dart';
import '../models/chat_thread_hive_model.dart';

class RagChatbotRepositoryImpl implements IRagChatbotRepository {
  final IRagChatbotLocalDataSource local;
  final IRagChatbotRemoteDataSource remote;
  final NetworkInfo networkInfo;

  RagChatbotRepositoryImpl({
    required this.local,
    required this.remote,
    required this.networkInfo,
  });

  static const _threadIdMapBox = "rag_thread_id_map"; // localId -> serverId

  Future<Box> _openThreadIdMap() => Hive.openBox(_threadIdMapBox);

  /// Resolves a local thread ID to its server ID if a mapping exists.
  Future<String> _resolveThreadId(String threadId) async {
    if (!threadId.startsWith("local_")) return threadId;
    final map = await _openThreadIdMap();
    return map.get(threadId)?.toString() ?? threadId;
  }

  /// Ensures a thread entity has a non-empty workspaceId.
  /// API responses may omit workspaceId — use the known value as fallback.
  ChatThreadEntity _withWorkspaceId(
      ChatThreadEntity entity, String workspaceId) {
    if (entity.workspaceId.isNotEmpty) return entity;
    return ChatThreadEntity(
      id: entity.id,
      workspaceId: workspaceId,
      userId: entity.userId,
      title: entity.title,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      messages: entity.messages,
    );
  }

  // ---------------- CREATE THREAD (local first) ----------------
  @override
  Future<Either<Failure, ChatThreadEntity>> createThread({
    required String workspaceId,
    String? title,
  }) async {
    try {
      final now = DateTime.now();
      final localId = "local_${const Uuid().v4()}";

      // 1) Create locally immediately
      final localEntity = ChatThreadEntity(
        id: localId,
        workspaceId: workspaceId,
        userId: '',
        title: title ?? 'New chat',
        createdAt: now,
        updatedAt: now,
        messages: const [],
      );
      await local.upsertThread(ChatThreadHiveModel.fromEntity(localEntity));

      // 2) Try remote
      final online = await networkInfo.isConnected;
      if (!online) return Right(localEntity);

      try {
        final api =
            await remote.createThread(workspaceId: workspaceId, title: title);
        final serverEntity = _withWorkspaceId(api.toEntity(), workspaceId);

        // Map local -> server
        final map = await _openThreadIdMap();
        await map.put(localId, serverEntity.id);

        // Replace local with server thread
        await local.deleteThread(localId);
        await local.upsertThread(ChatThreadHiveModel.fromEntity(serverEntity));
        if (serverEntity.messages.isNotEmpty) {
          await local.upsertMessages(
            serverEntity.id,
            serverEntity.messages.map(ChatMessageHiveModel.fromEntity).toList(),
          );
        }

        return Right(serverEntity);
      } catch (_) {
        // Remote failed – keep local thread
        return Right(localEntity);
      }
    } catch (e) {
      return Left(LocalDatabaseFailure(message: e.toString()));
    }
  }

  // ---------------- LIST THREADS (local first) ----------------
  @override
  Future<Either<Failure, List<ChatThreadEntity>>> listThreads({
    required String workspaceId,
  }) async {
    try {
      final cached = await local.getThreadsByWorkspace(workspaceId);
      final localEntities = cached.map((h) => h.toEntity()).toList()
        ..sort((a, b) {
          final ad = a.updatedAt ?? a.createdAt ?? DateTime(0);
          final bd = b.updatedAt ?? b.createdAt ?? DateTime(0);
          return bd.compareTo(ad);
        });

      final online = await networkInfo.isConnected;
      if (!online) return Right(localEntities);

      try {
        // Flush any pending title updates to server before fetching
        final pendingTitles = await local.getAllPendingTitleUpdates();
        for (final entry in pendingTitles.entries) {
          try {
            await remote.updateThreadTitle(
                threadId: entry.key, title: entry.value);
            await local.clearPendingTitleUpdate(entry.key);
          } catch (_) {
            // keep in queue for next sync
          }
        }

        final api = await remote.listThreads(workspaceId: workspaceId);
        final entities =
            api.map((m) => _withWorkspaceId(m.toEntity(), workspaceId)).toList()
              ..sort((a, b) {
                final ad = a.updatedAt ?? a.createdAt ?? DateTime(0);
                final bd = b.updatedAt ?? b.createdAt ?? DateTime(0);
                return bd.compareTo(ad);
              });

        await local.upsertThreads(
          entities.map(ChatThreadHiveModel.fromEntity).toList(),
        );

        // Keep local-only threads that haven't been synced yet
        final serverIds = entities.map((e) => e.id).toSet();
        final localOnly = localEntities
            .where(
                (e) => e.id.startsWith("local_") && !serverIds.contains(e.id))
            .toList();

        // Prune stale threads: previously synced but no longer on the server
        for (final stale in localEntities) {
          if (!stale.id.startsWith("local_") &&
              !serverIds.contains(stale.id)) {
            await local.deleteThread(stale.id);
            await local.clearMessages(stale.id);
            await local.clearPendingMessages(stale.id);
          }
        }

        return Right([...localOnly, ...entities]);
      } catch (_) {
        return Right(localEntities);
      }
    } catch (e) {
      return Left(LocalDatabaseFailure(message: e.toString()));
    }
  }

  // ---------------- GET THREAD (local first, resolves IDs) ----------------
  @override
  Future<Either<Failure, ChatThreadEntity>> getThread({
    required String threadId,
  }) async {
    try {
      // Resolve local ID to server ID if mapped
      final resolvedId = await _resolveThreadId(threadId);

      final cachedThread = await local.getThreadById(resolvedId);
      final cachedMsgs = await local.getMessages(resolvedId);

      ChatThreadEntity? localEntity;
      if (cachedThread != null) {
        final base = cachedThread.toEntity();
        localEntity = ChatThreadEntity(
          id: base.id,
          workspaceId: base.workspaceId,
          userId: base.userId,
          title: base.title,
          createdAt: base.createdAt,
          updatedAt: base.updatedAt,
          messages: cachedMsgs.map((m) => m.toEntity()).toList(),
        );
      }

      final online = await networkInfo.isConnected;
      if (!online || resolvedId.startsWith("local_")) {
        if (localEntity != null) return Right(localEntity);
        return const Left(
            NetworkFailure(message: "Thread not available offline"));
      }

      try {
        final api = await remote.getThread(threadId: resolvedId);
        final rawEntity = api.toEntity();

        // Preserve workspaceId from cache if API didn't return it
        final fallbackWsId = localEntity?.workspaceId ?? '';
        final entity = _withWorkspaceId(rawEntity, fallbackWsId);

        await local.upsertThread(ChatThreadHiveModel.fromEntity(entity));
        await local.upsertMessages(
          entity.id,
          entity.messages.map(ChatMessageHiveModel.fromEntity).toList(),
        );

        return Right(entity);
      } catch (_) {
        if (localEntity != null) return Right(localEntity);
        return const Left(ApiFailure(message: "Failed to load thread"));
      }
    } catch (e) {
      return Left(LocalDatabaseFailure(message: e.toString()));
    }
  }

  // ---------------- DELETE THREAD (local first, resolves IDs) ----------------
  @override
  Future<Either<Failure, bool>> deleteThread({
    required String threadId,
  }) async {
    try {
      final resolvedId = await _resolveThreadId(threadId);

      // Clean up both local and resolved entries
      await local.deleteThread(threadId);
      await local.clearMessages(threadId);
      await local.clearPendingMessages(threadId);
      if (resolvedId != threadId) {
        await local.deleteThread(resolvedId);
        await local.clearMessages(resolvedId);
        await local.clearPendingMessages(resolvedId);

        // Remove mapping
        final map = await _openThreadIdMap();
        await map.delete(threadId);
      }

      // If it was local-only, nothing to delete on server
      if (resolvedId.startsWith("local_")) return const Right(true);

      final online = await networkInfo.isConnected;
      if (!online) return const Right(true);

      try {
        await remote.deleteThread(threadId: resolvedId);
      } catch (_) {
        // best-effort
      }
      return const Right(true);
    } catch (e) {
      return Left(LocalDatabaseFailure(message: e.toString()));
    }
  }

  // ---------------- CHAT (local-first + offline queue) ----------------
  @override
  Future<Either<Failure, List<ChatMessageEntity>>> chat({
    required String workspaceId,
    required String threadId,
    required String message,
  }) async {
    try {
      final now = DateTime.now();

      if (message.trim().isEmpty) {
        return const Left(ApiFailure(message: "Message is empty"));
      }

      // 1) Write user message locally immediately (pending)
      final localUserEntity = ChatMessageEntity(
        id: "local_${const Uuid().v4()}",
        threadId: threadId,
        role: "user",
        content: message,
        createdAt: now,
        pending: true,
        failed: false,
      );

      final currentHive = await local.getMessages(threadId);
      final currentEntities = currentHive.map((m) => m.toEntity()).toList();
      final nextEntities = [...currentEntities, localUserEntity];

      await local.upsertMessages(
        threadId,
        nextEntities.map(ChatMessageHiveModel.fromEntity).toList(),
      );

      // Always enqueue so it can retry on failure too
      await local.enqueuePendingMessage(
        workspaceId: workspaceId,
        threadId: threadId,
        message: ChatMessageHiveModel.fromEntity(localUserEntity),
      );

      // 2) If offline -> return local (pending stays queued)
      final online = await networkInfo.isConnected;
      if (!online) {
        return Right(nextEntities);
      }

      // 3) Online -> flush pending (includes the message we just enqueued)
      final syncRes = await syncPendingMessages(
          workspaceId: workspaceId, threadId: threadId);

      // After sync, read from the resolved thread ID (may have changed)
      final resolvedId = await _resolveThreadId(threadId);
      final hive = await local.getMessages(resolvedId);

      // Stamp the resolved threadId on all messages so the VM can
      // reliably extract it (API responses may omit threadId).
      final resolvedMsgs = hive.map((m) {
        final e = m.toEntity();
        return ChatMessageEntity(
          id: e.id,
          threadId: resolvedId,
          role: e.role,
          content: e.content,
          createdAt: e.createdAt,
          pending: e.pending,
          failed: e.failed,
          kind: e.kind,
          notes: e.notes,
        );
      }).toList();

      return syncRes.fold(
        (_) async => Right(resolvedMsgs),
        (_) async => Right(resolvedMsgs),
      );
    } catch (e) {
      return Left(ApiFailure(message: e.toString()));
    }
  }

  // ---------------- SYNC PENDING MESSAGES ----------------
  @override
  Future<Either<Failure, bool>> syncPendingMessages({
    required String workspaceId,
    required String threadId,
  }) async {
    final online = await networkInfo.isConnected;
    if (!online) return const Right(false);

    try {
      String resolvedId = await _resolveThreadId(threadId);

      // If the thread is still local-only, create it on the server first
      if (resolvedId.startsWith("local_")) {
        try {
          final api =
              await remote.createThread(workspaceId: workspaceId, title: null);
          final serverEntity = _withWorkspaceId(api.toEntity(), workspaceId);
          resolvedId = serverEntity.id;

          // Store mapping
          final map = await _openThreadIdMap();
          await map.put(threadId, resolvedId);

          // Replace local thread in cache
          await local.deleteThread(threadId);
          await local
              .upsertThread(ChatThreadHiveModel.fromEntity(serverEntity));

          // Move cached messages to server thread ID
          final cachedMsgs = await local.getMessages(threadId);
          if (cachedMsgs.isNotEmpty) {
            await local.upsertMessages(resolvedId, cachedMsgs);
            await local.clearMessages(threadId);
          }
        } catch (e) {
          // Can't create thread on server yet – keep pending
          return Left(ApiFailure(message: e.toString()));
        }
      }

      // Flush pending messages — capture each response to preserve full answer + notes
      final pending = await local.getPendingMessages(threadId);
      final chatResponses = <_ChatResponseMeta>[];

      for (final m in pending) {
        if (m.role != "user") continue;
        if (m.content.trim().isEmpty) continue;

        final response = await remote.chat(
          workspaceId: workspaceId,
          threadId: resolvedId,
          question: m.content,
        );
        chatResponses.add(_ChatResponseMeta(
          answer: response.answer,
          kind: response.kind,
          notesJson: response.notes.isNotEmpty
              ? jsonEncode(
                  response.notes
                      .map((n) => {"id": n.id, "title": n.title})
                      .toList(),
                )
              : null,
        ));
      }

      if (pending.isNotEmpty) {
        await local.clearPendingMessages(threadId);
      }

      // Flush pending title updates before fetching remote
      final pendingTitle = await local.getPendingTitleUpdate(resolvedId);
      if (pendingTitle != null) {
        try {
          await remote.updateThreadTitle(
              threadId: resolvedId, title: pendingTitle);
          await local.clearPendingTitleUpdate(resolvedId);
        } catch (_) {
          // keep in queue for next sync
        }
      }

      // Refresh thread from server to get the full conversation
      final apiThread = await remote.getThread(threadId: resolvedId);
      final entity = _withWorkspaceId(apiThread.toEntity(), workspaceId);

      // Merge captured notes onto the last N assistant messages
      List<ChatMessageHiveModel> hiveMessages =
          entity.messages.map(ChatMessageHiveModel.fromEntity).toList();

      if (chatResponses.isNotEmpty) {
        final assistantIndices = hiveMessages
            .asMap()
            .entries
            .where((e) => e.value.role == "assistant")
            .map((e) => e.key)
            .toList();

        for (int i = 0; i < chatResponses.length; i++) {
          final msgIdx = assistantIndices.length - chatResponses.length + i;
          if (msgIdx >= 0 && msgIdx < assistantIndices.length) {
            final idx = assistantIndices[msgIdx];
            hiveMessages[idx] = hiveMessages[idx].copyWith(
              // Use the answer from /chat directly — getThread may store
              // a truncated or different content field.
              content: chatResponses[i].answer.isNotEmpty
                  ? chatResponses[i].answer
                  : null,
              notesJson: chatResponses[i].notesJson,
              kind: chatResponses[i].kind.isNotEmpty
                  ? chatResponses[i].kind
                  : null,
            );
          }
        }
      }

      await local.upsertThread(ChatThreadHiveModel.fromEntity(entity));
      await local.upsertMessages(resolvedId, hiveMessages);

      return const Right(true);
    } catch (e) {
      // Keep pending queue as-is so it can retry later
      return Left(ApiFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> updateThreadTitle({
    required String threadId,
    required String title,
  }) async {
    try {
      final resolvedId = await _resolveThreadId(threadId);
      final cached = await local.getThreadById(resolvedId);
      if (cached == null) {
        return const Left(
            LocalDatabaseFailure(message: "Thread not found locally"));
      }

      final updated = cached.copyWith(
        title: title,
        updatedAt: DateTime.now(),
      );
      await local.upsertThread(updated);

      // If it was local-only, nothing to update on server
      if (resolvedId.startsWith("local_")) return const Right(true);

      // Enqueue so it can be retried on reconnect
      await local.enqueuePendingTitleUpdate(
        threadId: resolvedId,
        title: title,
      );

      final online = await networkInfo.isConnected;
      if (!online) return const Right(true);

      try {
        await remote.updateThreadTitle(threadId: resolvedId, title: title);
        await local.clearPendingTitleUpdate(resolvedId);
      } catch (_) {
        // stays in queue for next sync
      }

      return const Right(true);
    } catch (e) {
      return Left(LocalDatabaseFailure(message: e.toString()));
    }
  }
}

/// Helper to carry the full answer + metadata captured from a chat response.
class _ChatResponseMeta {
  final String answer;
  final String kind;
  final String? notesJson;
  const _ChatResponseMeta({
    required this.answer,
    required this.kind,
    this.notesJson,
  });
}
