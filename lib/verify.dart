import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'complete_profile.dart';
import 'services/auth_service.dart';

/* ================= VERIFY EMAIL SCREEN ================= */

class VerifyEmailScreen extends StatefulWidget {
  final String token; // registration token from step one

  const VerifyEmailScreen({super.key, required this.token});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final List<TextEditingController> _controllers =
  List.generate(6, (_) => TextEditingController());

  bool isVerifying = false;
  bool isResending = false;

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  /* ================= VERIFY CODE ================= */
  Future<void> _verifyCode() async {
    final code = _controllers.map((c) => c.text).join();

    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the 6-digit code')),
      );
      return;
    }

    setState(() => isVerifying = true);

    final result = await AuthService.verifyEmail(
      token: widget.token,
      code: code,
    );

    setState(() => isVerifying = false);

    if (result['success'] == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CompleteProfileScreen(
            token: widget.token,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Verification failed')),
      );
    }
  }

  /* ================= RESEND CODE ================= */
  Future<void> _resendCode() async {
    setState(() => isResending = true);

    final result = await AuthService.resendVerificationCode(widget.token);

    setState(() => isResending = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result['message'] ?? 'Failed to resend code')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Verify Email'),
        centerTitle: true,
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      // This is key for tablet/iPad keyboard handling
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 450), // Standard width for tablet forms
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 20),
                            const Icon(Icons.mark_email_read_outlined, size: 80, color: Colors.red),
                            const SizedBox(height: 30),
                            const Text(
                              'Check your email',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              "We've sent a 6-digit verification code to your email. Please enter it below to continue.",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
                            ),
                            const SizedBox(height: 40),

                            /// CODE INPUT
                            CodeInputRow(controllers: _controllers),

                            const SizedBox(height: 40),
                            const Text(
                              "Didn't receive the code?",
                              style: TextStyle(color: Colors.white70, fontSize: 15),
                            ),
                            TextButton(
                              onPressed: isResending ? null : _resendCode,
                              child: isResending
                                  ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
                              )
                                  : const Text(
                                'Resend Code',
                                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                            const SizedBox(height: 40),

                            /// VERIFY BUTTON
                            SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: ElevatedButton(
                                onPressed: isVerifying ? null : _verifyCode,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: isVerifying
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : const Text(
                                  'Verify',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 40), // Ensures space at bottom when keyboard rises
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/* ================= CODE INPUT ROW ================= */

class CodeInputRow extends StatelessWidget {
  final List<TextEditingController> controllers;

  const CodeInputRow({super.key, required this.controllers});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(controllers.length, (index) {
        return SizedBox(
          width: 50,
          height: 65,
          child: TextField(
            controller: controllers[index],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            autofocus: index == 0,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(1),
            ],
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: const Color(0xFF1A1A1A),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white10),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
            ),
            onChanged: (value) {
              if (value.isNotEmpty && index < controllers.length - 1) {
                FocusScope.of(context).nextFocus();
              } else if (value.isEmpty && index > 0) {
                FocusScope.of(context).previousFocus();
              }
            },
          ),
        );
      }),
    );
  }
}
