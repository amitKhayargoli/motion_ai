import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motion_ai/feature/workspace/domain/entities/workspace_entity.dart';
import 'package:motion_ai/feature/workspace/presentation/pages/workspace_onboarding_page.dart';
import 'package:motion_ai/feature/workspace/presentation/state/workspace_state.dart';
import 'package:motion_ai/feature/workspace/presentation/view_model/workspace_view_model.dart';

// ---- Fakes ----

class FakeWorkspaceViewModel extends WorkspaceViewModel {
  final WorkspaceState _initialState;
  bool createWorkspaceCalled = false;
  String? lastCreatedName;
  bool joinByInviteLinkCalled = false;
  String? lastInviteLink;
  bool createShouldFail = false;
  bool joinShouldFail = false;

  FakeWorkspaceViewModel([WorkspaceState? initial])
      : _initialState = initial ?? WorkspaceState.initial();

  @override
  WorkspaceState build() => _initialState;

  @override
  Future<bool> createWorkspace(String name) async {
    createWorkspaceCalled = true;
    lastCreatedName = name;
    if (createShouldFail) {
      state = state.copyWith(error: 'Failed to create');
      return false;
    }
    final ws = WorkspaceEntity(
      id: 'new-ws',
      name: name,
      createdAt: DateTime.now(),
    );
    state = state.copyWith(
      workspaces: [ws, ...state.workspaces],
      selected: ws,
    );
    return true;
  }

  @override
  Future<bool> joinByInviteLink(String inviteLink) async {
    joinByInviteLinkCalled = true;
    lastInviteLink = inviteLink;
    if (joinShouldFail) {
      state = state.copyWith(error: 'Invalid invite link');
      return false;
    }
    final ws = WorkspaceEntity(
      id: 'joined-ws',
      name: 'Joined Workspace',
      createdAt: DateTime.now(),
    );
    state = state.copyWith(
      workspaces: [ws, ...state.workspaces],
      selected: ws,
    );
    return true;
  }
}

// ---- Helpers ----

void main() {
  Widget buildOnboardingPage({FakeWorkspaceViewModel? wsVm}) {
    return ProviderScope(
      overrides: [
        workspaceViewModelProvider
            .overrideWith(() => wsVm ?? FakeWorkspaceViewModel()),
      ],
      child: const MaterialApp(home: WorkspaceOnboardingPage()),
    );
  }

  group('WorkspaceOnboardingPage rendering', () {
    testWidgets('displays Welcome text', (tester) async {
      await tester.pumpWidget(buildOnboardingPage());
      expect(find.textContaining('Welcome'), findsOneWidget);
    });

    testWidgets('displays description text', (tester) async {
      await tester.pumpWidget(buildOnboardingPage());
      expect(
        find.text('Create your first workspace or join an existing one.'),
        findsOneWidget,
      );
    });

    testWidgets('displays "Workspace name" label', (tester) async {
      await tester.pumpWidget(buildOnboardingPage());
      expect(find.text('Workspace name'), findsOneWidget);
    });

    testWidgets('displays "Invite link" label', (tester) async {
      await tester.pumpWidget(buildOnboardingPage());
      expect(find.text('Invite link'), findsOneWidget);
    });

    testWidgets('displays "Create Workspace" button', (tester) async {
      await tester.pumpWidget(buildOnboardingPage());
      expect(find.text('Create Workspace'), findsOneWidget);
    });

    testWidgets('displays "Join Workspace" button', (tester) async {
      await tester.pumpWidget(buildOnboardingPage());
      expect(find.text('Join Workspace'), findsOneWidget);
    });

    testWidgets('displays OR separator', (tester) async {
      await tester.pumpWidget(buildOnboardingPage());
      expect(find.text('OR'), findsOneWidget);
    });

    testWidgets('has two TextFields', (tester) async {
      await tester.pumpWidget(buildOnboardingPage());
      expect(find.byType(TextField), findsNWidgets(2));
    });

    testWidgets('displays hint texts in text fields', (tester) async {
      await tester.pumpWidget(buildOnboardingPage());
      expect(find.text('My Workspace'), findsOneWidget);
      expect(find.text('Paste invite link'), findsOneWidget);
    });
  });

  group('WorkspaceOnboardingPage create workspace', () {
    testWidgets('Create button is disabled when name field is empty',
        (tester) async {
      await tester.pumpWidget(buildOnboardingPage());

      final createButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Create Workspace'),
      );
      expect(createButton.onPressed, isNull);
    });

    testWidgets('Create button is enabled when name field has text',
        (tester) async {
      await tester.pumpWidget(buildOnboardingPage());

      // Enter text in the first TextField (workspace name)
      await tester.enterText(find.byType(TextField).first, 'My Project');
      await tester.pumpAndSettle();

      final createButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Create Workspace'),
      );
      expect(createButton.onPressed, isNotNull);
    });

    testWidgets('calls createWorkspace with entered name', (tester) async {
      final wsVm = FakeWorkspaceViewModel();
      // Make create fail to prevent navigation to DashboardView
      // (which needs providers not in scope). We only test the call is made.
      wsVm.createShouldFail = true;
      await tester.pumpWidget(buildOnboardingPage(wsVm: wsVm));

      await tester.enterText(find.byType(TextField).first, 'Test Workspace');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create Workspace'));
      await tester.pump();

      expect(wsVm.createWorkspaceCalled, true);
      expect(wsVm.lastCreatedName, 'Test Workspace');
    });
  });

  group('WorkspaceOnboardingPage join workspace', () {
    testWidgets('Join button is disabled when invite field is empty',
        (tester) async {
      await tester.pumpWidget(buildOnboardingPage());

      final joinButton = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Join Workspace'),
      );
      expect(joinButton.onPressed, isNull);
    });

    testWidgets('Join button is enabled when invite field has text',
        (tester) async {
      await tester.pumpWidget(buildOnboardingPage());

      // Enter text in the second TextField (invite link)
      await tester.enterText(find.byType(TextField).last, 'invite-token-xyz');
      await tester.pumpAndSettle();

      final joinButton = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Join Workspace'),
      );
      expect(joinButton.onPressed, isNotNull);
    });

    testWidgets('calls joinByInviteLink with entered text', (tester) async {
      final wsVm = FakeWorkspaceViewModel();
      // Make join fail to prevent navigation to DashboardView
      // (which needs providers not in scope). We only test the call is made.
      wsVm.joinShouldFail = true;
      await tester.pumpWidget(buildOnboardingPage(wsVm: wsVm));

      await tester.enterText(find.byType(TextField).last, 'abc-invite-link');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Join Workspace'));
      await tester.pump();

      expect(wsVm.joinByInviteLinkCalled, true);
      expect(wsVm.lastInviteLink, 'abc-invite-link');
    });
  });

  group('WorkspaceOnboardingPage error state', () {
    testWidgets('displays error text when workspace state has error',
        (tester) async {
      final wsVm = FakeWorkspaceViewModel(
        WorkspaceState(
          isLoading: false,
          workspaces: [],
          selected: null,
          error: 'Something went wrong',
        ),
      );

      await tester.pumpWidget(buildOnboardingPage(wsVm: wsVm));
      expect(find.text('Something went wrong'), findsOneWidget);
    });
  });

  group('WorkspaceOnboardingPage loading state', () {
    testWidgets('shows "Creating..." text when loading', (tester) async {
      final wsVm = FakeWorkspaceViewModel(
        WorkspaceState(
          isLoading: true,
          workspaces: [],
          selected: null,
          error: null,
        ),
      );

      await tester.pumpWidget(buildOnboardingPage(wsVm: wsVm));
      expect(find.text('Creating...'), findsOneWidget);
    });

    testWidgets('shows "Joining..." text when loading', (tester) async {
      final wsVm = FakeWorkspaceViewModel(
        WorkspaceState(
          isLoading: true,
          workspaces: [],
          selected: null,
          error: null,
        ),
      );

      await tester.pumpWidget(buildOnboardingPage(wsVm: wsVm));
      expect(find.text('Joining...'), findsOneWidget);
    });
  });
}
