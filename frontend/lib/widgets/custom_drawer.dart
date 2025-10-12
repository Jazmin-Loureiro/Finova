import 'package:flutter/material.dart';

// 🔹 Importá tus pantallas reales
import '../screens/dashboard_screen.dart';
import '../screens/configuration_screen.dart';
import '../screens/challenge_screen.dart';
import '../screens/currency_converter_screen.dart';
import '../screens/export_reports_screen.dart';

class CustomDrawer extends StatelessWidget {
  final String currentRoute;

  const CustomDrawer({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Widget buildMenuItem({
      required IconData icon,
      required String title,
      required String routeName,
      required Widget screen,
    }) {
      final bool isSelected = currentRoute == routeName;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            Navigator.pop(context);
            if (!isSelected) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => screen),
              );
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? scheme.primary.withOpacity(0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? scheme.primary : Colors.white70,
                  size: 22,
                ),
                const SizedBox(width: 14),
                Text(
                  title,
                  style: textTheme.bodyLarge?.copyWith(
                    color: isSelected ? scheme.primary : Colors.white70,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
      ),
      backgroundColor: Colors.black,
      elevation: 8,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 🔹 Encabezado violeta con logo blanco encima
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 28.0),
              color: scheme.primary,
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      color: Colors.white, // círculo blanco sólido
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Image.asset(
                        'assets/icon.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Finova',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: scheme.onPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 🔹 Ítems del menú
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(top: 8),
                children: [
                  buildMenuItem(
                    icon: Icons.dashboard_rounded,
                    title: 'Panel',
                    routeName: 'dashboard',
                    screen: const DashboardScreen(),
                  ),
                  buildMenuItem(
                    icon: Icons.settings_rounded,
                    title: 'Configuración',
                    routeName: 'configuration',
                    screen: const ConfigurationScreen(),
                  ),
                  buildMenuItem(
                    icon: Icons.emoji_events_rounded,
                    title: 'Desafíos',
                    routeName: 'challenge',
                    screen: const ChallengeScreen(),
                  ),
                  buildMenuItem(
                    icon: Icons.currency_exchange_rounded,
                    title: 'Conversor',
                    routeName: 'currency_converter',
                    screen: const CurrencyConverterScreen(),
                  ),
                  buildMenuItem(
                    icon: Icons.file_download	,
                    title: 'Exportar Reportes',
                    routeName: 'report_export',
                    screen: const ExportReportsScreen(),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Divider(color: Colors.white24),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text(
                'Versión 1.0.0',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(
                  color: Colors.white54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
