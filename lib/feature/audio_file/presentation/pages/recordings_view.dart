import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:motion_ai/core/sync/audio_auto_sync.dart';
import 'package:motion_ai/feature/audio_file/domain/entities/audio_file_entity.dart';
import 'package:motion_ai/feature/audio_file/presentation/pages/audio_player_page.dart';
import 'package:motion_ai/feature/audio_file/presentation/state/audio_state.dart';
import 'package:motion_ai/feature/audio_file/presentation/view_model/audio_view_model.dart';
import 'package:motion_ai/feature/home/presentation/pages/widgets/gradient_scaffold_widget.dart';

class RecordingsView extends ConsumerStatefulWidget {
  const RecordingsView({super.key});

  @override
  ConsumerState<RecordingsView> createState() => _RecordingsViewState();
}

class _RecordingsViewState extends ConsumerState<RecordingsView> {
  bool _isMultiSelect = false;
  final Set<String> _selectedIds = {};

  void _toggleMultiSelect() {
    setState(() {
      _isMultiSelect = !_isMultiSelect;
      if (!_isMultiSelect) _selectedIds.clear();
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _isMultiSelect = false;
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _showRenameDialog(AudioFileEntity audio) {
    final controller = TextEditingController(text: audio.displayName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A2900),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Rename Recording',
          style: TextStyle(color: Colors.white, fontFamily: 'sf_pro'),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontFamily: 'sf_pro'),
          decoration: InputDecoration(
            hintText: 'Enter new name',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: Colors.white.withOpacity(0.08),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFFAEFB2A), width: 1.5),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54, fontFamily: 'sf_pro'),
            ),
          ),
          FilledButton(
            onPressed: () {
              final newTitle = controller.text.trim();
              if (newTitle.isNotEmpty && newTitle != audio.displayName) {
                ref
                    .read(audioViewModelProvider.notifier)
                    .updateAudio(audioId: audio.id, title: newTitle);
              }
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFAEFB2A),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Save',
              style:
                  TextStyle(fontFamily: 'sf_pro', fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(AudioFileEntity audio) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A2900),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Recording?',
          style: TextStyle(color: Colors.white, fontFamily: 'sf_pro'),
        ),
        content: Text(
          'Are you sure you want to delete "${audio.displayName}"?',
          style: const TextStyle(color: Colors.white70, fontFamily: 'sf_pro'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54, fontFamily: 'sf_pro'),
            ),
          ),
          FilledButton(
            onPressed: () {
              ref.read(audioViewModelProvider.notifier).deleteAudio(audio.id);
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Delete',
              style:
                  TextStyle(fontFamily: 'sf_pro', fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmBulkDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A2900),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Selected?',
          style: TextStyle(color: Colors.white, fontFamily: 'sf_pro'),
        ),
        content: Text(
          'Delete ${_selectedIds.length} recording(s)?',
          style: const TextStyle(color: Colors.white70, fontFamily: 'sf_pro'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54, fontFamily: 'sf_pro'),
            ),
          ),
          FilledButton(
            onPressed: () {
              ref
                  .read(audioViewModelProvider.notifier)
                  .deleteMultipleAudios(_selectedIds.toList());
              Navigator.pop(ctx);
              setState(() {
                _isMultiSelect = false;
                _selectedIds.clear();
              });
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Delete All',
              style:
                  TextStyle(fontFamily: 'sf_pro', fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('MMM d, h:mm a').format(date);
  }

  String _formatSeconds(int? seconds) {
    if (seconds == null) return '--:--';
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final audioState = ref.watch(audioViewModelProvider);
    final audios = audioState.audios;
    final syncState = ref.watch(audioAutoSyncProvider);

    return GradientScaffold(
      useDashboardGradient: true,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        'RECORDINGS',
                        style: TextStyle(
                          fontFamily: 'sf_pro',
                          color: Colors.white70,
                          fontSize: 14,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildSyncPill(syncState),
                    ],
                  ),
                  if (_isMultiSelect)
                    Row(
                      children: [
                        Text(
                          '${_selectedIds.length} selected',
                          style: const TextStyle(
                            color: Color(0xFFAEFB2A),
                            fontFamily: 'sf_pro',
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _selectedIds.isNotEmpty
                              ? _confirmBulkDelete
                              : null,
                          icon: Icon(
                            Icons.delete_outline,
                            color: _selectedIds.isNotEmpty
                                ? Colors.redAccent
                                : Colors.white38,
                          ),
                        ),
                        IconButton(
                          onPressed: _toggleMultiSelect,
                          icon: const Icon(Icons.close, color: Colors.white70),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _buildContent(audioState, audios),
            ),

            // Bottom padding for FAB / nav bar
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(AudioState audioState, List<AudioFileEntity>? audios) {
    if (audioState.status == AudioStatus.loading &&
        (audios == null || audios.isEmpty)) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFAEFB2A)),
      );
    }

    if (audios == null || audios.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.mic_none,
              size: 64,
              color: Colors.white.withOpacity(0.15),
            ),
            const SizedBox(height: 16),
            const Text(
              'No recordings yet',
              style: TextStyle(
                color: Colors.white54,
                fontFamily: 'sf_pro',
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap the mic button to start recording',
              style: TextStyle(
                color: Colors.white30,
                fontFamily: 'sf_pro',
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(audioViewModelProvider.notifier).fetchAudios(),
      color: const Color(0xFFAEFB2A),
      backgroundColor: const Color(0xFF1A2900),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: audios.length,
        itemBuilder: (context, index) {
          final audio = audios[index];
          return _buildRecordingCard(audio);
        },
      ),
    );
  }

  Widget _buildSyncPill(AudioSyncState syncState) {
    if (syncState.isSyncing) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFAEFB2A).withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: Color(0xFFAEFB2A),
              ),
            ),
            SizedBox(width: 4),
            Text(
              'Syncing',
              style: TextStyle(
                color: Color(0xFFAEFB2A),
                fontFamily: 'sf_pro',
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    if (syncState.lastSuccessAt != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, size: 10, color: Colors.white38),
            SizedBox(width: 4),
            Text(
              'Synced',
              style: TextStyle(
                color: Colors.white38,
                fontFamily: 'sf_pro',
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildRecordingCard(AudioFileEntity audio) {
    final isSelected = _selectedIds.contains(audio.id);

    return Dismissible(
      key: ValueKey(audio.id),
      direction:
          _isMultiSelect ? DismissDirection.none : DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      confirmDismiss: (direction) async {
        _confirmDelete(audio);
        return false;
      },
      child: GestureDetector(
        onLongPress: () {
          if (!_isMultiSelect) {
            setState(() {
              _isMultiSelect = true;
              _selectedIds.add(audio.id);
            });
          }
        },
        onTap: () {
          if (_isMultiSelect) {
            _toggleSelection(audio.id);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AudioPlayerPage(audio: audio),
              ),
            );
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFAEFB2A).withOpacity(0.1)
                : Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
            border: isSelected
                ? Border.all(color: const Color(0xFFAEFB2A), width: 1.5)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (_isMultiSelect) ...[
                    Checkbox(
                      value: isSelected,
                      onChanged: (_) => _toggleSelection(audio.id),
                      activeColor: const Color(0xFFAEFB2A),
                      checkColor: Colors.black,
                      side: const BorderSide(color: Colors.white38),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],

                  // Recording icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFAEFB2A).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.graphic_eq,
                      color: Color(0xFFAEFB2A),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Title + metadata
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          audio.displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'sf_pro',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _formatSeconds(audio.durationSeconds),
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontFamily: 'sf_pro',
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatDate(audio.uploadedAt),
                              style: const TextStyle(
                                color: Colors.white38,
                                fontFamily: 'sf_pro',
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  if (!_isMultiSelect) ...[
                    // Edit button
                    IconButton(
                      onPressed: () => _showRenameDialog(audio),
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: Colors.white38,
                        size: 20,
                      ),
                      splashRadius: 20,
                    ),
                    // Play hint
                    const Icon(
                      Icons.chevron_right,
                      color: Colors.white24,
                      size: 20,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
