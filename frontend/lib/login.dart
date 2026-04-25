import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'register.dart';
import 'shared_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'services/api_service.dart';
import 'services/google_auth_service.dart';
import 'pages/components/navbar.dart';
import 'pages/admin_dashboard.dart';
import 'package:universal_html/html.dart' as html;

const Color kBrandRed = Color(0xFFE4252A);
const Color kBrandRedSoft = Color(0xFFFFE5E6);
const Color kBgLight = Color(0xFFFDF7F7);
const Color kTextDark = Color(0xFF1A1A1A);
const Color kTextMuted = Color(0xFF6B6B6B);

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GoogleAuthService _googleAuthService = GoogleAuthService();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) _renderGoogleButton();
  }

  void _renderGoogleButton() {
    Future.delayed(const Duration(milliseconds: 500), () {
      try {
        final container = html.document.getElementById('google-signin-button');
        if (container != null) print('Google Sign-In button container ready');
      } catch (e) {
        print('Error setting up Google button: $e');
      }
    });
  }

  void handleLogin() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('Please enter both email and password.', Colors.orange);
      return;
    }

    setState(() => isLoading = true);

    try {
      final result = await ApiService.loginUserWithWakeUp(
        email: email,
        password: password,
      );

      setState(() => isLoading = false);

      if (result['success'] == true) {
        _showSnackBar('Welcome back!', kBrandRed);

        final data = (result['data'] as Map<String, dynamic>?) ?? {};
        final userData = (data['user'] is Map<String, dynamic>)
            ? (data['user'] as Map<String, dynamic>)
            : data;

        final bool isAdmin = _isAdminFlag(data['is_admin']) ||
            _isAdminFlag(userData['is_admin']);

        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => isAdmin
                ? AdminHomePage(userData: userData)
                : UserHomePage(userData: userData),
          ),
        );
      } else {
        final errorText = (result['error'] ?? 'Login failed').toString();
        final serverError = errorText.toLowerCase();

        if (serverError.contains('doctype html')) {
          _showSnackBar(
            'Server Database Error. Please check backend logs.',
            Colors.red,
          );
          return;
        }

        if (serverError.contains('email') || serverError.contains('not found')) {
          _showSnackBar('Email not registered.', Colors.blueGrey);
        } else if (serverError.contains('password') ||
            serverError.contains('credentials')) {
          _showSnackBar('Incorrect password.', Colors.redAccent);
        } else {
          _showSnackBar(errorText, Colors.red);
        }
      }
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint("Login Error: $e");
      _showSnackBar('Connection failed. Is the server running?', Colors.red);
    }
  }

  bool _isAdminFlag(dynamic value) {
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    if (value is num) return value == 1;
    return false;
  }

  Future<void> handleGoogleSignIn() async {
    if (isLoading) return; // Prevent multiple calls
    setState(() => isLoading = true);
    try {
      final result = await _googleAuthService.signInWithGoogle();
      if (result != null && mounted) {
        _showSnackBar('Google Sign-In successful!', kBrandRed);
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => UserHomePage(userData: result),
          ),
        );
      } else if (mounted) {
        setState(() => isLoading = false);
        _showSnackBar('Google Sign-In cancelled.', Colors.orange);
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        _showSnackBar('Google Sign-In error: ${e.toString()}', Colors.red);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      title: "Login",
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: GlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kBrandRed.withOpacity(0.12),
                ),
                child: const Icon(
                  Icons.lock_person_rounded,
                  size: 44,
                  color: kBrandRed,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Welcome Back",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Sign in to continue",
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black.withOpacity(0.55),
                ),
              ),
              const SizedBox(height: 32),

              GlassTextField(
                hintText: "Email",
                icon: Icons.email_outlined,
                controller: emailController,
              ),
              const SizedBox(height: 16),
              GlassTextField(
                hintText: "Password",
                icon: Icons.lock_outline,
                isPassword: true,
                controller: passwordController,
              ),
              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kBrandRed,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: kBrandRed.withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: isLoading ? null : handleLogin,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "LOGIN",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: Divider(color: Colors.black.withOpacity(0.15)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "OR",
                      style: TextStyle(
                        color: Colors.black.withOpacity(0.5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(color: Colors.black.withOpacity(0.15)),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    side: BorderSide(color: Colors.black.withOpacity(0.1)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: isLoading ? null : handleGoogleSignIn,
                  icon: SvgPicture.network(
                    'https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg',
                    height: 22,
                  ),
                  label: const Text(
                    "Sign in with Google",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: TextStyle(color: Colors.black.withOpacity(0.65)),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RegisterPage(),
                      ),
                    ),
                    child: const Text(
                      "Register",
                      style: TextStyle(
                        color: kBrandRed,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}







  // void handleLogin() async {
  //   final email = emailController.text.trim();
  //   final password = passwordController.text.trim();
  //   if (email.isEmpty || password.isEmpty) {
  //     _showSnackBar('Please enter both email and password.', Colors.orange);
  //     return;
  //   }
  //   setState(() => isLoading = true);
  //   try {
  //     final result = await ApiService.loginUser(email: email, password: password);
  //     setState(() => isLoading = false);
  //     if (result['success']) {
  //       _showSnackBar('Welcome back! Logging you in...', kBrandRed);
  //       final userData = result['data']['user'];
  //       final isAdmin = result['data']['is_admin'] ?? false;
  //       await Future.delayed(const Duration(milliseconds: 500));
  //       if (!mounted) return;
  //       Navigator.pushReplacement(
  //         context,
  //         MaterialPageRoute(
  //           builder: (context) => isAdmin
  //               ? AdminHomePage(userData: userData)
  //               : UserHomePage(userData: userData),
  //         ),
  //       );
  //     } else {
  //       String serverError = result['error'].toString().toLowerCase();
  //       if (serverError.contains('email') || serverError.contains('not found')) {
  //         _showSnackBar('This email is not registered. Please create an account.', Colors.blueGrey);
  //       } else if (serverError.contains('password') || serverError.contains('credentials')) {
  //         _showSnackBar('Incorrect password. Please try again.', Colors.redAccent);
  //       } else {
  //         _showSnackBar(result['error'], Colors.red);
  //       }
  //     }
  //   } catch (e) {
  //     setState(() => isLoading = false);
  //     _showSnackBar('Server connection failed.', Colors.red);
  //   }
  // }
