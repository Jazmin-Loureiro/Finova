import 'package:flutter/material.dart';
import '../widgets/custom_scaffold.dart';

class ConfigurationScreen extends StatelessWidget {
  const ConfigurationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomScaffold(
      title: 'Configuración',
      currentRoute: 'configuration',
      showNavigation: false,
      body: Center(
        child: Text(
          'Pantalla de Configuración',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
