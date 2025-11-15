import 'package:flutter/material.dart';
import '../widgets/custom_scaffold.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomScaffold(
      title: 'Panel',
      currentRoute: 'dashboard',
      showNavigation: false,
      body: Center(
        child: Text(
          'Pantalla de Panel (Dashboard)',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
