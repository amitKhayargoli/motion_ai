import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motion_ai/feature/home/presentation/pages/widgets/gradient_scaffold_widget.dart';

void main() {
  group('GradientScaffold rendering', () {
    testWidgets('renders the body widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: GradientScaffold(
            body: Text('Hello Body'),
          ),
        ),
      );

      expect(find.text('Hello Body'), findsOneWidget);
    });

    testWidgets('renders with an appBar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: GradientScaffold(
            appBar: AppBar(title: const Text('Test Title')),
            body: const SizedBox(),
          ),
        ),
      );

      expect(find.text('Test Title'), findsOneWidget);
    });

    testWidgets('renders with a bottomNavigationBar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: GradientScaffold(
            bottomNavigationBar: BottomAppBar(
              child: const Text('Bottom Bar'),
            ),
            body: const SizedBox(),
          ),
        ),
      );

      expect(find.text('Bottom Bar'), findsOneWidget);
    });

    testWidgets('contains a Scaffold with transparent background',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: GradientScaffold(body: SizedBox()),
        ),
      );

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).last);
      expect(scaffold.backgroundColor, Colors.transparent);
    });

    testWidgets('defaults to onboarding gradient', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: GradientScaffold(body: SizedBox()),
        ),
      );

      // Find the outer Container that holds the gradient
      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.gradient, isA<LinearGradient>());
    });

    testWidgets('uses radial gradient when useDashboardGradient is true',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: GradientScaffold(
            useDashboardGradient: true,
            body: SizedBox(),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.gradient, isA<RadialGradient>());
    });

    testWidgets('extendBodyBehindAppBar defaults to true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: GradientScaffold(body: SizedBox()),
        ),
      );

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).last);
      expect(scaffold.extendBodyBehindAppBar, true);
    });

    testWidgets('extendBody defaults to false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: GradientScaffold(body: SizedBox()),
        ),
      );

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).last);
      expect(scaffold.extendBody, false);
    });

    testWidgets('extendBody can be set to true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: GradientScaffold(extendBody: true, body: SizedBox()),
        ),
      );

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).last);
      expect(scaffold.extendBody, true);
    });
  });
}
