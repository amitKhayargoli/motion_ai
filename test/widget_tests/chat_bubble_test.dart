import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motion_ai/feature/rag_chatbot/presentation/widgets/chat_bubble.dart';

void main() {
  Widget buildChatBubble({
    String text = 'Hello world',
    bool isUser = true,
    bool pending = false,
    bool failed = false,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: ChatBubble(
          text: text,
          isUser: isUser,
          pending: pending,
          failed: failed,
        ),
      ),
    );
  }

  group('ChatBubble rendering', () {
    testWidgets('displays the message text', (tester) async {
      await tester.pumpWidget(buildChatBubble(text: 'Test message'));
      expect(find.text('Test message'), findsOneWidget);
    });

    testWidgets('shows "..." when text is empty', (tester) async {
      await tester.pumpWidget(buildChatBubble(text: ''));
      expect(find.text('...'), findsOneWidget);
    });
  });

  group('ChatBubble user messages', () {
    testWidgets('user bubble uses accent green background', (tester) async {
      await tester.pumpWidget(buildChatBubble(isUser: true));

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(ChatBubble),
          matching: find.byType(Container),
        ),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, const Color(0xFFAEFB2A));
    });

    testWidgets('user message text uses black color', (tester) async {
      await tester.pumpWidget(buildChatBubble(isUser: true, text: 'Hi'));

      final textWidget = tester.widget<Text>(find.text('Hi'));
      expect(textWidget.style?.color, Colors.black);
    });
  });

  group('ChatBubble assistant messages', () {
    testWidgets('assistant message text uses white color', (tester) async {
      await tester.pumpWidget(buildChatBubble(isUser: false, text: 'Response'));

      final textWidget = tester.widget<Text>(find.text('Response'));
      expect(textWidget.style?.color, Colors.white);
    });

    testWidgets('assistant bubble has border', (tester) async {
      await tester.pumpWidget(buildChatBubble(isUser: false));

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(ChatBubble),
          matching: find.byType(Container),
        ),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.border, isNotNull);
    });
  });

  group('ChatBubble pending state', () {
    testWidgets('shows "Sending…" for pending user message', (tester) async {
      await tester.pumpWidget(buildChatBubble(isUser: true, pending: true));
      expect(find.text('Sending…'), findsOneWidget);
    });

    testWidgets('does not show "Sending…" for non-pending message',
        (tester) async {
      await tester.pumpWidget(buildChatBubble(isUser: true, pending: false));
      expect(find.text('Sending…'), findsNothing);
    });

    testWidgets('does not show pending text for assistant messages',
        (tester) async {
      await tester.pumpWidget(buildChatBubble(isUser: false, pending: true));
      expect(find.text('Sending…'), findsNothing);
    });
  });

  group('ChatBubble failed state', () {
    testWidgets('shows "Tap to retry" for failed user message', (tester) async {
      await tester.pumpWidget(buildChatBubble(isUser: true, failed: true));
      expect(find.text('Tap to retry'), findsOneWidget);
    });

    testWidgets('does not show "Tap to retry" for non-failed message',
        (tester) async {
      await tester.pumpWidget(buildChatBubble(isUser: true, failed: false));
      expect(find.text('Tap to retry'), findsNothing);
    });

    testWidgets('does not show retry text for assistant messages',
        (tester) async {
      await tester.pumpWidget(buildChatBubble(isUser: false, failed: true));
      expect(find.text('Tap to retry'), findsNothing);
    });
  });
}
