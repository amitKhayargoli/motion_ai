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
  Timer? _draftTimer;
  bool _draftDirty = false;
  bool _draftSaving = false;

  static const _draftDebounce = Duration(milliseconds: 700);
  static const _draftBoxName = "notes_drafts";
  final Color _accentColor = const Color(0xFFB0B0B0);

  String get _modeTitle => widget.note == null ? "NEW NOTE" : "EDIT NOTE";

  String _draftKey(String workspaceId) {
    if (widget.note == null) return "draft_create__ws_$workspaceId";
    return "draft_edit__${widget.note!.id}__ws_$workspaceId";
  }

  @override
  void initState() {
    super.initState();
    _controller = QuillController.basic();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final ws = ref.read(workspaceViewModelProvider).selected;
      final workspaceId = ws?.id;

      if (widget.note != null) {
        _titleCtrl.text = widget.note!.title;
        _loadHtmlIntoEditor(widget.note!.content);
      }

      if (workspaceId != null) {
        await _loadDraft(workspaceId);
      }

      _attachDraftListeners(workspaceId);
      if (mounted) setState(() {});
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
      final delta = HtmlToDelta().convert(html);
      final doc = Document.fromDelta(delta);
      _controller = QuillController(
        document: doc,
        selection: const TextSelection.collapsed(offset: 0),
      );
    } catch (e) {
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
      ConverterOptions(multiLineParagraph: true),
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
    if (ws?.id == null || !_draftDirty) return;

    if (mounted) setState(() => _draftSaving = true);
    try {
      final box = await Hive.openBox(_draftBoxName);
      await box.put(_draftKey(ws!.id), {
        "title": _titleCtrl.text,
        "delta": _controller.document.toDelta().toJson(),
        "updatedAt": DateTime.now().toIso8601String(),
      });
      _draftDirty = false;
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
          _controller = QuillController(
            document: Document.fromJson(deltaJson),
            selection: const TextSelection.collapsed(offset: 0),
          );
        }
      }
    } catch (_) {}
  }

  Future<void> _clearDraft() async {
    final ws = ref.read(workspaceViewModelProvider).selected;
    if (ws == null) return;
    final box = await Hive.openBox(_draftBoxName);
    await box.delete(_draftKey(ws.id));
  }

  // ===================== SAVE =====================

  Future<void> _handleSave() async {
    final ws = ref.read(workspaceViewModelProvider).selected;
    if (ws == null) return;

    final title = _titleCtrl.text.trim();
    if (title.isEmpty || _isEditorEmpty()) {
      SnackbarUtils.showError(context, "Title and content are required");
      return;
    }

    setState(() => _saving = true);
    try {
      await _saveDraftNow();
      final htmlContent = _docToHtml();
      final vm = ref.read(notesViewModelProvider.notifier);

      final result = widget.note == null
          ? await vm.createNote(
              workspaceId: ws.id, title: title, content: htmlContent)
          : await vm.updateNote(
              noteId: widget.note!.id, title: title, content: htmlContent);

      if (!mounted) return;
      if (result != null) {
        await _clearDraft();
        Navigator.pop(context, result);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          child: Column(
            children: [
              // ======= TOP BAR =======
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white, size: 20),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          _modeTitle,
                          style: const TextStyle(
                            color: Colors.white60,
                            letterSpacing: 2,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'sf_pro',
                          ),
                        ),
                      ),
                    ),
                    _saving
                        ? SizedBox(
                            width: 48,
                            child: Center(
                                child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        color: _accentColor, strokeWidth: 2))))
                        : TextButton(
                            onPressed: _handleSave,
                            child: Text("SAVE",
                                style: TextStyle(
                                    color: _accentColor,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'sf_pro')),
                          ),
                  ],
                ),
              ),

              if (_draftSaving)
                LinearProgressIndicator(
                    backgroundColor: Colors.transparent,
                    color: _accentColor.withOpacity(0.3),
                    minHeight: 1),

              // ======= TITLE FIELD (Glassmorphic) =======
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _titleCtrl,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'sf_pro'),
                  cursorColor: _accentColor,
                  decoration: InputDecoration(
                    hintText: "Title",
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          BorderSide(color: Colors.white.withOpacity(0.1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          BorderSide(color: Colors.white.withOpacity(0.1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          BorderSide(color: _accentColor.withOpacity(0.5)),
                    ),
                  ),
                ),
              ),

              // ======= TOOLBAR (Glassmorphic) =======
              SizedBox(
                width: double.infinity,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: QuillSimpleToolbar(
                    controller: _controller,
                    config: QuillSimpleToolbarConfig(
                      showBoldButton: true,
                      showItalicButton: true,
                      showUnderLineButton: false,
                      showStrikeThrough: false,
                      showListBullets: true,
                      showListNumbers: false,
                      showListCheck: true,
                      showHeaderStyle: true,
                      showQuote: false,
                      showLink: true,
                      showCodeBlock: true,
                      showInlineCode: false,
                      showFontSize: false,
                      showFontFamily: false,
                      showColorButton: false,
                      showBackgroundColorButton: false,
                      showAlignmentButtons: false,
                      showSmallButton: false,
                      showIndent: true,
                      showSearchButton: false,
                      showSubscript: false,
                      showSuperscript: false,
                      showClipboardCut: false,
                      showClipboardCopy: false,
                      showClipboardPaste: false,
                      showDirection: false,
                      showUndo: false,
                      showRedo: false,
                      showClearFormat: true,
                      buttonOptions: QuillSimpleToolbarButtonOptions(
                        base: QuillToolbarBaseButtonOptions(
                          iconTheme: QuillIconTheme(
                            iconButtonSelectedData: IconButtonData(
                                color: Colors.white,
                                style: IconButton.styleFrom(
                                    backgroundColor: Colors.white12)),
                            iconButtonUnselectedData:
                                const IconButtonData(color: Colors.white54),
                          ),
                        ),
                        selectHeaderStyleDropdownButton:
                            QuillToolbarSelectHeaderStyleDropdownButtonOptions(
                          textStyle: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontFamily: 'sf_pro',
                          ),
                          width: 120,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ======= EDITOR (Glassmorphic, fixed width) =======
              Expanded(
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: DefaultTextStyle(
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontFamily: 'sf_pro'),
                      child: QuillEditor(
                        controller: _controller,
                        focusNode: _focusNode,
                        scrollController: _scrollController,
                        config: QuillEditorConfig(
                          placeholder: "Write something brilliant...",
                          padding: const EdgeInsets.all(20),
                          textSelectionThemeData: TextSelectionThemeData(
                            selectionColor: _accentColor.withOpacity(0.3),
                            selectionHandleColor: _accentColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
