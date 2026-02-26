import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:html/parser.dart' as html_parser;

import 'package:motion_ai/feature/home/presentation/pages/widgets/notes_card_widget.dart';
import 'package:motion_ai/feature/notes/domain/entities/note_entity.dart';
import 'package:motion_ai/feature/notes/presentation/view_model/notes_view_model.dart';
import 'package:motion_ai/feature/notes/presentation/state/notes_state.dart';
import 'package:motion_ai/feature/workspace/presentation/view_model/workspace_view_model.dart';

// ✅ import your editor page
import 'package:motion_ai/feature/notes/presentation/pages/note_editor.dart';

class NotesListView extends ConsumerStatefulWidget {
  const NotesListView({super.key});

  @override
  ConsumerState<NotesListView> createState() => _NotesListViewState();
}

class _NotesListViewState extends ConsumerState<NotesListView> {
  bool _isSearching = false;
  final TextEditingController _searchCtrl = TextEditingController();
  ProviderSubscription? _wsSub;

  // ---------- HTML helpers ----------
  String _htmlToPlainText(String html) {
    final document = html_parser.parse(html);
    return (document.body?.text ?? '').trim();
  }

  String _previewFromHtml(String html, {int maxChars = 140}) {
    final text = _htmlToPlainText(html).replaceAll(RegExp(r'\s+'), ' ');
    if (text.length <= maxChars) return text;
    return '${text.substring(0, maxChars)}...';
  }

  @override
  void initState() {
    super.initState();

    // 1) Fetch once after first frame (selected workspace)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final wsState = ref.read(workspaceViewModelProvider);
      final selected = wsState.selected;
      if (selected != null) {
        ref
            .read(notesViewModelProvider.notifier)
            .fetchWorkspaceNotes(selected.id);
      }
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
    });
  }

  @override
  void dispose() {
    _wsSub?.close();
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
    final wsState = ref.watch(workspaceViewModelProvider);
    final selectedWorkspace = wsState.selected;

    final notesState = ref.watch(notesViewModelProvider);
    final query = _searchCtrl.text.trim().toLowerCase();

    final visibleNotes = query.isEmpty
        ? notesState.notes
        : notesState.notes.where((n) {
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
                child: Row(
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

                    return ListView.builder(
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

                        return InkWell(
                          onTap: () => _openEditNote(note),
                          child: NoteCard(
                            title: note.title,
                            content: preview,
                            category: "Workspace",
                            time: formattedTime,
                            isPinned: false,
                          ),
                        );
                      },
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
