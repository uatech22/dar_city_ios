import 'package:flutter/material.dart';
import 'package:dar_city_app/core/layout/dar_layout_metrics.dart';
import 'package:dar_city_app/core/widgets/responsive_scaffold.dart';
import 'package:dar_city_app/navigation/role_navigation.dart';
import 'services/auth_service.dart';
import 'package:dar_city_app/services/session_manager.dart';

/* ================= COMPLETE PROFILE SCREEN ================= */

class CompleteProfileScreen extends StatefulWidget {

  final String token; // <- token received after email verification

  const CompleteProfileScreen({
    super.key,
    required this.token,
  });

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _preferredPlayerController = TextEditingController();
  final _favoriteJerseyController = TextEditingController();

  String? _role; // fan or sponsor
  bool isLoading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _preferredPlayerController.dispose();
    _favoriteJerseyController.dispose();
    super.dispose();
  }

  /// Save profile and submit to backend


  void _saveProfile() async {
    if (_fullNameController.text.isEmpty || _phoneController.text.isEmpty || _role == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() => isLoading = true);

    final result = await AuthService.completeProfile(
      token: widget.token, // pass the registration token here
      fullName: _fullNameController.text.trim(),
      phone: _phoneController.text.trim(),
      role: _role!,
    );

    setState(() => isLoading = false);

    if (result['success']) {
      await RoleNavigation.persistRoleFromResponse(result);
      final role = SessionManager().getRole() ?? _role;
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => RoleNavigation.homeForRole(role)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Registration failed')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        centerTitle: true,
        backgroundColor: Colors.black,
      ),
      body: darResponsiveBody(
        SingleChildScrollView(
        padding: EdgeInsets.all(DarLayoutMetrics.of(context).horizontalPadding),
        child: Column(
          children: [
            ProfileTextField(
              label: 'Full Name',
              controller: _fullNameController,
            ),
            const SizedBox(height: 16),
            ProfileTextField(
              label: 'Phone Number',
              controller: _phoneController,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            ProfileTextField(
              label: 'Preferred Player (Optional)',
              controller: _preferredPlayerController,
            ),
            const SizedBox(height: 16),
            ProfileTextField(
              label: 'Favorite Jersey (Optional)',
              controller: _favoriteJerseyController,
            ),
            const SizedBox(height: 16),

            /// Role selection
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: const Text('Fan', style: TextStyle(color: Colors.white)),
                    leading: Radio<String>(
                      value: 'fan',
                      groupValue: _role,
                      onChanged: (value) => setState(() => _role = value),
                      activeColor: Colors.red,
                    ),
                  ),
                ),
                Expanded(
                  child: ListTile(
                    title: const Text('Sponsor', style: TextStyle(color: Colors.white)),
                    leading: Radio<String>(
                      value: 'sponsor',
                      groupValue: _role,
                      onChanged: (value) => setState(() => _role = value),
                      activeColor: Colors.red,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            /// SAVE BUTTON
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  'Save Profile',
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
      ),
    );
  }
}

/* ================= REUSABLE TEXT FIELD ================= */

class ProfileTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;

  const ProfileTextField({
    super.key,
    required this.label,
    required this.controller,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
