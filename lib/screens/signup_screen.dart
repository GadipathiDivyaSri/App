import 'package:flutter/material.dart';
import 'auth_entry_screen.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AuthEntryScreen(initialIsSignUp: true);
  }
}
