import 'package:flutter/material.dart';
import 'package:agrismart/core/database/db_helper.dart'; 
import 'package:agrismart/features/dashboard/presentation/pages/dashboard.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Define controllers to capture text
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    // Clean up controllers when screen is closed
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Account")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text("Join AgriSmart Nepal", 
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            _buildField("Full Name", Icons.person_outline, _nameController),
            _buildField("Email Address", Icons.email_outlined, _emailController),
            _buildField("Phone Number", Icons.phone_android_outlined, _phoneController),
            _buildField("Farm Location", Icons.location_on_outlined, _locationController),
            _buildField("Password", Icons.lock_outline, _passwordController, obscure: true),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (_nameController.text.isNotEmpty && _emailController.text.isNotEmpty) {
                    // 1. Prepare data mapping keys to DB columns
                    Map<String, dynamic> userData = {
                      'name': _nameController.text,
                      'email': _emailController.text,
                      'phone': _phoneController.text,
                      'location': _locationController.text,
                      'password': _passwordController.text,
                    };

                    // 2. Insert into SQLite[cite: 1]
                    await DBHelper().registerUser(userData);

                    // 3. Navigate to Dashboard[cite: 1]
                    if (mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => Dashboard(userEmail: _emailController.text)), // Pass email to Dashboard
                        (route) => false,
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text("Register"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Pass the controller into the builder function
  Widget _buildField(String label, IconData icon, TextEditingController controller, {bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller, // Linked to the controller[cite: 1]
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}