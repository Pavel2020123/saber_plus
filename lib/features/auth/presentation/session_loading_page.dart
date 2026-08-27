import 'package:flutter/material.dart';

class SessionLoadingPage extends StatelessWidget {
  const SessionLoadingPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Semantics(
        label: 'Restaurando sesión',
        child: const CircularProgressIndicator(),
      ),
    ),
  );
}
