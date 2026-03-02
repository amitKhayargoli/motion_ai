// feature/transcript/presentation/pages/transcript_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:motion_ai/feature/notes/presentation/state/transcript_state.dart';
import 'package:motion_ai/feature/notes/presentation/view_model/transcript_view_model.dart';

class TranscriptPage extends ConsumerStatefulWidget {
  final String audioFileId;

  /// optional: show a nice title from audio filename
  final String? headerTitle;

  const TranscriptPage({
    super.key,
    required this.audioFileId,
    this.headerTitle,
  });

  @override
  ConsumerState<TranscriptPage> createState() => _TranscriptPageState();
}

class _TranscriptPageState extends ConsumerState<TranscriptPage> {
  static final _htmlTagRegex = RegExp(r'<[^>]*>', multiLine: true);

  static String _stripHtml(String html) {
    return html
        .replaceAll(_htmlTagRegex, '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .trim();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(transcriptViewModelProvider.notifier)
          .fetchTranscript(widget.audioFileId);
    });
  }

  Future<void> _refresh() async {
    await ref
        .read(transcriptViewModelProvider.notifier)
        .fetchTranscript(widget.audioFileId);
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(transcriptViewModelProvider);

    final note = st.note;
    final updated = (note?.updatedAt ?? note?.createdAt)?.toLocal();
    final time = updated != null
        ? DateFormat("dd MMM yyyy • HH:mm").format(updated)
        : "";

    final title = widget.headerTitle ?? note?.title ?? "Meeting Transcript";
    final statusText = (note?.status ?? "").toUpperCase();

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
              // ===== Top bar =====
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
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'sf_pro',
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              if (statusText.isNotEmpty)
                                _StatusChip(statusText: statusText),
                              if (statusText.isNotEmpty)
                                const SizedBox(width: 8),
                              if (time.isNotEmpty)
                                Text(
                                  time,
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontFamily: 'sf_pro',
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // ===== Body =====
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: Builder(
                    builder: (_) {
                      if (st.status == TranscriptStatus.loading &&
                          st.note == null) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (st.status == TranscriptStatus.error &&
                          st.note == null) {
                        return ListView(
                          children: [
                            const SizedBox(height: 140),
                            Center(
                              child: Text(
                                st.error ?? "Failed to load transcript",
                                style: const TextStyle(color: Colors.white70),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        );
                      }

                      if (note == null) {
                        return ListView(
                          children: const [
                            SizedBox(height: 140),
                            Center(
                              child: Text(
                                "No transcript found for this recording yet.",
                                style: TextStyle(color: Colors.white70),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        );
                      }

                      final transcript = _stripHtml(note.content.trim());
                      final isProcessing = (note.status ?? "") == "PROCESSING";

                      return ListView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.20),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.08)),
                            ),
                            child: SelectableText(
                              transcript.isEmpty
                                  ? (isProcessing
                                      ? "Transcribing... Please wait."
                                      : "Transcript is empty.")
                                  : transcript,
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'sf_pro',
                                fontSize: 15,
                                height: 1.5,
                              ),
                            ),
                          ),
                          if (st.status == TranscriptStatus.loading)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Row(
                                children: const [
                                  SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    "Refreshing…",
                                    style: TextStyle(
                                        color: Colors.white70,
                                        fontFamily: 'sf_pro'),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      );
                    },
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.statusText});
  final String statusText;

  @override
  Widget build(BuildContext context) {
    final isProcessing = statusText == "PROCESSING";
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isProcessing
            ? Colors.black.withOpacity(0.25)
            : Colors.black.withOpacity(0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Text(
        statusText,
        style: const TextStyle(
          color: Color(0xFFAEFB2A),
          fontFamily: 'sf_pro',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
