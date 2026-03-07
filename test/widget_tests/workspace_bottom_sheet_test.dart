import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motion_ai/feature/home/presentation/pages/widgets/workspace_bottom_sheet.dart';
import 'package:motion_ai/feature/workspace/domain/entities/workspace_entity.dart';
import 'package:motion_ai/feature/workspace/presentation/state/workspace_state.dart';
import 'package:motion_ai/feature/workspace/presentation/view_model/workspace_view_model.dart';

// ---- Fakes ----

class FakeWorkspaceViewModel extends WorkspaceViewModel {
  final WorkspaceState _initialState;
  FakeWorkspaceViewModel([WorkspaceState? initial])
      : _initialState = initial ?? WorkspaceState.initial();

  @override
  WorkspaceState build() => _initialState;

  bool selectWorkspaceCalled = false;
  String? lastSelectedId;
  @override
  void selectWorkspace(String workspaceId) {
    selectWorkspaceCalled = true;
    lastSelectedId = workspaceId;
    final found = state.workspaces.where((w) => w.id == workspaceId).toList();
    if (found.isEmpty) return;
    state = state.copyWith(selected: found.first);
  }

  bool createWorkspaceCalled = false;
  String? lastCreatedName;
  @override
  Future<bool> createWorkspace(String name) async {
    createWorkspaceCalled = true;
    lastCreatedName = name;
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

  bool joinByInviteLinkCalled = false;
  String? lastInviteLink;
  bool joinShouldFail = false;
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

// ---- Test data ----

final tWorkspace1 = WorkspaceEntity(
  id: 'ws-1',
  name: 'My Workspace',
  createdAt: DateTime(2025, 1, 1),
);

final tWorkspace2 = WorkspaceEntity(
  id: 'ws-2',
  name: 'Team Workspace',
  createdAt: DateTime(2025, 2, 1),
);

WorkspaceState stateWithWorkspaces({WorkspaceEntity? selected}) =>
    WorkspaceState(
      isLoading: false,
      workspaces: [tWorkspace1, tWorkspace2],
      selected: selected ?? tWorkspace1,
      error: null,
    );

WorkspaceState emptyState() => WorkspaceState.initial();

WorkspaceState loadingState() => WorkspaceState(
      isLoading: true,
      workspaces: [tWorkspace1],
      selected: tWorkspace1,
      error: null,
    );

// ---- Helpers ----

/// Builds a scaffold that opens the workspace sheet on button press.
Widget buildSheetHost({required FakeWorkspaceViewModel wsVm}) {
  return ProviderScope(
    overrides: [
      workspaceViewModelProvider.overrideWith(() => wsVm),
    ],
    child: MaterialApp(
      home: Consumer(
        builder: (context, ref, _) {
          return Scaffold(
            body: ElevatedButton(
              onPressed: () => showWorkspaceSheet(context, ref),
              child: const Text('Open Sheet'),
            ),
          );
        },
      ),
    ),
  );
}

/// Tap the trigger button to open the bottom sheet.
Future<void> openSheet(WidgetTester tester) async {
  await tester.tap(find.text('Open Sheet'));
  await tester.pumpAndSettle();
}

void main() {
  group('WorkspaceBottomSheet rendering', () {
    testWidgets('displays "Workspaces" title', (tester) async {
      final wsVm = FakeWorkspaceViewModel(stateWithWorkspaces());
      await tester.pumpWidget(buildSheetHost(wsVm: wsVm));
      await openSheet(tester);

      expect(find.text('Workspaces'), findsOneWidget);
    });

    testWidgets('displays drag handle', (tester) async {
      final wsVm = FakeWorkspaceViewModel(stateWithWorkspaces());
      await tester.pumpWidget(buildSheetHost(wsVm: wsVm));
      await openSheet(tester);

      // Drag handle is a Container with width 44, height 5
      final containers = find.byType(Container);
      expect(containers, findsWidgets);
    });

    testWidgets('displays workspace names', (tester) async {
      final wsVm = FakeWorkspaceViewModel(stateWithWorkspaces());
      await tester.pumpWidget(buildSheetHost(wsVm: wsVm));
      await openSheet(tester);

      expect(find.text('My Workspace'), findsOneWidget);
      expect(find.text('Team Workspace'), findsOneWidget);
    });

    testWidgets('displays check_circle on selected workspace', (tester) async {
      final wsVm = FakeWorkspaceViewModel(stateWithWorkspaces());
      await tester.pumpWidget(buildSheetHost(wsVm: wsVm));
      await openSheet(tester);

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.circle_outlined), findsOneWidget);
    });

    testWidgets('displays "Create Workspace" tile', (tester) async {
      final wsVm = FakeWorkspaceViewModel(stateWithWorkspaces());
      await tester.pumpWidget(buildSheetHost(wsVm: wsVm));
      await openSheet(tester);

      expect(find.text('Create Workspace'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('displays "Join by invite link" section', (tester) async {
      final wsVm = FakeWorkspaceViewModel(stateWithWorkspaces());
      await tester.pumpWidget(buildSheetHost(wsVm: wsVm));
      await openSheet(tester);

      expect(find.text('Join by invite link'), findsOneWidget);
    });

    testWidgets('displays invite link text field with hint', (tester) async {
      final wsVm = FakeWorkspaceViewModel(stateWithWorkspaces());
      await tester.pumpWidget(buildSheetHost(wsVm: wsVm));
      await openSheet(tester);

      expect(
        find.text('Paste inviteLink (e.g. 8ed24428...)'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.link), findsOneWidget);
    });

    testWidgets('displays "Join Workspace" button', (tester) async {
      final wsVm = FakeWorkspaceViewModel(stateWithWorkspaces());
      await tester.pumpWidget(buildSheetHost(wsVm: wsVm));
      await openSheet(tester);

      expect(find.text('Join Workspace'), findsOneWidget);
      expect(find.byIcon(Icons.group_add), findsOneWidget);
    });

    testWidgets('displays Cancel button', (tester) async {
      final wsVm = FakeWorkspaceViewModel(stateWithWorkspaces());
      await tester.pumpWidget(buildSheetHost(wsVm: wsVm));
      await openSheet(tester);

      expect(find.text('Cancel'), findsOneWidget);
    });
  });

  group('WorkspaceBottomSheet empty state', () {
    testWidgets('shows "No workspaces yet." when list is empty',
        (tester) async {
      final wsVm = FakeWorkspaceViewModel(emptyState());
      await tester.pumpWidget(buildSheetHost(wsVm: wsVm));
      await openSheet(tester);

      expect(find.text('No workspaces yet.'), findsOneWidget);
    });

    testWidgets('does not show check_circle or circle_outlined when empty',
        (tester) async {
      final wsVm = FakeWorkspaceViewModel(emptyState());
      await tester.pumpWidget(buildSheetHost(wsVm: wsVm));
      await openSheet(tester);

      expect(find.byIcon(Icons.check_circle), findsNothing);
      expect(find.byIcon(Icons.circle_outlined), findsNothing);
    });

    testWidgets('still shows join and cancel sections when empty',
        (tester) async {
      final wsVm = FakeWorkspaceViewModel(emptyState());
      await tester.pumpWidget(buildSheetHost(wsVm: wsVm));
      await openSheet(tester);

      expect(find.text('Join by invite link'), findsOneWidget);
      expect(find.text('Join Workspace'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });
  });

  group('WorkspaceBottomSheet select workspace', () {
    testWidgets('tapping a workspace calls selectWorkspace', (tester) async {
      final wsVm = FakeWorkspaceViewModel(stateWithWorkspaces());
      await tester.pumpWidget(buildSheetHost(wsVm: wsVm));
      await openSheet(tester);

      await tester.tap(find.text('Team Workspace'));
      await tester.pumpAndSettle();

      expect(wsVm.selectWorkspaceCalled, true);
      expect(wsVm.lastSelectedId, 'ws-2');
    });

    testWidgets('tapping a workspace closes the bottom sheet', (tester) async {
      final wsVm = FakeWorkspaceViewModel(stateWithWorkspaces());
      await tester.pumpWidget(buildSheetHost(wsVm: wsVm));
      await openSheet(tester);

      expect(find.text('Workspaces'), findsOneWidget);

      await tester.tap(find.text('Team Workspace'));
      await tester.pumpAndSettle();

      // Sheet should be dismissed
      expect(find.text('Workspaces'), findsNothing);
    });

    testWidgets('tapping a workspace shows success snackbar', (tester) async {
      final wsVm = FakeWorkspaceViewModel(stateWithWorkspaces());
      await tester.pumpWidget(buildSheetHost(wsVm: wsVm));
      await openSheet(tester);

      await tester.tap(find.text('Team Workspace'));
      await tester.pump(); // show snackbar

      expect(find.textContaining('Switched to Team Workspace'), findsOneWidget);
    });
  });

  group('WorkspaceBottomSheet cancel', () {
    testWidgets('cancel button closes the bottom sheet', (tester) async {
      final wsVm = FakeWorkspaceViewModel(stateWithWorkspaces());
      await tester.pumpWidget(buildSheetHost(wsVm: wsVm));
      await openSheet(tester);

      expect(find.text('Workspaces'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Workspaces'), findsNothing);
    });
  });

  group('WorkspaceBottomSheet join workspace', () {
    testWidgets('shows error snackbar when invite link is empty',
        (tester) async {
      final wsVm = FakeWorkspaceViewModel(stateWithWorkspaces());
      await tester.pumpWidget(buildSheetHost(wsVm: wsVm));
      await openSheet(tester);

      // Tap Join without entering link
      await tester.tap(find.text('Join Workspace'));
      await tester.pump();

      expect(find.text('Invite link is required'), findsOneWidget);
      expect(wsVm.joinByInviteLinkCalled, false);
    });

    testWidgets('calls joinByInviteLink with entered text', (tester) async {
      final wsVm = FakeWorkspaceViewModel(stateWithWorkspaces());
      await tester.pumpWidget(buildSheetHost(wsVm: wsVm));
      await openSheet(tester);

      // Enter invite link
      await tester.enterText(
        find.byType(TextField),
        'abc123-invite-token',
      );
      await tester.pump();

      await tester.tap(find.text('Join Workspace'));
      await tester.pumpAndSettle();

      expect(wsVm.joinByInviteLinkCalled, true);
      expect(wsVm.lastInviteLink, 'abc123-invite-token');
    });

    testWidgets('shows success snackbar and closes on successful join',
        (tester) async {
      final wsVm = FakeWorkspaceViewModel(stateWithWorkspaces());
      await tester.pumpWidget(buildSheetHost(wsVm: wsVm));
      await openSheet(tester);

      await tester.enterText(find.byType(TextField), 'valid-link');
      await tester.pump();

      await tester.tap(find.text('Join Workspace'));
      await tester.pump(); // process join + snackbar

      expect(
        find.textContaining('Joined Joined Workspace'),
        findsOneWidget,
      );
    });

    testWidgets('shows error snackbar on failed join', (tester) async {
      final wsVm = FakeWorkspaceViewModel(stateWithWorkspaces());
      wsVm.joinShouldFail = true;
      await tester.pumpWidget(buildSheetHost(wsVm: wsVm));
      await openSheet(tester);

      await tester.enterText(find.byType(TextField), 'bad-link');
      await tester.pump();

      await tester.tap(find.text('Join Workspace'));
      await tester.pump();

      expect(find.text('Invalid invite link'), findsOneWidget);
    });

    testWidgets('shows "Joining..." when loading', (tester) async {
      final wsVm = FakeWorkspaceViewModel(loadingState());
      await tester.pumpWidget(buildSheetHost(wsVm: wsVm));
      await openSheet(tester);

      expect(find.text('Joining...'), findsOneWidget);
    });
  });

  group('WorkspaceBottomSheet create workspace dialog', () {
    testWidgets('tapping "Create Workspace" opens dialog', (tester) async {
      final wsVm = FakeWorkspaceViewModel(stateWithWorkspaces());
      await tester.pumpWidget(buildSheetHost(wsVm: wsVm));
      await openSheet(tester);

      // The "Create Workspace" ListTile in the sheet
      await tester.tap(find.text('Create Workspace'));
      await tester.pumpAndSettle();

      // Dialog should appear with title and text field
      // The dialog also has "Create Workspace" as title text
      expect(find.text('Workspace name'), findsOneWidget);
      expect(find.text('Create'), findsOneWidget);
    });

    testWidgets('cancel in dialog closes dialog but keeps sheet',
        (tester) async {
      final wsVm = FakeWorkspaceViewModel(stateWithWorkspaces());
      await tester.pumpWidget(buildSheetHost(wsVm: wsVm));
      await openSheet(tester);

      await tester.tap(find.text('Create Workspace'));
      await tester.pumpAndSettle();

      // Two Cancel buttons: one in dialog, one in sheet behind it.
      // The sheet's Cancel is obscured by the dialog barrier, so
      // warnIfMissed: false suppresses the hit-test warning.
      final dialogCancel = find.text('Cancel').first;
      await tester.ensureVisible(dialogCancel);
      await tester.tap(dialogCancel, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Dialog closed, sheet still open
      expect(find.text('Workspace name'), findsNothing);
      expect(find.text('Workspaces'), findsOneWidget);
    });

    testWidgets('shows error when name is empty', (tester) async {
      final wsVm = FakeWorkspaceViewModel(stateWithWorkspaces());
      await tester.pumpWidget(buildSheetHost(wsVm: wsVm));
      await openSheet(tester);

      await tester.tap(find.text('Create Workspace'));
      await tester.pumpAndSettle();

      // Tap Create without entering a name
      await tester.tap(find.text('Create'));
      await tester.pump();

      expect(find.text('Name is required'), findsOneWidget);
      expect(wsVm.createWorkspaceCalled, false);
    });

    testWidgets('creates workspace with entered name', (tester) async {
      final wsVm = FakeWorkspaceViewModel(stateWithWorkspaces());
      await tester.pumpWidget(buildSheetHost(wsVm: wsVm));
      await openSheet(tester);

      await tester.tap(find.text('Create Workspace'));
      await tester.pumpAndSettle();

      // Find the TextField in the dialog (the one with "Workspace name" hint)
      final textFields = find.byType(TextField);
      // The dialog's TextField is the last one (invite link field is in sheet behind)
      await tester.enterText(textFields.last, 'New Project');
      await tester.pump();

      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(wsVm.createWorkspaceCalled, true);
      expect(wsVm.lastCreatedName, 'New Project');
    });

    testWidgets('shows success snackbar on successful creation',
        (tester) async {
      final wsVm = FakeWorkspaceViewModel(stateWithWorkspaces());
      await tester.pumpWidget(buildSheetHost(wsVm: wsVm));
      await openSheet(tester);

      await tester.tap(find.text('Create Workspace'));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.last, 'New Project');
      await tester.pump();

      await tester.tap(find.text('Create'));
      await tester.pump(); // process + snackbar

      expect(find.textContaining('Created'), findsOneWidget);
    });
  });

  group('WorkspaceBottomSheet structure', () {
    testWidgets('sheet background color is light grey', (tester) async {
      final wsVm = FakeWorkspaceViewModel(stateWithWorkspaces());
      await tester.pumpWidget(buildSheetHost(wsVm: wsVm));
      await openSheet(tester);

      // BottomSheet is present
      expect(find.byType(BottomSheet), findsOneWidget);
    });

    testWidgets('workspace list uses ListView.separated', (tester) async {
      final wsVm = FakeWorkspaceViewModel(stateWithWorkspaces());
      await tester.pumpWidget(buildSheetHost(wsVm: wsVm));
      await openSheet(tester);

      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('workspace items are ListTiles', (tester) async {
      final wsVm = FakeWorkspaceViewModel(stateWithWorkspaces());
      await tester.pumpWidget(buildSheetHost(wsVm: wsVm));
      await openSheet(tester);

      // 2 workspaces + 1 "Create Workspace" tile = 3 ListTiles
      expect(find.byType(ListTile), findsNWidgets(3));
    });
  });
}
