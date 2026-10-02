// lib/features/auth/presentation/provider/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  AuthProvider() {
    _checkLoginStatus();
  }

  // Check if token exists in local storage
  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token != null) {
      _isAuthenticated = true;
      notifyListeners();
    }
  }

  // Save token and login
  Future<void> login(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    _isAuthenticated = true;
    notifyListeners();
  }

  // Clear data and logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _isAuthenticated = false;
    notifyListeners();
  }
  // Function<void> register(String token) {
  //   final prefs = SharedPreferences.getInstance();
  //   prefs.then((prefs) => prefs.setString('auth_token', token));
  //   _isAuthenticated = true;
  //   notifyListeners();
  //   if (_isAuthenticated) {
  //     return () => logout();
  //   } else {
  //     return () => login(token);
  //   }
  // }
}