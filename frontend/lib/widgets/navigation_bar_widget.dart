import 'package:flutter/material.dart';
import 'package:frontend/screens/registers/transfer_screen.dart';
import 'package:frontend/screens/statistics/statistics._screen.dart';
import '../screens/moneyMaker/money_maker_list_screen.dart';
import '../screens/registers/transaction_form_screen.dart';
import '../screens/home_screen.dart';
import '../screens/goals/goals_list_screen.dart';

class NavigationBarWidget extends StatefulWidget {
  final int currentIndex; // índice actual para marcar el activo
  const NavigationBarWidget({super.key, required this.currentIndex});

  @override
  State<NavigationBarWidget> createState() => _NavigationBarWidgetState();
}

class _NavigationBarWidgetState extends State<NavigationBarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      lowerBound: 0.0,
      upperBound: 0.1,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Pantallas asociadas
  final List<Widget> _screens = const [
    HomeScreen(),
    GoalsListScreen(),
    SizedBox(), // botón central
    MoneyMakerListScreen(),
    StatisticsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Container(
        height: 85,
        decoration: BoxDecoration(
          color: scheme.surface,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(context, 0, Icons.home),
            _buildNavItem(context, 1, Icons.flag),
            _centerAddButton(context, scheme),
            _buildNavItem(context, 3, Icons.account_balance_wallet),
            _buildNavItem(context, 4, Icons.auto_graph),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, IconData icon) {
    final scheme = Theme.of(context).colorScheme;
    final isActive = widget.currentIndex == index;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: () {
        if (!isActive) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => _screens[index]),
          );
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutBack,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color:
              isActive ? scheme.primary.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          icon,
          color: isActive ? scheme.primary : scheme.outline,
          size: isActive ? 32 : 28,
        ),
      ),
    );
  }

  Widget _centerAddButton(BuildContext context, ColorScheme scheme) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: scheme.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Container(
                    height: 4,
                    width: 40,
                    decoration: BoxDecoration(
                      color: scheme.outlineVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: Icon(Icons.arrow_upward, color: scheme.primary),
                    title: const Text('Ingreso'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const TransactionFormScreen(type: 'income'),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.arrow_downward, color: scheme.error),
                    title: const Text('Gasto'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const TransactionFormScreen(type: 'expense'),
                        ),
                      );
                    },
                  ),
                    ListTile(
                    leading: Icon(Icons.sync_alt, color: scheme.tertiary),
                    title: const Text('Transfererir'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const TransferScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
      child: Container(
        height: 68,
        width: 68,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              scheme.primary,
              scheme.primaryContainer,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withOpacity(0.4),
              offset: const Offset(0, 6),
              blurRadius: 12,
            ),
          ],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 34),
      ),
    );
  }
}
