import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motion_ai/feature/rag_chatbot/domain/entities/chat_thread_entity.dart';
import 'package:motion_ai/feature/rag_chatbot/presentation/pages/thread_history_page.dart';
import 'package:motion_ai/feature/rag_chatbot/presentation/state/rag_chatbot_state.dart';
import 'package:motion_ai/feature/rag_chatbot/presentation/view_model/rag_chatbot_view_model.dart';
import 'package:motion_ai/feature/workspace/domain/entities/workspace_entity.dart';
import 'package:motion_ai/feature/workspace/presentation/state/workspace_state.dart';
import 'package:motion_ai/feature/workspace/presentation/view_model/workspace_view_model.dart';

// ---- Fakes ----

class FakeRagChatbotViewModel extends RagChatbotViewModel {
  final RagChatbotState _initialState;

  FakeRagChatbotViewModel([RagChatbotState? initial])
      : _initialState = initial ?? RagChatbotState.initial();

  @override
  RagChatbotState build() => _initialState;

  @override
  Future<void> fetchThreads({required String workspaceId}) async {}

  @override
  Future<void> deleteThread({
    required String workspaceId,
    required String threadId,
  }) async {}

  @override
  Future<void> deleteThreads({
    required String workspaceId,
    required List<String> threadIds,
  }) async {}

  @override
  Future<void> updateThreadTitle({
    required String workspaceId,
    required String threadId,
    required String title,
  }) async {}
}

class FakeWorkspaceViewModel extends WorkspaceViewModel {
  final WorkspaceState _initialState;
  FakeWorkspaceViewModel([WorkspaceState? initial])
      : _initialState = initial ?? WorkspaceState.initial();

  @override
  WorkspaceState build() => _initialState;
}

// ---- Test data ----

final tWorkspace = WorkspaceEntity(
  id: 'ws-1',
  name: 'Test Workspace',
  createdAt: DateTime(2025, 1, 1),
);

WorkspaceState wsWithSelected() => WorkspaceState(
      isLoading: false,
      workspaces: [tWorkspace],
      selected: tWorkspace,
      error: null,
    );

final tThread1 = ChatThreadEntity(
  id: 'thread-1',
  workspaceId: 'ws-1',
  userId: 'user-1',
  title: 'First Chat',
  createdAt: DateTime(2025, 1, 1),
  updatedAt: DateTime(2025, 1, 1),
  messages: const [],
);

final tThread2 = ChatThreadEntity(
  id: 'thread-2',
  workspaceId: 'ws-1',
  userId: 'user-1',
  title: 'Second Chat',
  createdAt: DateTime(2025, 2, 1),
  updatedAt: DateTime(2025, 2, 1),
  messages: const [],
);

RagChatbotState stateWithThreads() => RagChatbotState.initial().copyWith(
      status: RagChatbotStatus.ready,
      threads: [tThread1, tThread2],
    );

// ---- Helpers ----

void main() {
  Widget buildThreadHistoryPage({
    FakeRagChatbotViewModel? ragVm,
    FakeWorkspaceViewModel? wsVm,
  }) {
    return ProviderScope(
      overrides: [
        ragChatbotViewModelProvider
            .overrideWith(() => ragVm ?? FakeRagChatbotViewModel()),
        workspaceViewModelProvider
            .overrideWith(() => wsVm ?? FakeWorkspaceViewModel()),
      ],
      child: const MaterialApp(home: ThreadHistoryPage()),
    );
  }

  group('ThreadHistoryPage rendering', () {
    testWidgets('displays CHAT HISTORY title', (tester) async {
      final wsVm = FakeWorkspaceViewModel(wsWithSelected());
      await tester.pumpWidget(buildThreadHistoryPage(wsVm: wsVm));

      expect(find.text('CHAT HISTORY'), findsOneWidget);
    });

    testWidgets('displays back button', (tester) async {
      final wsVm = FakeWorkspaceViewModel(wsWithSelected());
      await tester.pumpWidget(buildThreadHistoryPage(wsVm: wsVm));

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });
  });

  group('ThreadHistoryPage empty/no-workspace states', () {
    testWidgets('shows "Select a workspace first" when no workspace selected',
        (tester) async {
      await tester.pumpWidget(buildThreadHistoryPage());
      expect(find.text('Select a workspace first'), findsOneWidget);
    });

    testWidgets('shows "No chats yet" when workspace selected but no threads',
        (tester) async {
      final wsVm = FakeWorkspaceViewModel(wsWithSelected());
      final ragVm = FakeRagChatbotViewModel(
        RagChatbotState.initial().copyWith(
          status: RagChatbotStatus.ready,
          threads: const [],
        ),
      );

      await tester.pumpWidget(
        buildThreadHistoryPage(wsVm: wsVm, ragVm: ragVm),
      );
      expect(find.text('No chats yet'), findsOneWidget);
    });

    testWidgets('shows loading spinner when status is loading', (tester) async {
      final wsVm = FakeWorkspaceViewModel(wsWithSelected());
      final ragVm = FakeRagChatbotViewModel(
        RagChatbotState.initial().copyWith(status: RagChatbotStatus.loading),
      );

      await tester.pumpWidget(
        buildThreadHistoryPage(wsVm: wsVm, ragVm: ragVm),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error message when status is error and no threads',
        (tester) async {
      final wsVm = FakeWorkspaceViewModel(wsWithSelected());
      final ragVm = FakeRagChatbotViewModel(
        RagChatbotState.initial().copyWith(
          status: RagChatbotStatus.error,
          error: 'Network error',
        ),
      );

      await tester.pumpWidget(
        buildThreadHistoryPage(wsVm: wsVm, ragVm: ragVm),
      );
      expect(find.text('Network error'), findsOneWidget);
    });
  });

  group('ThreadHistoryPage with threads', () {
    testWidgets('displays thread titles', (tester) async {
      final wsVm = FakeWorkspaceViewModel(wsWithSelected());
      final ragVm = FakeRagChatbotViewModel(stateWithThreads());

      await tester.pumpWidget(
        buildThreadHistoryPage(wsVm: wsVm, ragVm: ragVm),
      );

      expect(find.text('First Chat'), findsOneWidget);
      expect(find.text('Second Chat'), findsOneWidget);
    });

    testWidgets('displays chat bubble icons for each thread', (tester) async {
      final wsVm = FakeWorkspaceViewModel(wsWithSelected());
      final ragVm = FakeRagChatbotViewModel(stateWithThreads());

      await tester.pumpWidget(
        buildThreadHistoryPage(wsVm: wsVm, ragVm: ragVm),
      );

      expect(find.byIcon(Icons.chat_bubble_outline), findsNWidgets(2));
    });

    testWidgets('displays edit icons for each thread', (tester) async {
      final wsVm = FakeWorkspaceViewModel(wsWithSelected());
      final ragVm = FakeRagChatbotViewModel(stateWithThreads());

      await tester.pumpWidget(
        buildThreadHistoryPage(wsVm: wsVm, ragVm: ragVm),
      );

      expect(find.byIcon(Icons.edit_outlined), findsNWidgets(2));
    });

    testWidgets('displays formatted timestamps', (tester) async {
      final wsVm = FakeWorkspaceViewModel(wsWithSelected());
      final ragVm = FakeRagChatbotViewModel(stateWithThreads());

      await tester.pumpWidget(
        buildThreadHistoryPage(wsVm: wsVm, ragVm: ragVm),
      );

      expect(find.textContaining('01 Jan 2025'), findsOneWidget);
      expect(find.textContaining('01 Feb 2025'), findsOneWidget);
    });
  });

  group('ThreadHistoryPage selection mode', () {
    testWidgets('long press enters selection mode', (tester) async {
      final wsVm = FakeWorkspaceViewModel(wsWithSelected());
      final ragVm = FakeRagChatbotViewModel(stateWithThreads());

      await tester.pumpWidget(
        buildThreadHistoryPage(wsVm: wsVm, ragVm: ragVm),
      );

      await tester.longPress(find.text('First Chat'));
      await tester.pumpAndSettle();

      expect(find.text('1 selected'), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });

    testWidgets('tapping another thread in selection mode selects it',
        (tester) async {
      final wsVm = FakeWorkspaceViewModel(wsWithSelected());
      final ragVm = FakeRagChatbotViewModel(stateWithThreads());

      await tester.pumpWidget(
        buildThreadHistoryPage(wsVm: wsVm, ragVm: ragVm),
      );

      await tester.longPress(find.text('First Chat'));
      await tester.pumpAndSettle();
      expect(find.text('1 selected'), findsOneWidget);

      await tester.tap(find.text('Second Chat'));
      await tester.pumpAndSettle();
      expect(find.text('2 selected'), findsOneWidget);
    });

    testWidgets('close button exits selection mode', (tester) async {
      final wsVm = FakeWorkspaceViewModel(wsWithSelected());
      final ragVm = FakeRagChatbotViewModel(stateWithThreads());

      await tester.pumpWidget(
        buildThreadHistoryPage(wsVm: wsVm, ragVm: ragVm),
      );

      await tester.longPress(find.text('First Chat'));
      await tester.pumpAndSettle();
      expect(find.text('1 selected'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('1 selected'), findsNothing);
      expect(find.text('CHAT HISTORY'), findsOneWidget);
    });

    testWidgets('selected thread shows check icon instead of chat icon',
        (tester) async {
      final wsVm = FakeWorkspaceViewModel(wsWithSelected());
      final ragVm = FakeRagChatbotViewModel(stateWithThreads());

      await tester.pumpWidget(
        buildThreadHistoryPage(wsVm: wsVm, ragVm: ragVm),
      );

      // Before selection: 2 chat_bubble_outline, 0 check
      expect(find.byIcon(Icons.chat_bubble_outline), findsNWidgets(2));
      expect(find.byIcon(Icons.check), findsNothing);

      await tester.longPress(find.text('First Chat'));
      await tester.pumpAndSettle();

      // After selection: 1 chat_bubble_outline, 1 check
      expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });
  });
}
