import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_delta_from_html/flutter_quill_delta_from_html.dart';
import 'package:hive/hive.dart';
import 'package:motion_ai/core/utils/snackbar_utils.dart';
import 'package:motion_ai/feature/notes/domain/entities/note_entity.dart';
import 'package:motion_ai/feature/notes/presentation/view_model/notes_view_model.dart';
import 'package:motion_ai/feature/workspace/presentation/view_model/workspace_view_model.dart';
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';

class NoteEditorPage extends ConsumerStatefulWidget {
  const NoteEditorPage({super.key, this.note});

  /// null => create new
  /// not null => edit
  final NoteEntity? note;

  @override
  ConsumerState<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends ConsumerState<NoteEditorPage> {
  final _titleCtrl = TextEditingController();

  late QuillController _controller;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  bool _saving = false;

  // Draft autosave (keeps your UX nice)
  Timer? _draftTimer;
  bool _draftDirty = false;
  bool _draftSaving = false;

  static const _draftDebounce = Duration(milliseconds: 700);
  static const _draftBoxName = "notes_drafts";

  String get _modeTitle => widget.note == null ? "New Note" : "Edit Note";

  // draft key must differ per note
  String _draftKey(String workspaceId) {
    if (widget.note == null) {
      return "draft_create__ws_$workspaceId";
    }
    return "draft_edit__${widget.note!.id}__ws_$workspaceId";
  }

  @override
  void initState() {
    super.initState();

    // start with empty editor, then load in postFrame (so workspace is ready)
    _controller = QuillController.basic();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final ws = ref.read(workspaceViewModelProvider).selected;
      final workspaceId = ws?.id;

      // 1) prefill title/content from note if editing
      if (widget.note != null) {
        _titleCtrl.text = widget.note!.title;
        _loadHtmlIntoEditor(widget.note!.content);
      }

      // 2) load draft (draft overrides existing content if exists)
      if (workspaceId != null) {
        await _loadDraft(workspaceId);
      }

      // 3) attach draft listeners after initial fill
      _attachDraftListeners(workspaceId);
      setState(() {});
    });
  }

  @override
  void dispose() {
    _draftTimer?.cancel();
    _titleCtrl.dispose();
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ===================== HTML <-> QUILL =====================

  void _loadHtmlIntoEditor(String html) {
    try {
      // Convert HTML -> Delta -> Document
      final delta = HtmlToDelta().convert(html);
      final doc = Document.fromDelta(delta);

      _controller = QuillController(
        document: doc,
        selection: const TextSelection.collapsed(offset: 0),
      );
    } catch (e) {
      debugPrint("HTML -> Quill parse failed: $e");
      // Fallback: put plain text into doc
      final plain = html.replaceAll(RegExp(r"<[^>]*>"), "").trim();
      _controller = QuillController(
        document: Document()..insert(0, plain),
        selection: const TextSelection.collapsed(offset: 0),
      );
    }
  }

  String _docToHtml() {
    final ops =
        _controller.document.toDelta().toJson().cast<Map<String, dynamic>>();
    return QuillDeltaToHtmlConverter(
      ops,
      ConverterOptions(
        multiLineParagraph: true,
      ),
    ).convert();
  }

  bool _isEditorEmpty() => _controller.document.toPlainText().trim().isEmpty;

  // ===================== DRAFT AUTOSAVE =====================

  void _attachDraftListeners(String? workspaceId) {
    _titleCtrl.addListener(_markDraftDirty);
    _controller.document.changes.listen((_) => _markDraftDirty());
  }

  void _markDraftDirty() {
    _draftDirty = true;
    _draftTimer?.cancel();
    _draftTimer = Timer(_draftDebounce, _saveDraftNow);
  }

  Future<void> _saveDraftNow() async {
    final ws = ref.read(workspaceViewModelProvider).selected;
    final workspaceId = ws?.id;
    if (workspaceId == null) return;

    if (!_draftDirty) return;

    if (mounted) setState(() => _draftSaving = true);

    try {
      final box = await Hive.openBox(_draftBoxName);
      await box.put(_draftKey(workspaceId), {
        "title": _titleCtrl.text,
        "delta": _controller.document.toDelta().toJson(),
        "updatedAt": DateTime.now().toIso8601String(),
      });
      _draftDirty = false;
    } catch (e) {
      debugPrint("Draft save error: $e");
    } finally {
      if (mounted) setState(() => _draftSaving = false);
    }
  }

  Future<void> _loadDraft(String workspaceId) async {
    try {
      final box = await Hive.openBox(_draftBoxName);
      final raw = box.get(_draftKey(workspaceId));

      if (raw is Map) {
        if (raw["title"] != null) _titleCtrl.text = raw["title"].toString();

        final deltaJson = raw["delta"];
        if (deltaJson is List) {
          // Draft uses Delta JSON -> Document.fromJson
          _controller = QuillController(
            document: Document.fromJson(deltaJson),
            selection: const TextSelection.collapsed(offset: 0),
          );
        }
      }
    } catch (e) {
      debugPrint("Draft load error: $e");
    }
  }

  Future<void> _clearDraft() async {
    final ws = ref.read(workspaceViewModelProvider).selected;
    final workspaceId = ws?.id;
    if (workspaceId == null) return;

    final box = await Hive.openBox(_draftBoxName);
    await box.delete(_draftKey(workspaceId));
  }

  // ===================== SAVE (CREATE/UPDATE) =====================

  Future<void> _handleSave() async {
    final ws = ref.read(workspaceViewModelProvider).selected;
    if (ws == null) {
      SnackbarUtils.showError(context, "No workspace selected");
      return;
    }

    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      SnackbarUtils.showError(context, "Title is required");
      return;
    }

    if (_isEditorEmpty()) {
      SnackbarUtils.showError(context, "Note is empty");
      return;
    }

    setState(() => _saving = true);

    try {
      await _saveDraftNow();
      final htmlContent = _docToHtml();

      final vm = ref.read(notesViewModelProvider.notifier);

      if (widget.note == null) {
        // CREATE
        final created = await vm.createNote(
          workspaceId: ws.id,
          title: title,
          content: htmlContent,
        );

        if (!mounted) return;

        if (created != null) {
          await _clearDraft();
          SnackbarUtils.showSuccess(context, "Note saved");
          Navigator.pop(context, created);
        } else {
          SnackbarUtils.showError(
            context,
            ref.read(notesViewModelProvider).error ?? "Save failed",
          );
        }
      } else {
        // UPDATE (local-first should be handled in your repository)
        final updated = await vm.updateNote(
          noteId: widget.note!.id,
          title: title,
          content: htmlContent,
        );

        if (!mounted) return;

        if (updated != null) {
          await _clearDraft();
          SnackbarUtils.showSuccess(context, "Note updated");
          Navigator.pop(context, updated);
        } else {
          SnackbarUtils.showError(
            context,
            ref.read(notesViewModelProvider).error ?? "Update failed",
          );
        }
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ===================== UI =====================

  @override
  Widget build(BuildContext context) {
    final workspaceName =
        ref.watch(workspaceViewModelProvider).selected?.name ?? "No workspace";

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E3A0F), Color(0xFF2F5D15), Color(0xFF224210)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ======= APP BAR =======
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _modeTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              fontFamily: 'sf_pro',
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                workspaceName,
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                  fontFamily: 'sf_pro',
                                ),
                              ),
                              if (_draftSaving) ...[
                                const SizedBox(width: 8),
                                const Text(
                                  "Saving draft...",
                                  style: TextStyle(
                                    color: Colors.white38,
                                    fontSize: 12,
                                    fontFamily: 'sf_pro',
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: _saving ? null : _handleSave,
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              "Save",
                              style: TextStyle(
                                color: Color(0xFFAEFB2A),
                                fontWeight: FontWeight.bold,
                                fontFamily: 'sf_pro',
                              ),
                            ),
                    ),
                  ],
                ),
              ),

              // ======= TITLE =======
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _titleCtrl,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'sf_pro',
                  ),
                  cursorColor: const Color(0xFFAEFB2A),
                  decoration: InputDecoration(
                    hintText: "Title",
                    hintStyle: const TextStyle(
                      color: Colors.white30,
                      fontFamily: 'sf_pro',
                    ),
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              // ======= TOOLBAR =======
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: QuillSimpleToolbar(
                  controller: _controller,
                  config: QuillSimpleToolbarConfig(
                    showFontSize: false,
                    showFontFamily: false,
                    showColorButton: false,
                    showBackgroundColorButton: false,
                    buttonOptions: QuillSimpleToolbarButtonOptions(
                      base: QuillToolbarBaseButtonOptions(
                        iconTheme: const QuillIconTheme(
                          iconButtonSelectedData: IconButtonData(
                            color: Colors.black,
                          ),
                          iconButtonUnselectedData: IconButtonData(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // ======= EDITOR =======
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.20),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.white
                            .withOpacity(0.08)), // Added requested border
                  ),
                  child: DefaultTextStyle(
                    // ✅ Forces all editor text to be white
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    child: QuillEditor(
                      controller: _controller,
                      focusNode: _focusNode,
                      scrollController: _scrollController,
                      config: const QuillEditorConfig(
                        placeholder: "Start writing...",
                        padding: EdgeInsets.all(16),
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
