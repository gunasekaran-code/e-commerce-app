import 'package:flutter/material.dart';
import 'login.dart';
import 'shared_ui.dart';
import 'services/api_service.dart';

const Color kBrandRed = Color(0xFFE4252A);
const Color kBrandRedSoft = Color(0xFFFFE5E6);
const Color kBgLight = Color(0xFFFDF7F7);
const Color kTextDark = Color(0xFF1A1A1A);
const Color kTextMuted = Color(0xFF6B6B6B);

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  bool isLoading = false;
  String? nameError;
  String? emailError;
  String? passwordError;

  // Email validation regex
  final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  // Username validation regex (3-20 chars, letters, numbers, underscore only)
  final RegExp usernameRegex = RegExp(
    r'^[a-zA-Z0-9_]{3,20}$',
  );

  String? validateName(String value) {
    if (value.isEmpty) {
      return '❌ Name is required';
    }
    
    if (value.contains(' ')) {
      return '❌ Spaces are not allowed in username';
    }
    
    if (value.length < 3) {
      return '❌ Name must be at least 3 characters';
    }
    
    if (value.length > 20) {
      return '❌ Name must be maximum 20 characters';
    }
    
    if (!usernameRegex.hasMatch(value)) {
      return '❌ Only letters, numbers, and underscores (_) are allowed';
    }
    
    return null;
  }

  String? validateEmail(String value) {
    if (value.isEmpty) {
      return '❌ Email is required';
    }
    
    if (!emailRegex.hasMatch(value)) {
      return '❌ Please enter a valid email address (e.g., user@gmail.com)';
    }
    
    return null;
  }

  String? validatePassword(String value) {
    if (value.isEmpty) {
      return '❌ Password is required';
    }
    
    return null;
  }

  void handleRegister() async {
    // Clear previous errors
    setState(() {
      nameError = null;
      emailError = null;
      passwordError = null;
    });

    // Validate all fields
    final nameValidation = validateName(nameController.text.trim());
    final emailValidation = validateEmail(emailController.text.trim());
    final passwordValidation = validatePassword(passwordController.text.trim());

    if (nameValidation != null || emailValidation != null || passwordValidation != null) {
      setState(() {
        nameError = nameValidation;
        emailError = emailValidation;
        passwordError = passwordValidation;
      });
      
      // Show first error in snackbar
      String errorMsg = nameValidation ?? emailValidation ?? passwordValidation ?? '';
      _showSnackBar(errorMsg, Colors.red);
      return;
    }

    setState(() => isLoading = true);
    print('🔵 Button pressed, calling API...');

    try {
      final result = await ApiService.registerUser(
        fullName: nameController.text.trim(),
        email: emailController.text.trim().toLowerCase(), // Convert to lowercase
        password: passwordController.text.trim(),
      );

      setState(() => isLoading = false);
      print('🔵 API Result: $result');

      if (result['success']) {
        _showSnackBar('✅ Registration Successful!', Colors.green);
        await Future.delayed(const Duration(seconds: 1));
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      } else {
        String errorMessage = '❌ Registration failed. Please try again.';
        
        // Handle API errors
        if (result['error'] is Map) {
          final errors = result['error'] as Map;
          
          // Email errors
          if (errors['email'] != null) {
            List<dynamic> emailErrors = errors['email'];
            if (emailErrors.isNotEmpty) {
              if (emailErrors[0].toString().toLowerCase().contains('already exists') ||
                  emailErrors[0].toString().toLowerCase().contains('already taken')) {
                errorMessage = '❌ This email is already registered. Please use another email.';
                setState(() => emailError = 'Email already exists');
              } else {
                errorMessage = '❌ Email: ${emailErrors[0]}';
                setState(() => emailError = emailErrors[0].toString());
              }
            }
          }
          
          // Username/Name errors
          if (errors['name'] != null || errors['full_name'] != null || errors['username'] != null) {
            List<dynamic> nameErrors = errors['name'] ?? errors['full_name'] ?? errors['username'];
            if (nameErrors.isNotEmpty) {
              if (nameErrors[0].toString().toLowerCase().contains('already exists') ||
                  nameErrors[0].toString().toLowerCase().contains('already taken')) {
                errorMessage = '❌ This username is already taken. Please choose another one.';
                setState(() => nameError = 'Username already exists');
              } else {
                errorMessage = '❌ Name: ${nameErrors[0]}';
                setState(() => nameError = nameErrors[0].toString());
              }
            }
          }
          
          // Password errors
          if (errors['password'] != null) {
            List<dynamic> passwordErrors = errors['password'];
            if (passwordErrors.isNotEmpty) {
              errorMessage = '❌ Password: ${passwordErrors[0]}';
              setState(() => passwordError = passwordErrors[0].toString());
            }
          }
        } else if (result['error'] is String) {
          errorMessage = '❌ ${result['error']}';
        }
        
        _showSnackBar(errorMessage, Colors.red, duration: const Duration(seconds: 5));
      }
    } catch (e) {
      setState(() => isLoading = false);
      print('🔴 Exception in handleRegister: $e');
      _showSnackBar('❌ Network error. Please check your connection and try again.', 
          Colors.red,
          duration: const Duration(seconds: 5));
    }
  }

  void _showSnackBar(String message, Color color,
      {Duration duration = const Duration(seconds: 3)}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: duration,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      title: "Register",
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
                  Icons.person_add_alt_1_rounded,
                  size: 44,
                  color: kBrandRed,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Create Account",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Join us — it only takes a minute",
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black.withOpacity(0.55),
                ),
              ),
              const SizedBox(height: 32),

              // Name Field with Error
              GlassTextField(
                hintText: "Username (3-20 chars, no spaces)",
                icon: Icons.person_outline,
                controller: nameController,
              ),
              if (nameError != null)
                Padding(
                  padding: const EdgeInsets.only(left: 4, top: 6),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      nameError!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Email Field with Error
              GlassTextField(
                hintText: "Email (e.g., user@gmail.com)",
                icon: Icons.email_outlined,
                controller: emailController,
              ),
              if (emailError != null)
                Padding(
                  padding: const EdgeInsets.only(left: 4, top: 6),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      emailError!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Password Field with Error
              GlassTextField(
                hintText: "Password (min 6 characters)",
                icon: Icons.lock_outline,
                isPassword: true,
                controller: passwordController,
              ),
              if (passwordError != null)
                Padding(
                  padding: const EdgeInsets.only(left: 4, top: 6),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      passwordError!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 28),

              // Register Button
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
                  onPressed: isLoading ? null : handleRegister,
                  child: isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          "REGISTER",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // Navigate to Login
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Already have an account? ",
                    style: TextStyle(color: Colors.black.withOpacity(0.65)),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                    ),
                    child: const Text(
                      "Login",
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