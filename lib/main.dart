import 'dart:io'; // To check the platform
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart'; // For Linux support
import 'package:provider/provider.dart';
import 'package:agrismart/features/auth/presentation/provider/auth_provider.dart';
import 'package:agrismart/features/auth/presentation/pages/login_screen.dart';

void main() {
  // 1. Required for desktop (Ubuntu) SQLite support
  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(
    ChangeNotifierProvider(
      create: (context) => AuthProvider(),
      child: const AgriSmartApp(), // Ensure this matches the class name below
    ),
  );
}

// 2. This name MUST match what is inside runApp()
class AgriSmartApp extends StatelessWidget {
  const AgriSmartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AgriSmart Nepal',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      // Your routing logic here
      home: LoginScreen(), 
    );
  }
}