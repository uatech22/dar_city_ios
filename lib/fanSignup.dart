import 'package:dar_city_app/loginScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'verify.dart';
import 'services/auth_service.dart';
import 'services/google_service.dart'; // Import the new service
import 'fanMainDashboard.dart'; // Import the home screen

class SignUpScreen extends StatefulWidget {
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  bool isGoogleLoading = false; // State for Google sign-up

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  /// ===============================
  /// HANDLE SIGN UP
  /// ===============================
  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    final result = await AuthService.registerStepOne(
      emailController.text.trim(),
      passwordController.text,
    );

    setState(() => isLoading = false);

    if (result['success'] == true) {
      final String token = result['token'];

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VerifyEmailScreen(token: token),
        ),
      );
    } else {
      _showError(result);
    }
  }

  /// ===============================
  /// HANDLE GOOGLE SIGN UP
  /// ===============================
  Future<void> _handleGoogleSignUp() async {
    setState(() => isGoogleLoading = true);

    final result = await GoogleAuthService.signInWithGoogle();

    setState(() => isGoogleLoading = false);

    if (result['success'] == true) {
      // On success, navigate to the home screen
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false, // Remove all previous routes
      );
    } else {
      _showError(result);
    }
  }

  /// ===============================
  /// SHOW ERROR FROM BACKEND
  /// ===============================
  void _showError(Map<String, dynamic> result) {
    String message = result['message'] ?? 'An error occurred';

    if (result['errors'] != null) {
      if (result['errors']['email'] != null) {
        message = result['errors']['email'][0];
      } else if (result['errors']['password'] != null) {
        message = result['errors']['password'][0];
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Column(
              children: [
                const SizedBox(height: 40),

                // 🔵 LOGO
                Image.asset(
                  'assets/images/dar-city-logo.png',
                  width: 160,
                ),

                const SizedBox(height: 20),

                //  TITLE
                const Text(
                  'Create Account',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Join Dar City Basketball',
                  style: TextStyle(color: Colors.white54),
                ),

                const SizedBox(height: 30),

                //  FORM CARD
                Card(
                  color: const Color(0xFF1A1A1A),
                  elevation: 12,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          //  EMAIL
                          TextFormField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Email address',
                              hintStyle:
                              const TextStyle(color: Colors.white54),
                              prefixIcon:
                              const Icon(Icons.email, color: Colors.white54),
                              filled: true,
                              fillColor: const Color(0xFF2A2A2A),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Email is required';
                              }
                              if (!RegExp(
                                  r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                  .hasMatch(value.trim())) {
                                return 'Enter a valid email';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          //  PASSWORD
                          TextFormField(
                            controller: passwordController,
                            obscureText: true,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Password',
                              hintStyle:
                              const TextStyle(color: Colors.white54),
                              prefixIcon:
                              const Icon(Icons.lock, color: Colors.white54),
                              filled: true,
                              fillColor: const Color(0xFF2A2A2A),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Password is required';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 24),

                          //  SIGN UP BUTTON
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: isLoading || isGoogleLoading
                                  ? null
                                  : _handleSignUp,
                              child: isLoading
                                  ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                                  : const Text(
                                'Sign Up',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          //  GOOGLE SIGN UP
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: TextButton(
                              onPressed: isLoading || isGoogleLoading
                                  ? null
                                  : _handleGoogleSignUp,
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: isGoogleLoading
                                  ? const CircularProgressIndicator(
                                color: Colors.black,
                              )
                                  : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'assets/images/google.png',
                                    height: 22,
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Sign up with Google',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                //  SIGN IN LINK
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.white70),
                    children: [
                      const TextSpan(text: 'Already have an account? '),
                      TextSpan(
                        text: 'Sign In',
                        style: const TextStyle(
                          color: Colors.white,
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.bold,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => LoginScreen(),
                              ),
                            );
                          },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }


  /// ===============================
  /// INPUT FIELD
  /// ===============================
  Widget _buildTextField(
      String hint,
      TextEditingController controller, {
        bool obscureText = false,
        String? Function(String?)? validator,
      }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: const Color(0xFF333339),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
      validator: validator,
    );
  }
}
