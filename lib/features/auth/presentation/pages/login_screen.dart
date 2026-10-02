import 'package:flutter/material.dart';
import 'package:agrismart/core/database/db_helper.dart';
import 'package:agrismart/features/auth/presentation/pages/register_screen.dart';
import 'package:agrismart/features/dashboard/presentation/pages/dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // 1. Define controllers to capture user input
  final TextEditingController _identifierController = TextEditingController(); // Email or Phone
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    // Always dispose controllers to save memory
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView( // Added to prevent overflow on small screens
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 80),
              const Icon(Icons.agriculture, size: 80, color: Color(0xFF1B5E20)),
              const SizedBox(height: 16),
              const Text(
                "AgriSmart Nepal",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
              ),
              const SizedBox(height: 40),
              TextFormField(
                controller: _identifierController, // Link to controller[cite: 1]
                decoration: const InputDecoration(
                  labelText: 'Phone Number or Email',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController, // Link to controller[cite: 1]
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () async {
                  String identifier = _identifierController.text.trim();
                  String password = _passwordController.text.trim();

                  if (identifier.isEmpty || password.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please fill all fields")),
                    );
                    return;
                  }

                  // 2. Verify credentials using DBHelper[cite: 1]
                  final user = await DBHelper().checkLogin(identifier, password);

                  if (user != null) {
                    // 3. If found, go to Dashboard[cite: 1]
                    if (mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => Dashboard(userEmail: user['email'])), // Pass email to Dashboard
                      );
                    }
                  } else {
                    // 4. Show error if not found[cite: 1]
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Invalid Credentials. Please Register first.")),
                      );
                    }
                  }
                },
                child: const Text("Login"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RegisterScreen()),
                  );
                },
                child: const Text("Don't have an account? Register"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}