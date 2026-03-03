import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:motion_ai/core/api/api_endpoints.dart';
import 'package:motion_ai/feature/auth/presentation/state/auth_state.dart';
import 'package:motion_ai/feature/auth/presentation/view_model/auth_viewmodel.dart';

class MyAccountPage extends ConsumerStatefulWidget {
  const MyAccountPage({super.key});

  @override
  ConsumerState<MyAccountPage> createState() => _MyAccountPageState();
}

class _MyAccountPageState extends ConsumerState<MyAccountPage> {
  final ImagePicker _imagePicker = ImagePicker();
  final List<XFile> _selectedMedia = [];

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (image != null) {
        setState(() {
          _selectedMedia.clear();
          _selectedMedia.add(image);
        });
        await ref
            .read(authViewModelProvider.notifier)
            .uploadImage(File(image.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gallery access denied.')),
        );
      }
    }
  }

  void _showEditUsernameDialog(String currentUsername) {
    final controller = TextEditingController(text: currentUsername);
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E3A0F),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Edit Username',
            style: TextStyle(color: Colors.white, fontFamily: 'sf_pro'),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(color: Colors.white, fontFamily: 'sf_pro'),
            cursorColor: const Color(0xFFAEFB2A),
            decoration: InputDecoration(
              hintText: 'New username',
              hintStyle: const TextStyle(color: Colors.white54),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: Colors.white.withOpacity(0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFAEFB2A)),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.white60)),
            ),
            TextButton(
              onPressed: () async {
                final newName = controller.text.trim();
                if (newName.isNotEmpty && newName != currentUsername) {
                  Navigator.pop(dialogCtx);
                  await ref
                      .read(authViewModelProvider.notifier)
                      .updateUser(username: newName);
                }
              },
              child: const Text('Save',
                  style: TextStyle(color: Color(0xFFAEFB2A))),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final user = authState.user;

    String? profilePictureUrl = user?.profilePicture;
    final String uploadBase = ApiEndpoints.baseUrl.replaceFirst('/api', '');

    if (authState.status == AuthStatus.loaded &&
        authState.uploadPhotoName != null) {
      profilePictureUrl = '$uploadBase/${authState.uploadPhotoName}';
    } else if (profilePictureUrl != null &&
        !profilePictureUrl.startsWith('http')) {
      profilePictureUrl = '$uploadBase$profilePictureUrl';
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
              // Top bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'MY ACCOUNT',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white60,
                          letterSpacing: 2,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'sf_pro',
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    children: [
                      // Profile picture with camera edit button
                      SizedBox(
                        height: 110,
                        width: 110,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              height: 100,
                              width: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color:
                                      const Color(0xFFAEFB2A).withOpacity(0.5),
                                  width: 3,
                                ),
                              ),
                              child: CircleAvatar(
                                backgroundColor: Colors.white10,
                                backgroundImage: _selectedMedia.isNotEmpty
                                    ? FileImage(
                                        File(_selectedMedia.last.path))
                                    : profilePictureUrl != null &&
                                            profilePictureUrl.isNotEmpty
                                        ? NetworkImage(profilePictureUrl)
                                        : const AssetImage(
                                                'assets/images/default_avatar.png')
                                            as ImageProvider,
                              ),
                            ),
                            Positioned(
                              right: -4,
                              bottom: 0,
                              child: SizedBox(
                                height: 36,
                                width: 36,
                                child: TextButton(
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(50),
                                      side: BorderSide(
                                          color:
                                              Colors.white.withOpacity(0.2)),
                                    ),
                                    backgroundColor: const Color(0xFF2F5D15),
                                  ),
                                  onPressed: _pickFromGallery,
                                  child: const Icon(Icons.camera_alt,
                                      color: Color(0xFFAEFB2A), size: 18),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      Text(
                        user?.username ?? 'User Name',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'sf_pro',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? 'email@motion.ai',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                          fontFamily: 'sf_pro',
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Account Information card
                      _SectionCard(
                        title: 'Account Information',
                        children: [
                          _InfoRow(
                            label: 'Username',
                            value: user?.username ?? '-',
                            onEdit: () => _showEditUsernameDialog(
                                user?.username ?? ''),
                          ),
                          const _CardDivider(),
                          _InfoRow(
                            label: 'Email',
                            value: user?.email ?? '-',
                          ),
                          const _CardDivider(),
                          _InfoRow(
                            label: 'Member Since',
                            value: user?.createdAt != null
                                ? DateFormat('MMM d, yyyy')
                                    .format(user!.createdAt!)
                                : '-',
                          ),
                          const _CardDivider(),
                          _InfoRow(
                            label: 'User ID',
                            value: user?.userId != null
                                ? (user!.userId!.length > 12
                                    ? '${user.userId!.substring(0, 12)}...'
                                    : user.userId!)
                                : '-',
                          ),
                        ],
                      ),
                    ],
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

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              fontFamily: 'sf_pro',
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            color: Colors.white.withOpacity(0.05),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onEdit;

  const _InfoRow({required this.label, required this.value, this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 14,
              fontFamily: 'sf_pro',
            ),
          ),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    value,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontFamily: 'sf_pro',
                    ),
                  ),
                ),
                if (onEdit != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: GestureDetector(
                      onTap: onEdit,
                      child: const Icon(Icons.edit,
                          color: Color(0xFFAEFB2A), size: 16),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardDivider extends StatelessWidget {
  const _CardDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(color: Colors.white.withOpacity(0.1), height: 1);
  }
}
