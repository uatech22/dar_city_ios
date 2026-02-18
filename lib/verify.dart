import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'complete_profile.dart';
import 'services/auth_service.dart';

/* ================= VERIFY EMAIL SCREEN ================= */

class VerifyEmailScreen extends StatefulWidget {
  final String token; //  registration token from step one

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
            token: widget.token, //  pass token forward
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
      appBar: AppBar(
        title: const Text('Verify Email'),
        centerTitle: true,
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Check your email',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "We've sent a verification code to your email address. Please enter the code below.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 30),

            /// CODE INPUT
            CodeInputRow(controllers: _controllers),

            const SizedBox(height: 30),
            const Text(
              "Didn't receive the code?",
              style: TextStyle(color: Colors.white70),
            ),
            TextButton(
              onPressed: isResending ? null : _resendCode,
              child: isResending
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Text(
                'Resend Code',
                style: TextStyle(color: Colors.red),
              ),
            ),
            const SizedBox(height: 30),

            /// VERIFY BUTTON
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isVerifying ? null : _verifyCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: isVerifying
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  'Verify',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(controllers.length, (index) {
        return SizedBox(
          width: 45,
          child: TextField(
            controller: controllers[index],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(fontSize: 22),
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: const Color(0xFF1A1A1A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
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
