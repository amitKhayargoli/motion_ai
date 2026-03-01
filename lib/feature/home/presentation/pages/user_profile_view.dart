import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:motion_ai/core/api/api_endpoints.dart';
import 'package:motion_ai/core/providers/providers.dart';
import 'package:motion_ai/core/utils/snackbar_utils.dart';
import 'package:motion_ai/feature/auth/presentation/pages/login_page.dart';
import 'package:motion_ai/feature/auth/presentation/state/auth_state.dart';
import 'package:motion_ai/feature/auth/presentation/view_model/auth_viewmodel.dart';
import 'package:motion_ai/feature/home/presentation/pages/help_center_page.dart';
import 'package:motion_ai/feature/home/presentation/pages/my_account_page.dart';
import 'package:motion_ai/feature/home/presentation/pages/settings_page.dart';
import 'package:path_provider/path_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final List<XFile> _selectedMedia = [];
  final ImagePicker _imagePicker = ImagePicker();
  final Color _accentColor = const Color(0xFFAEFB2A);

  @override
  void initState() {
    super.initState();
    // Fetch fresh user profile from remote (auth/me) & cache in Hive
    Future.microtask(
      () => ref.read(authViewModelProvider.notifier).getCurrentUser(),
    );
  }

  // ===================== LOGOUT =====================
  Future<void> _confirmAndLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E3A0F),
        title: const Text("Log out?", style: TextStyle(color: Colors.white)),
        content: const Text("Are you sure you want to log out?",
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                const Text("Cancel", style: TextStyle(color: Colors.white60)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text("Log out",
                style: TextStyle(
                    color: _accentColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;
    await ref.read(authViewModelProvider.notifier).logout();
    await ref.read(hiveServiceProvider).clearActiveUser();
    await ref.read(userSessionServiceProvider).clearUserSession();
  }

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
      if (mounted) SnackbarUtils.showError(context, "Gallery access denied.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);

    ref.listen<AuthState>(authViewModelProvider, (prev, next) {
      if (next.status == AuthStatus.unauthenticated) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    });

    // Construct the full URL for the profile picture
    String? profilePictureUrl = authState.user?.profilePicture;

    // Derive upload base from the API base URL (strip /api suffix)
    final String uploadBase = ApiEndpoints.baseUrl.replaceFirst('/api', '');

    if (authState.status == AuthStatus.loaded &&
        authState.uploadPhotoName != null) {
      profilePictureUrl = '$uploadBase/${authState.uploadPhotoName}';
    } else if (profilePictureUrl != null &&
        !profilePictureUrl.startsWith('http')) {
      profilePictureUrl = '$uploadBase$profilePictureUrl';
    }

    final isLoading =
        authState.status == AuthStatus.loading && authState.user == null;

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
              // ======= TOP BAR =======
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  "USER PROFILE",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    letterSpacing: 2,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'sf_pro',
                  ),
                ),
              ),

              if (isLoading)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFAEFB2A),
                    ),
                  ),
                )
              else
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      children: [
                        ProfilePic(
                          onEditPressed: _pickFromGallery,
                          profilePictureUrl: profilePictureUrl,
                          selectedMedia: _selectedMedia,
                          accentColor: _accentColor,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          authState.user?.username ?? "User Name",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'sf_pro',
                          ),
                        ),
                        Text(
                          authState.user?.email ?? "email@motion.ai",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 30),

                        // ======= MENU ITEMS =======
                        ProfileMenu(
                          text: "My Account",
                          icon: Icons.person_outline,
                          press: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const MyAccountPage()),
                            );
                          },
                        ),
                        ProfileMenu(
                          text: "Settings",
                          icon: Icons.settings_outlined,
                          press: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const SettingsPage()),
                            );
                          },
                        ),
                        ProfileMenu(
                          text: "Help Center",
                          icon: Icons.help_outline,
                          press: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const HelpCenterPage()),
                            );
                          },
                        ),
                        ProfileMenu(
                          text: "Log Out",
                          icon: Icons.logout,
                          isLogout: true,
                          press: authState.status == AuthStatus.loading
                              ? null
                              : _confirmAndLogout,
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

class ProfilePic extends StatefulWidget {
  const ProfilePic({
    super.key,
    required this.onEditPressed,
    this.selectedMedia,
    this.profilePictureUrl,
    required this.accentColor,
  });

  final VoidCallback onEditPressed;
  final List<XFile>? selectedMedia;
  final String? profilePictureUrl;
  final Color accentColor;

  @override
  State<ProfilePic> createState() => _ProfilePicState();
}

class _ProfilePicState extends State<ProfilePic> {
  File? _cachedFile;
  static const _cacheFileName = 'profile_picture_cache.jpg';

  @override
  void initState() {
    super.initState();
    _loadCachedImage();
  }

  Future<File> get _cacheFile async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_cacheFileName');
  }

  Future<void> _loadCachedImage() async {
    final file = await _cacheFile;
    if (await file.exists()) {
      if (mounted) setState(() => _cachedFile = file);
    }
  }

  Future<void> _cacheImageBytes(Uint8List bytes) async {
    final file = await _cacheFile;
    await file.writeAsBytes(bytes);
    if (mounted) setState(() => _cachedFile = file);
  }

  @override
  Widget build(BuildContext context) {
    final hasLocalFile =
        widget.selectedMedia != null && widget.selectedMedia!.isNotEmpty;
    final hasNetworkUrl = widget.profilePictureUrl != null &&
        widget.profilePictureUrl!.isNotEmpty;

    Widget avatarChild;

    if (hasLocalFile) {
      avatarChild = CircleAvatar(
        backgroundColor: Colors.white10,
        backgroundImage: FileImage(File(widget.selectedMedia!.first.path)),
      );
    } else if (hasNetworkUrl) {
      avatarChild = ClipOval(
        child: Image.network(
          widget.profilePictureUrl!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (frame != null) {
              // Image loaded from network — cache it
              _cacheNetworkImage(widget.profilePictureUrl!);
            }
            return child;
          },
          errorBuilder: (context, error, stackTrace) {
            // Offline or error — try cached file
            if (_cachedFile != null && _cachedFile!.existsSync()) {
              return Image.file(
                _cachedFile!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              );
            }
            return const CircleAvatar(
              backgroundColor: Colors.white10,
              backgroundImage: AssetImage('assets/images/default_avatar.png'),
            );
          },
        ),
      );
    } else {
      avatarChild = const CircleAvatar(
        backgroundColor: Colors.white10,
        backgroundImage: AssetImage('assets/images/default_avatar.png'),
      );
    }

    return SizedBox(
      height: 115,
      width: 115,
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: widget.accentColor.withOpacity(0.5), width: 3),
              boxShadow: [
                BoxShadow(
                  color: widget.accentColor.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                )
              ],
            ),
            child: avatarChild,
          ),
          Positioned(
            right: -4,
            bottom: 0,
            child: SizedBox(
              height: 40,
              width: 40,
              child: TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                    side: BorderSide(color: Colors.white.withOpacity(0.2)),
                  ),
                  backgroundColor: const Color(0xFF2F5D15),
                ),
                onPressed: widget.onEditPressed,
                child:
                    Icon(Icons.camera_alt, color: widget.accentColor, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isCaching = false;
  String? _cachedUrl;

  Future<void> _cacheNetworkImage(String url) async {
    if (_isCaching) return;
    if (_cachedUrl == url) return; // already cached this URL in this session
    _isCaching = true;
    try {
      final httpClient = HttpClient();
      final request = await httpClient.getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode == 200) {
        final bytes = await consolidateHttpClientResponseBytes(response);
        await _cacheImageBytes(bytes);
        _cachedUrl = url;
      }
      httpClient.close();
    } catch (_) {
      // Silently fail — cached version will be used next time
    } finally {
      _isCaching = false;
    }
  }
}

class ProfileMenu extends StatelessWidget {
  const ProfileMenu({
    super.key,
    required this.text,
    required this.icon,
    this.press,
    this.isLogout = false,
  });

  final String text;
  final IconData icon;
  final VoidCallback? press;
  final bool isLogout;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          color: Colors.white.withOpacity(0.05), // Glass effect
        ),
        child: TextButton(
          style: TextButton.styleFrom(
            padding: const EdgeInsets.all(20),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
          onPressed: press,
          child: Row(
            children: [
              Icon(
                icon,
                color: isLogout ? Colors.redAccent : const Color(0xFFAEFB2A),
                size: 22,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    color: isLogout
                        ? Colors.redAccent
                        : Colors.white.withOpacity(0.8),
                    fontSize: 16,
                    fontFamily: 'sf_pro',
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white.withOpacity(0.2),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
