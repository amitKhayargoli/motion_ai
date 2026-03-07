import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motion_ai/core/services/connectivity/connectivity_stream_provider.dart';
import 'package:motion_ai/core/services/sensor/proximity_wave_service.dart';
import 'package:motion_ai/core/sync/notes_auto_sync.dart';
import 'package:motion_ai/core/sync/rag_chat_auto_sync.dart';
import 'package:motion_ai/core/sync/audio_auto_sync.dart';
import 'package:motion_ai/core/sync/tasks_auto_sync.dart';
import 'package:motion_ai/core/utils/snackbar_utils.dart';
import 'package:motion_ai/feature/audio_file/presentation/view_model/audio_view_model.dart';
import 'package:motion_ai/feature/audio_file/presentation/pages/recordings_view.dart';
import 'package:motion_ai/feature/audio_file/presentation/pages/voice_recorder_page.dart';
import 'package:motion_ai/feature/home/presentation/pages/home_view.dart';
import 'package:motion_ai/feature/home/presentation/providers/wave_to_switch_provider.dart';
import 'package:motion_ai/feature/rag_chatbot/presentation/pages/mindspace_view.dart';
import 'package:motion_ai/feature/notes/presentation/pages/notes_view.dart';
import 'package:motion_ai/feature/home/presentation/pages/widgets/bottom_nav_widget.dart';
import 'package:motion_ai/feature/notes/presentation/pages/note_editor.dart';
import 'package:motion_ai/feature/workspace/presentation/view_model/workspace_view_model.dart';

class DashboardView extends ConsumerStatefulWidget {
  const DashboardView({super.key});

  @override
  ConsumerState<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends ConsumerState<DashboardView> {
  int _selectedIndex = 0;

  ProviderSubscription<dynamic>? _sub;
  late final ProximityWaveService _proximityService;

  @override
  void initState() {
    super.initState();
    _sub = ref.listenManual(
      connectivityStreamProvider,
      (previous, next) {
        if (next.isLoading || next.hasError) return;
        final results = next.value;
        if (results == null) return;

        if (!results.contains(ConnectivityResult.none)) {
          ref.read(notesAutoSyncProvider.notifier).trySync();
          ref.read(ragChatAutoSyncProvider.notifier).trySync();
          ref.read(tasksAutoSyncProvider.notifier).trySync();
          ref.read(audioAutoSyncProvider.notifier).trySync().then((_) {
            ref.read(audioViewModelProvider.notifier).reloadFromLocal();
          });
        }
      },
    );

    _proximityService = ref.read(proximityWaveServiceProvider);
    _startProximityIfEnabled();

    ref.listenManual<bool>(
      waveToSwitchEnabledProvider,
      (previous, next) {
        if (next) {
          _startProximityIfEnabled();
        } else {
          _proximityService.stopListening();
        }
      },
    );
  }

  @override
  void dispose() {
    _sub?.close();
    _proximityService.stopListening();
    super.dispose();
  }

  // ================== PROXIMITY SENSOR ==================
  void _startProximityIfEnabled() {
    final enabled = ref.read(waveToSwitchEnabledProvider);
    if (!enabled) return;
    if (_proximityService.isListening) return;

    _proximityService.startListening(
      onWaveDetected: () {
        if (!mounted) return;

        // Only respond to proximity wave when DashboardView is the top route
        // (i.e. user is on one of the four bottom nav pages, not a sub-page).
        final route = ModalRoute.of(context);
        if (route == null || !route.isCurrent) return;

        final nextWs = ref
            .read(workspaceViewModelProvider.notifier)
            .cycleToNextWorkspace();

        if (nextWs != null && mounted) {
          SnackbarUtils.showSuccess(
            context,
            'Switched to ${nextWs.name}',
          );
        }
      },
    );
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  List<Widget> get pages => [
        HomeView(onViewAllRecordings: () => _onItemTapped(1)),
        const RecordingsView(),
        const MindspaceView(),
        const NotesListView(),
      ];

  Future<void> _openCreateNote() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NoteEditorPage()),
    );
  }

  void _openVoiceRecorder() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const VoiceRecorderPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<List<ConnectivityResult>>>(
      connectivityStreamProvider,
      (prev, next) {
        next.whenData((results) {
          if (!results.contains(ConnectivityResult.none)) {
            ref.read(notesAutoSyncProvider.notifier).trySync();
            ref.read(ragChatAutoSyncProvider.notifier).trySync();
            ref.read(tasksAutoSyncProvider.notifier).trySync();
            ref.read(audioAutoSyncProvider.notifier).trySync().then((_) {
              ref.read(audioViewModelProvider.notifier).reloadFromLocal();
            });
          }
        });
      },
    );

    return Scaffold(
      extendBody: true,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: _selectedIndex == 1
          ? _recordFab()
          : _selectedIndex == 3
              ? _createNoteFab()
              : null,
      bottomNavigationBar: BottomNavWidget(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
    );
  }

  // ================== RECORD FAB ==================
  Widget _recordFab() {
    return FloatingActionButton.extended(
      heroTag: 'record_fab',
      onPressed: _openVoiceRecorder,
      backgroundColor: const Color(0xFF3F5F00),
      icon: const Icon(Icons.mic, color: Colors.white, size: 24),
      label: const Text(
        "Record",
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          fontFamily: 'sf_pro',
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
    );
  }

  // ================== CREATE NOTE FAB (NOTES) ==================
  Widget _createNoteFab() {
    return FloatingActionButton.extended(
      heroTag: 'note_fab',
      onPressed: _openCreateNote,
      backgroundColor: const Color(0xFF3F5F00),
      icon: const Icon(Icons.edit_note, color: Colors.white, size: 26),
      label: const Text(
        "New Note",
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          fontFamily: 'sf_pro',
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
    );
  }
}
