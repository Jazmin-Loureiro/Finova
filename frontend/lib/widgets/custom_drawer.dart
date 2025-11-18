import 'package:flutter/material.dart';
import 'package:frontend/screens/Soap/investment_rates_screen.dart';
import 'package:frontend/screens/registers/register_list_screen.dart';

// 🔹 Importá tus pantallas reales
import '../screens/challenge_screen.dart';
import '../screens/currency_converter_screen.dart';
import '../screens/export_reports_screen.dart';
import '../screens/loan_simulator_screen.dart';
import '../screens/investment_simulator_screen.dart';
import '../screens/category/category_list.dart';
import '../screens/challenge_profile_screen.dart';
import '../screens/home_screen.dart';

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
              Navigator.push(
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
                  color: isSelected
                      ? scheme.primary
                      : scheme.onSurface.withOpacity(0.7),
                  size: 22,
                ),
                const SizedBox(width: 14),
                Text(
                  title,
                  style: textTheme.bodyLarge?.copyWith(
                    color: isSelected
                        ? scheme.primary
                        : scheme.onSurface.withOpacity(0.7),
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
      backgroundColor: scheme.surface, // 👈 ahora toma el color del tema activo
      elevation: 8,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: () {
                Navigator.pop(context); // Cierra el drawer

                if (currentRoute != '/home') {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 28.0),
                color: scheme.primary,
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: scheme.onPrimary,
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
            ),


            const SizedBox(height: 12),

            // 🔹 Ítems del menú
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(top: 8),
                children: [
                  buildMenuItem(
                    icon: Icons.manage_accounts,
                    title: 'Perfil',
                    routeName: 'challenge_profile',
                    screen: const ChallengeProfileScreen(),
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
                    icon: Icons.file_download_rounded	,
                    title: 'Exportar Reportes',
                    routeName: 'export',
                    screen: const ExportReportsScreen(),
                  ),
                  buildMenuItem(
                    icon: Icons.category_rounded	,
                    title: 'Categorias',
                    routeName: 'category_management',
                    screen: const CategoryListScreen(),
                  ),
                  buildMenuItem(
                    icon: Icons.request_quote_rounded,
                    title: 'Simular préstamos',
                    routeName: 'loan_simulation',
                    screen: const LoanSimulatorScreen(),
                  ),
                  buildMenuItem(
                    icon: Icons.trending_up_rounded,
                    title: 'Simular inversiones',
                    routeName: 'investment_simulation',
                    screen: const InvestmentSimulatorScreen(),
                  ),

                   buildMenuItem(
                      icon: Icons.list,
                      title: 'Todos los registros',
                      routeName: 'register_list',
                      screen: const RegisterListScreen(
                        moneyMakerId: null,       // ← esto es correcto
                        moneyMakerName: null,     // opcional si querés ocultar el nombre
                      ),
                    ),
                  /*
                   buildMenuItem(
                    icon: Icons.list,
                    title: 'Lista de Inversiones',
                    routeName: 'investment_list',
                    screen: const InvestmentRatesScreen(),
                  ), */
                ],
              ),
            ),

            // 🔹 Footer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Divider(color: scheme.onSurface.withOpacity(0.15)),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text(
                'Versión 1.0.0',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withOpacity(0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
