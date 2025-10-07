import 'package:flutter/material.dart';
import '../widgets/custom_scaffold.dart';

class ChallengeScreen extends StatelessWidget {
  const ChallengeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomScaffold(
      title: 'Desafíos',
      currentRoute: 'challenge',
      body: Center(
        child: Text(
          'Pantalla de Desafíos',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
