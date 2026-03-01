import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:html/parser.dart' as html_parser;

import 'package:motion_ai/feature/home/presentation/pages/widgets/notes_card_widget.dart';
import 'package:motion_ai/feature/notes/domain/entities/note_entity.dart';
import 'package:motion_ai/feature/notes/presentation/view_model/notes_view_model.dart';
import 'package:motion_ai/feature/notes/presentation/state/notes_state.dart';
import 'package:motion_ai/feature/workspace/presentation/view_model/workspace_view_model.dart';

import 'package:motion_ai/core/services/sensor/shake_detection_service.dart';
import 'package:motion_ai/core/sync/notes_auto_sync.dart';
import 'package:motion_ai/feature/audio_file/presentation/providers/recording_providers.dart';
import 'package:motion_ai/feature/notes/presentation/providers/shake_to_refresh_provider.dart';
import 'package:motion_ai/feature/notes/presentation/pages/note_editor.dart';

class NotesListView extends ConsumerStatefulWidget {
  const NotesListView({super.key});

  @override
  ConsumerState<NotesListView> createState() => _NotesListViewState();
}

class _NotesListViewState extends ConsumerState<NotesListView> {
  bool _isSearching = false;
  bool _showSynced = false;
  String? _activeFilter; // null = All
  Timer? _syncedTimer;
  final TextEditingController _searchCtrl = TextEditingController();
  ProviderSubscription? _wsSub;
  ProviderSubscription<NotesSyncState>? _syncSub;
  late final ShakeDetectionService _shakeService;

  // ---------- Selection state ----------
  final Set<String> _selectedNoteIds = {};
  bool get _isSelectionMode => _selectedNoteIds.isNotEmpty;

  // ---------- HTML helpers ----------
  String _htmlToPlainText(String html) {
    // Insert a space before closing block tags so paragraphs don't merge
    final spaced = html.replaceAllMapped(
      RegExp(r'</(p|div|br|h[1-6]|li|blockquote)>', caseSensitive: false),
      (m) => ' </${m[1]}>',
    );
    // Also handle self-closing <br> / <br/>
    final withBreaks = spaced.replaceAll(RegExp(r'<br\s*/?>'), ' ');
    final document = html_parser.parse(withBreaks);
    return (document.body?.text ?? '').trim();
  }

  String _previewFromHtml(String html, {int maxChars = 140}) {
    final text = _htmlToPlainText(html).replaceAll(RegExp(r'\s+'), ' ');
    if (text.length <= maxChars) return text;
    return '${text.substring(0, maxChars)}...';
  }

  String _noteTypeLabel(String? type) {
    switch (type) {
      case 'MEETING_SUMMARY':
        return 'Meeting Summary';
      case 'VOICE_TRANSCRIPT':
        return 'Voice Transcript';
      case 'MANUAL':
        return 'Manual Note';
      default:
        return 'Note';
    }
  }

  @override
  void initState() {
    super.initState();

    _shakeService = ref.read(shakeDetectionServiceProvider);

    void onShake() {
      if (!mounted) return;
      if (ref.read(recordingStateProvider) == RecordingState.recording) return;
      final ws = ref.read(workspaceViewModelProvider).selected;
      if (ws != null) {
        ref.read(notesViewModelProvider.notifier).refreshWorkspaceNotes(ws.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Refreshing notes...'),
            backgroundColor: Color(0xFF3F5F00),
            duration: Duration(seconds: 1),
          ),
        );
      }
    }

    if (ref.read(shakeToRefreshEnabledProvider)) {
      _shakeService.startListening(onShakeDetected: onShake);
    }

    ref.listenManual(shakeToRefreshEnabledProvider, (_, enabled) {
      if (enabled) {
        _shakeService.startListening(onShakeDetected: onShake);
      } else {
        _shakeService.stopListening();
      }
    });

    _syncSub = ref.listenManual(notesAutoSyncProvider, (prev, next) {
      final wasSyncing = prev?.isSyncing ?? false;

      if (wasSyncing && !next.isSyncing && next.lastError == null) {
        final ws = ref.read(workspaceViewModelProvider).selected;
        if (ws != null) {
          ref.read(notesViewModelProvider.notifier).fetchWorkspaceNotes(ws.id);
        }

        // Show "Synced" pill briefly
        _syncedTimer?.cancel();
        setState(() => _showSynced = true);
        _syncedTimer = Timer(const Duration(seconds: 3), () {
          if (mounted) setState(() => _showSynced = false);
        });
      }
    });

    // 1) Fetch once after first frame (selected workspace)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final wsState = ref.read(workspaceViewModelProvider);
      final selected = wsState.selected;
      if (selected != null) {
        ref
            .read(notesViewModelProvider.notifier)
            .fetchWorkspaceNotes(selected.id);
      }
      ref.read(notesAutoSyncProvider.notifier).trySync();
    });

    // 2) Listen workspace changes
    _wsSub = ref.listenManual(workspaceViewModelProvider, (prev, next) {
      final prevId = prev?.selected?.id;
      final nextId = next.selected?.id;

      if (nextId != null && nextId != prevId) {
        if (_isSearching) {
          setState(() {
            _searchCtrl.clear();
          });
        }
        ref.read(notesViewModelProvider.notifier).fetchWorkspaceNotes(nextId);
      }
      ref.read(notesAutoSyncProvider.notifier).trySync();
    });
  }

  @override
  void dispose() {
    _shakeService.stopListening();
    _wsSub?.close();
    _syncSub?.close();
    _syncedTimer?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openSearch() => setState(() => _isSearching = true);

  void _closeSearch() {
    setState(() {
      _isSearching = false;
      _searchCtrl.clear();
    });
  }

  void _clearSelection() => setState(() => _selectedNoteIds.clear());

  void _toggleSelection(String noteId) {
    setState(() {
      if (_selectedNoteIds.contains(noteId)) {
        _selectedNoteIds.remove(noteId);
      } else {
        _selectedNoteIds.add(noteId);
      }
    });
  }

  Future<void> _confirmAndDeleteNotes(List<String> noteIds) async {
    final count = noteIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E3A0F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title:
            const Text('Delete Notes', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete $count ${count == 1 ? 'note' : 'notes'}?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    for (final id in noteIds) {
      await ref.read(notesViewModelProvider.notifier).deleteNote(id);
    }
    _clearSelection();
  }

  Future<void> _openCreateNote() async {
    final ws = ref.read(workspaceViewModelProvider).selected;
    if (ws == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NoteEditorPage()),
    );

    // Refresh after returning
    if (!mounted) return;
    ref.read(notesViewModelProvider.notifier).fetchWorkspaceNotes(ws.id);
  }

  Future<void> _openEditNote(NoteEntity note) async {
    final ws = ref.read(workspaceViewModelProvider).selected;
    if (ws == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NoteEditorPage(note: note)),
    );

    // Refresh after returning
    if (!mounted) return;
    ref.read(notesViewModelProvider.notifier).fetchWorkspaceNotes(ws.id);
  }

  @override
  Widget build(BuildContext context) {
    final syncState = ref.watch(notesAutoSyncProvider);
    final wsState = ref.watch(workspaceViewModelProvider);
    final selectedWorkspace = wsState.selected;

    final notesState = ref.watch(notesViewModelProvider);
    final query = _searchCtrl.text.trim().toLowerCase();

    // Apply type filter first, then search query
    final filteredByType = _activeFilter == null
        ? notesState.notes
        : notesState.notes.where((n) => n.type == _activeFilter).toList();

    final visibleNotes = query.isEmpty
        ? filteredByType
        : filteredByType.where((n) {
            final t = n.title.toLowerCase();
            final s = (n.summary ?? '').toLowerCase();
            final plainBody = _htmlToPlainText(n.content).toLowerCase();

            return t.contains(query) ||
                s.contains(query) ||
                plainBody.contains(query);
          }).toList();

    final isBusy = notesState.status == NotesStatus.loading ||
        notesState.status == NotesStatus.creating ||
        notesState.status == NotesStatus.updating ||
        notesState.status == NotesStatus.deleting;

    return Scaffold(
      extendBody: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E3A0F), Color(0xFF2F5D15), Color(0xFF224210)],
            stops: [0.0, 0.4, 1.0],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // ======= TOP BAR =======
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: _isSelectionMode
                    // ---- Selection mode bar ----
                    ? Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close,
                                color: Colors.white, size: 24),
                            onPressed: _clearSelection,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_selectedNoteIds.length} selected',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'sf_pro',
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red, size: 24),
                            onPressed: () => _confirmAndDeleteNotes(
                                _selectedNoteIds.toList()),
                          ),
                        ],
                      )
                    // ---- Normal bar ----
                    : Stack(
                        alignment: Alignment.center,
                        children: [
                          Row(
                            children: [
                              const SizedBox(width: 40),
                              Expanded(
                                child: _isSearching
                                    ? _SearchField(
                                        controller: _searchCtrl,
                                        onChanged: (_) => setState(() {}),
                                        onClose: _closeSearch,
                                      )
                                    : const Center(
                                        child: Text(
                                          'NOTES',
                                          style: TextStyle(
                                            color: Colors.white60,
                                            letterSpacing: 2,
                                            fontWeight: FontWeight.w600,
                                            fontFamily: 'sf_pro',
                                          ),
                                        ),
                                      ),
                              ),
                              if (!_isSearching)
                                IconButton(
                                  icon: const Icon(Icons.search,
                                      color: Colors.white, size: 24),
                                  onPressed: _openSearch,
                                )
                              else
                                const SizedBox(width: 48),
                            ],
                          ),
                          // Syncing pill
                          if (syncState.isSyncing)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.10),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                      color: Colors.white.withOpacity(0.12)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    SizedBox(
                                      height: 14,
                                      width: 14,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      "Syncing…",
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                        fontFamily: 'sf_pro',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          // Synced pill
                          if (!syncState.isSyncing && _showSynced)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                      color: Colors.green.withOpacity(0.25)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.check_circle,
                                        color: Colors.green, size: 14),
                                    SizedBox(width: 8),
                                    Text(
                                      "Synced",
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontSize: 12,
                                        fontFamily: 'sf_pro',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
              ),

              // ======= FILTER CHIPS =======
              if (!_isSelectionMode)
                Padding(
                  padding: const EdgeInsets.only(left: 20, top: 4, bottom: 4),
                  child: SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildFilterChip(label: 'All', type: null),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                            label: 'Manual',
                            type: 'MANUAL',
                            icon: Icons.edit_note),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                            label: 'Transcript',
                            type: 'VOICE_TRANSCRIPT',
                            icon: Icons.mic),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                            label: 'Meeting',
                            type: 'MEETING_SUMMARY',
                            icon: Icons.groups),
                        const SizedBox(width: 20),
                      ],
                    ),
                  ),
                ),

              // ======= BODY =======
              Expanded(
                child: Builder(
                  builder: (_) {
                    if (selectedWorkspace == null) {
                      return const Center(
                        child: Text(
                          "Select a workspace to see notes",
                          style: TextStyle(color: Colors.white70),
                        ),
                      );
                    }

                    if (isBusy) {
                      return const Center(
                        child:
                            CircularProgressIndicator(color: Color(0xFFAEFB2A)),
                      );
                    }

                    if (notesState.status == NotesStatus.error) {
                      return Center(
                        child: Text(
                          notesState.error ?? "Something went wrong",
                          style: const TextStyle(color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    if (visibleNotes.isEmpty) {
                      return Center(
                        child: Text(
                          query.isEmpty
                              ? "No notes yet"
                              : "No results for “${_searchCtrl.text.trim()}”",
                          style: const TextStyle(color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        final ws =
                            ref.read(workspaceViewModelProvider).selected;
                        if (ws != null) {
                          await ref
                              .read(notesViewModelProvider.notifier)
                              .refreshWorkspaceNotes(ws.id);
                        }
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.only(top: 10, bottom: 120),
                        itemCount: visibleNotes.length,
                        itemBuilder: (context, index) {
                          final note = visibleNotes[index];

                          final date =
                              (note.updatedAt ?? note.createdAt)?.toLocal();
                          final formattedTime = date != null
                              ? DateFormat("dd MMM yyyy • HH:mm").format(date)
                              : "";

                          final preview = _previewFromHtml(note.content);

                          return Dismissible(
                            key: ValueKey(note.id),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (_) async {
                              await _confirmAndDeleteNotes([note.id]);
                              // Return false — deletion is handled inside
                              // _confirmAndDeleteNotes via the view model.
                              return false;
                            },
                            background: Container(
                              alignment: Alignment.centerRight,
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              padding: const EdgeInsets.only(right: 24),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: const Icon(Icons.delete,
                                  color: Colors.red, size: 28),
                            ),
                            child: GestureDetector(
                              onLongPress: () => _toggleSelection(note.id),
                              onTap: () {
                                if (_isSelectionMode) {
                                  _toggleSelection(note.id);
                                } else {
                                  _openEditNote(note);
                                }
                              },
                              child: NoteCard(
                                title: note.title,
                                content: preview,
                                category: _noteTypeLabel(note.type),
                                time: formattedTime,
                                isPinned: false,
                                isSelected: _selectedNoteIds.contains(note.id),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String? type,
    IconData? icon,
  }) {
    final isActive = _activeFilter == type;
    final chipColor = _filterColor(type);

    return GestureDetector(
      onTap: () => setState(() => _activeFilter = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? chipColor.withOpacity(0.2)
              : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? chipColor.withOpacity(0.6)
                : Colors.white.withOpacity(0.12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 14, color: isActive ? chipColor : Colors.white54),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                color: isActive ? chipColor : Colors.white54,
                fontSize: 13,
                fontFamily: 'sf_pro',
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Color _filterColor(String? type) {
    switch (type) {
      case 'VOICE_TRANSCRIPT':
        return const Color(0xFFFFB74D); // blue
      case 'MEETING_SUMMARY':
        return const Color(0xFF64B5F6); // amber
      case 'MANUAL':
        return const Color(0xFFAEFB2A); // green
      default:
        return Colors.white; // "All"
    }
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClose,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),
          const Icon(Icons.search, color: Colors.white70, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: true,
              onChanged: onChanged,
              style: const TextStyle(color: Colors.white, fontFamily: 'sf_pro'),
              cursorColor: const Color(0xFFAEFB2A),
              decoration: const InputDecoration(
                hintText: "Search notes...",
                hintStyle: TextStyle(color: Colors.white54),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close, color: Colors.white70, size: 18),
          ),
        ],
      ),
    );
  }
}
