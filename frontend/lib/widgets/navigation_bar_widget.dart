import 'package:flutter/material.dart';
import '../screens/money_maker_list_screen.dart';
import '../screens/registers/transaction_form_screen.dart';
import '../screens/home_screen.dart';
import '../screens/user_screen.dart';
import '../screens/goals/goals_list_screen.dart';

/// Notch circular liso y simétrico (como un cuenco derretido)
class SmoothCircularNotchedShape extends NotchedShape {
  final double extraRadius;

  const SmoothCircularNotchedShape({this.extraRadius = 8});

  @override
  Path getOuterPath(Rect host, Rect? guest) {
    if (guest == null) return Path()..addRect(host);

    final fabRadius = guest.width / 2.0 + extraRadius;
    final fabCenter = guest.center;

    final path = Path()..moveTo(host.left, host.top);

    path.lineTo(fabCenter.dx - fabRadius, host.top);

    path.arcToPoint(
      Offset(fabCenter.dx + fabRadius, host.top),
      radius: Radius.circular(fabRadius),
      clockwise: false,
    );

    path.lineTo(host.right, host.top);
    path.lineTo(host.right, host.bottom);
    path.lineTo(host.left, host.bottom);
    path.close();

    return path;
  }
}

class NavigationBarWidget {
  static Widget bottomAppBar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // 👇 Agregado SafeArea
    return SafeArea(
      top: false, // solo respeta abajo
      child: BottomAppBar(
        shape: const SmoothCircularNotchedShape(extraRadius: 10),
        notchMargin: 0,
        color: scheme.surface, // 👈 viene del main
        elevation: 10,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.home, color: scheme.primary),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                  );
                },
              ),
              IconButton(
                icon: Icon(Icons.flag, color: scheme.primary),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const GoalsListScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 70),
              IconButton(
                icon: Icon(Icons.account_balance_wallet, color: scheme.primary),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MoneyMakerListScreen(),
                    ),
                  );
                },
              ),
              IconButton(
                icon: Icon(Icons.person, color: scheme.primary),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const UserScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  static FloatingActionButton fab(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;

  return FloatingActionButton(
    shape: const CircleBorder(),
    backgroundColor: scheme.primary,
    elevation: 4,
    onPressed: () {
      showModalBottomSheet(
  context: context,
  backgroundColor: Theme.of(context).colorScheme.surface,
  builder: (context) {
    return SafeArea( // 👈 esto hace que nunca quede debajo de los botones
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('Ingreso'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const TransactionFormScreen(type: 'income'),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Gasto'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const TransactionFormScreen(type: 'expense'),
                ),
              );
            },
          ),
        ],
      ),
    );
  },
);

    },
    child: const Icon(Icons.add, size: 32, color: Colors.white),
  );
}

}
