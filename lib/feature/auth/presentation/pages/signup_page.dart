import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:motion_ai/core/utils/snackbar_utils.dart';
import 'package:motion_ai/core/widgets/custom_button.dart';
import 'package:motion_ai/feature/auth/presentation/pages/login_page.dart';
import 'package:motion_ai/feature/auth/presentation/state/auth_state.dart';
import 'package:motion_ai/feature/auth/presentation/view_model/auth_viewmodel.dart';

import '../../data/models/auth_hive_model.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  bool _rememberMe = false;
  bool _passwordVisible = false;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  Future<void> _handleSignup() async {
    ref.read(authViewModelProvider.notifier).clearError();

    if (_formKey.currentState!.validate()) {
      ref
          .read(authViewModelProvider.notifier)
          .register(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
    }
    final box = Hive.box<AuthHiveModel>('authBox');
    print('--- All Hive Users ---');
    for (var user in box.values) {
      print('Email: ${user.email}, Password: ${user.password}');
    }
  }

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: 'johndoe@gmail.com');
    _passwordController = TextEditingController(text: 'password');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);

    // listen for auth state changes
    // ref.read
    // ref.watch

    ref.listen<AuthState>(authViewModelProvider, (previous, next) {
      if (next.status == AuthStatus.error) {
        SnackbarUtils.showError(
          context,
          next.errorMessage ?? "Registration failed",
        );
      } else if (next.status == AuthStatus.registered) {
        SnackbarUtils.showSuccess(
          context,
          next.errorMessage ?? "Registration Successful",
        );
      }
    });

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF273E00), Color(0xFF020200)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.54],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 50),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [Color(0x26A2FF00), Colors.transparent],
                      radius: 2.5,
                      stops: [0.0, 1.0],
                    ),
                  ),
                  child: Image.asset('assets/images/logo.png', height: 60),
                ),
                const Text(
                  'Sign up a new\nAccount',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'sf_pro',
                    fontSize: 34,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Already a user? ",
                      style: TextStyle(
                        fontFamily: 'sf_pro',
                        fontSize: 15,
                        color: Colors.white70,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        // Navigate to Sign Up screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginPage(),
                          ),
                        );
                      },
                      child: const Text(
                        'Sign in',
                        style: TextStyle(
                          fontFamily: 'sf_pro',
                          fontSize: 15,
                          color: Color(0xFF6A9BEE),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildTextField(
                        label: 'Email',
                        controller: _emailController,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Email cannot be empty';
                          }
                          // Basic email regex
                          final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                          if (!emailRegex.hasMatch(value.trim())) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                        _buildTextField(
                          label: 'Password',
                          controller: _passwordController,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Password cannot be empty';
                            }
                            if (value.trim().length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                          obscureText: !_passwordVisible,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _passwordVisible
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: Colors.white54,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _passwordVisible = !_passwordVisible;
                              });
                            },
                          ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Theme(
                          data: ThemeData(
                            unselectedWidgetColor: Colors.white54,
                          ),
                          child: Checkbox(
                            value: _rememberMe,
                            onChanged: (value) {
                              setState(() {
                                _rememberMe = value ?? false;
                              });
                            },
                            checkColor: Colors.black,
                            activeColor: Colors.white,
                            side: const BorderSide(color: Colors.white54),
                          ),
                        ),
                        const Text(
                          'Remember me',
                          style: TextStyle(
                            fontFamily: 'sf_pro',
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),


                CustomButton(
                  text: 'Sign Up',
                  isLoading: authState.status == AuthStatus.loading,
                  onPressed: _handleSignup,
                ),

                const SizedBox(height: 12),
                const Row(
                  children: [
                    Expanded(child: Divider(color: Colors.white24)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        'Or',
                        style: TextStyle(
                          color: Colors.white70,
                          fontFamily: 'sf_pro',
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.white24)),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Image.asset(
                    'assets/images/google_logo.png',
                    height: 24,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.g_mobiledata, color: Colors.white),
                  ),
                  label: const Text(
                    'Continue with Google',
                    style: TextStyle(
                      fontFamily: 'sf_pro',
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Image.asset(
                    'assets/images/facebook_logo.png',
                    height: 24,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.facebook, color: Color(0xFF1877F2)),
                  ),
                  label: const Text(
                    'Continue with Facebook',
                    style: TextStyle(
                      fontFamily: 'sf_pro',
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'sf_pro',
            color: Colors.white70,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'sf_pro',
            fontSize: 16,
          ),
          validator: validator,
          decoration: InputDecoration(
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF98C149)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
          ),
        ),
      ],
    );
  }
}
