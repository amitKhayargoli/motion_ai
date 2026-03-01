import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motion_ai/feature/rag_chatbot/presentation/widgets/chat_typing_bubble.dart';

void main() {
  Widget buildTypingBubble() {
    return const MaterialApp(
      home: Scaffold(body: ChatTypingBubble()),
    );
  }

  group('ChatTypingBubble rendering', () {
    testWidgets('renders the widget', (tester) async {
      await tester.pumpWidget(buildTypingBubble());
      expect(find.byType(ChatTypingBubble), findsOneWidget);
    });

    testWidgets('displays text starting with "Typing"', (tester) async {
      await tester.pumpWidget(buildTypingBubble());
      // Pump a frame to let the animation produce text
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('Typing'), findsOneWidget);
    });

    testWidgets('is aligned to the left (assistant side)', (tester) async {
      await tester.pumpWidget(buildTypingBubble());

      final align = tester.widget<Align>(find.byType(Align));
      expect(align.alignment, Alignment.centerLeft);
    });

    testWidgets('animates dots over time', (tester) async {
      await tester.pumpWidget(buildTypingBubble());

      // Collect different text states over multiple frames
      final texts = <String>{};
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 200));
        final finder = find.textContaining('Typing');
        if (finder.evaluate().isNotEmpty) {
          final textWidget = tester.widget<Text>(finder);
          texts.add(textWidget.data ?? '');
        }
      }

      // We should see varying dot counts (Typing., Typing.., Typing...)
      expect(texts.length, greaterThan(1));
    });

    testWidgets('has rounded container decoration', (tester) async {
      await tester.pumpWidget(buildTypingBubble());

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(ChatTypingBubble),
          matching: find.byType(Container),
        ),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(18));
    });
  });
}
