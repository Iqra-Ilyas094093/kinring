import 'package:flutter/material.dart';

/// Placeholder — full Login screen (per Part 5.4.1 of the product doc)
/// is the next build step. This exists so `WelcomeScreen` has somewhere
/// real to navigate to today.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log In')),
      body: const Center(child: Text('Login screen — coming next.')),
    );
  }
}
