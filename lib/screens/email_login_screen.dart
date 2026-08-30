import 'package:flutter/material.dart';
import 'auth_entry_screen.dart';

class EmailLoginScreen extends StatelessWidget {
  final bool initialIsSignUp;

  const EmailLoginScreen({super.key, this.initialIsSignUp = false});

  @override
  Widget build(BuildContext context) {
    return AuthEntryScreen(initialIsSignUp: initialIsSignUp);
  }
}
