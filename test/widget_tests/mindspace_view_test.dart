import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motion_ai/feature/rag_chatbot/domain/entities/chat_message_entity.dart';
import 'package:motion_ai/feature/rag_chatbot/presentation/pages/mindspace_view.dart';
import 'package:motion_ai/feature/rag_chatbot/presentation/view_model/rag_chatbot_view_model.dart';
import 'package:motion_ai/feature/rag_chatbot/presentation/state/rag_chatbot_state.dart';
import 'package:motion_ai/feature/rag_chatbot/presentation/widgets/chat_bubble.dart';
import 'package:motion_ai/feature/rag_chatbot/presentation/widgets/chat_typing_bubble.dart';
import 'package:motion_ai/feature/workspace/domain/entities/workspace_entity.dart';
import 'package:motion_ai/feature/workspace/presentation/view_model/workspace_view_model.dart';
import 'package:motion_ai/feature/workspace/presentation/state/workspace_state.dart';

// Configurable fake for RagChatbotViewModel
class FakeRagChatbotViewModel extends RagChatbotViewModel {
  final RagChatbotState _initialState;
  bool sendMessageCalled = false;
  bool startNewThreadCalled = false;
  bool clearChatCalled = false;

  FakeRagChatbotViewModel([RagChatbotState? initial])
      : _initialState = initial ?? RagChatbotState.initial();

  @override
  RagChatbotState build() => _initialState;

  @override
  Future<void> syncPendingMessages({
    required String workspaceId,
    required String threadId,
  }) async {}

  @override
  Future<void> sendMessageEnsureThread({
    required String workspaceId,
    required String message,
    String? threadId,
  }) async {
    sendMessageCalled = true;
  }

  @override
  Future<void> startNewThread({required String workspaceId}) async {
    startNewThreadCalled = true;
  }

  @override
  void clearChat() {
    clearChatCalled = true;
  }

  @override
  Future<void> resendMessage({
    required String workspaceId,
    required String threadId,
    required String messageId,
  }) async {}
}

class FakeWorkspaceViewModel extends WorkspaceViewModel {
  final WorkspaceState _initialState;

  FakeWorkspaceViewModel([WorkspaceState? initial])
      : _initialState = initial ?? WorkspaceState.initial();

  @override
  WorkspaceState build() => _initialState;
}

// Helper to create a workspace state with a selected workspace
WorkspaceState wsWithSelected() => WorkspaceState(
      isLoading: false,
      workspaces: [
        WorkspaceEntity(
          id: 'ws-1',
          name: 'Test Workspace',
          createdAt: DateTime(2025, 1, 1),
        ),
      ],
      selected: WorkspaceEntity(
        id: 'ws-1',
        name: 'Test Workspace',
        createdAt: DateTime(2025, 1, 1),
      ),
      error: null,
    );

void main() {
  Widget buildMindspaceView({
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
      child: const MaterialApp(home: MindspaceView()),
    );
  }

  group('MindspaceView rendering', () {
    testWidgets('displays MINDSPACE title', (tester) async {
      await tester.pumpWidget(buildMindspaceView());
      expect(find.textContaining('MINDSPACE'), findsOneWidget);
    });

    testWidgets('displays add thread button', (tester) async {
      await tester.pumpWidget(buildMindspaceView());
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('displays chat input field', (tester) async {
      await tester.pumpWidget(buildMindspaceView());
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('displays input placeholder text', (tester) async {
      await tester.pumpWidget(buildMindspaceView());
      expect(find.text('Ask MindSpace anything...'), findsOneWidget);
    });

    testWidgets('displays Add Context button', (tester) async {
      await tester.pumpWidget(buildMindspaceView());
      expect(find.text('Add Context'), findsOneWidget);
      expect(find.text('@'), findsOneWidget);
    });

    testWidgets('displays filter labels', (tester) async {
      final wsVm = FakeWorkspaceViewModel(wsWithSelected());
      await tester.pumpWidget(buildMindspaceView(wsVm: wsVm));
      expect(find.text('Source: '), findsOneWidget);
      expect(find.text('Test Workspace'), findsOneWidget);
    });

    testWidgets('displays chat history link', (tester) async {
      await tester.pumpWidget(buildMindspaceView());
      expect(find.text('MindSpace Chat History'), findsOneWidget);
      expect(find.byIcon(Icons.history), findsOneWidget);
    });
  });

  group('MindspaceView empty state', () {
    testWidgets(
        'shows empty state with "Chat with your notes" when no messages',
        (tester) async {
      await tester.pumpWidget(buildMindspaceView());
      expect(find.text('Chat with your notes'), findsOneWidget);
    });

    testWidgets('shows "Select a workspace first" when no workspace selected',
        (tester) async {
      await tester.pumpWidget(buildMindspaceView());
      expect(find.text('Select a workspace first'), findsOneWidget);
    });

    testWidgets(
        'shows "What can I help you discover?" when workspace is selected',
        (tester) async {
      final wsVm = FakeWorkspaceViewModel(wsWithSelected());
      await tester.pumpWidget(buildMindspaceView(wsVm: wsVm));

      expect(find.text('What can I help you discover?'), findsOneWidget);
      expect(find.text('Select a workspace first'), findsNothing);
    });
  });

  group('MindspaceView with messages', () {
    testWidgets('displays chat bubbles when messages exist', (tester) async {
      final stateWithMessages = RagChatbotState.initial().copyWith(
        messages: [
          const ChatMessageEntity(
            id: 'm-1',
            threadId: 't-1',
            role: 'user',
            content: 'Hello AI',
          ),
          const ChatMessageEntity(
            id: 'm-2',
            threadId: 't-1',
            role: 'assistant',
            content: 'Hi there!',
          ),
        ],
      );

      final ragVm = FakeRagChatbotViewModel(stateWithMessages);
      final wsVm = FakeWorkspaceViewModel(wsWithSelected());
      await tester.pumpWidget(buildMindspaceView(ragVm: ragVm, wsVm: wsVm));

      expect(find.byType(ChatBubble), findsNWidgets(2));
      expect(find.text('Hello AI'), findsOneWidget);
      expect(find.text('Hi there!'), findsOneWidget);
    });

    testWidgets('hides empty state when messages exist', (tester) async {
      final stateWithMessages = RagChatbotState.initial().copyWith(
        messages: [
          const ChatMessageEntity(
            id: 'm-1',
            threadId: 't-1',
            role: 'user',
            content: 'Test',
          ),
        ],
      );

      final ragVm = FakeRagChatbotViewModel(stateWithMessages);
      await tester.pumpWidget(buildMindspaceView(ragVm: ragVm));

      expect(find.text('Chat with your notes'), findsNothing);
    });

    testWidgets('shows typing indicator when assistant is typing',
        (tester) async {
      final stateWithTyping = RagChatbotState.initial().copyWith(
        assistantTyping: true,
        messages: [
          const ChatMessageEntity(
            id: 'm-1',
            threadId: 't-1',
            role: 'user',
            content: 'Hello',
          ),
        ],
      );

      final ragVm = FakeRagChatbotViewModel(stateWithTyping);
      await tester.pumpWidget(buildMindspaceView(ragVm: ragVm));
      await tester.pump();

      expect(find.byType(ChatTypingBubble), findsOneWidget);
    });

    testWidgets('shows pending status for unsent messages', (tester) async {
      final stateWithPending = RagChatbotState.initial().copyWith(
        messages: [
          const ChatMessageEntity(
            id: 'm-1',
            threadId: 't-1',
            role: 'user',
            content: 'Pending message',
            pending: true,
          ),
        ],
      );

      final ragVm = FakeRagChatbotViewModel(stateWithPending);
      await tester.pumpWidget(buildMindspaceView(ragVm: ragVm));

      expect(find.text('Sending…'), findsOneWidget);
    });

    testWidgets('shows retry text for failed messages', (tester) async {
      final stateWithFailed = RagChatbotState.initial().copyWith(
        messages: [
          const ChatMessageEntity(
            id: 'm-1',
            threadId: 't-1',
            role: 'user',
            content: 'Failed message',
            failed: true,
          ),
        ],
      );

      final ragVm = FakeRagChatbotViewModel(stateWithFailed);
      await tester.pumpWidget(buildMindspaceView(ragVm: ragVm));

      expect(find.text('Tap to retry'), findsOneWidget);
    });
  });

  group('MindspaceView sending state', () {
    testWidgets('shows spinner on send button when syncing', (tester) async {
      final syncingState = RagChatbotState.initial().copyWith(
        chatStatus: RagChatStatus.syncing,
      );

      final ragVm = FakeRagChatbotViewModel(syncingState);
      final wsVm = FakeWorkspaceViewModel(wsWithSelected());
      await tester.pumpWidget(buildMindspaceView(ragVm: ragVm, wsVm: wsVm));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('disables add thread button when syncing', (tester) async {
      final syncingState = RagChatbotState.initial().copyWith(
        chatStatus: RagChatStatus.syncing,
      );

      final ragVm = FakeRagChatbotViewModel(syncingState);
      await tester.pumpWidget(buildMindspaceView(ragVm: ragVm));

      final addButton = tester.widget<IconButton>(
        find.byType(IconButton).first,
      );
      expect(addButton.onPressed, isNull);
    });
  });

  group('MindspaceView interactions', () {
    testWidgets('can enter text in chat input', (tester) async {
      await tester.pumpWidget(buildMindspaceView());

      await tester.enterText(find.byType(TextField), 'My question');
      await tester.pumpAndSettle();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller!.text, 'My question');
    });
  });
}
