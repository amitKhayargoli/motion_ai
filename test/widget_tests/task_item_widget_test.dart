import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motion_ai/feature/home/presentation/pages/widgets/task_item_widget.dart';

void main() {
  Widget buildTaskItem({
    String task = 'Buy groceries',
    bool isCompleted = false,
    VoidCallback? onTap,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: TaskItemWidget(
          task: task,
          isCompleted: isCompleted,
          onTap: onTap,
        ),
      ),
    );
  }

  group('TaskItemWidget rendering', () {
    testWidgets('displays the task text', (tester) async {
      await tester.pumpWidget(buildTaskItem(task: 'Write unit tests'));
      expect(find.text('Write unit tests'), findsOneWidget);
    });

    testWidgets('displays long task text with ellipsis overflow',
        (tester) async {
      await tester.pumpWidget(buildTaskItem(
        task: 'This is a very long task description that should overflow',
      ));
      final textWidget = tester.widget<Text>(find.text(
        'This is a very long task description that should overflow',
      ));
      expect(textWidget.overflow, TextOverflow.ellipsis);
    });
  });

  group('TaskItemWidget uncompleted state', () {
    testWidgets('shows empty circle when not completed', (tester) async {
      await tester.pumpWidget(buildTaskItem(isCompleted: false));

      // Should NOT have the check icon
      expect(find.byIcon(Icons.check), findsNothing);
    });

    testWidgets('text has no line-through decoration when not completed',
        (tester) async {
      await tester.pumpWidget(buildTaskItem(isCompleted: false));

      final text = tester.widget<Text>(find.text('Buy groceries'));
      expect(text.style?.decoration, isNull);
    });
  });

  group('TaskItemWidget completed state', () {
    testWidgets('shows check icon when completed', (tester) async {
      await tester.pumpWidget(buildTaskItem(isCompleted: true));
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('text has line-through decoration when completed',
        (tester) async {
      await tester
          .pumpWidget(buildTaskItem(isCompleted: true, task: 'Done task'));

      final text = tester.widget<Text>(find.text('Done task'));
      expect(text.style?.decoration, TextDecoration.lineThrough);
    });
  });

  group('TaskItemWidget interactions', () {
    testWidgets('tapping calls onTap callback', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        buildTaskItem(onTap: () => tapped = true),
      );

      await tester.tap(find.byType(GestureDetector));
      expect(tapped, true);
    });

    testWidgets('works without onTap callback (null safe)', (tester) async {
      await tester.pumpWidget(buildTaskItem(onTap: null));

      // Should not throw when tapped
      await tester.tap(find.byType(GestureDetector));
      await tester.pump();
    });
  });
}
