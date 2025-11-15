import 'package:flutter/material.dart';
import 'custom_app_bar.dart';
import 'custom_drawer.dart';

class CustomScaffold extends StatelessWidget {
  final String title;
  final String currentRoute;
  final Widget body;
  final List<Widget>? actions;
  final bool extendBody;
  final bool extendBodyBehindAppBar;
  final bool showNavigation; // ya no hace nada, si querés también lo podés borrar

  const CustomScaffold({
    super.key,
    required this.title,
    required this.currentRoute,
    required this.body,
    this.actions,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.showNavigation = true,
  });

  int _getCurrentIndex() {
    switch (currentRoute) {
      case 'inicio':
        return 0;
      case 'goals_list':
        return 1;
      case 'money_makers':
        return 3;
      case 'statistics':
        return 4;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final background = theme.scaffoldBackgroundColor;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            background.withOpacity(0.97),
            background.withOpacity(0.9),
            primary.withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: extendBody,
        extendBodyBehindAppBar: extendBodyBehindAppBar,
        appBar: CustomAppBar(title: title, actions: actions),
        drawer: CustomDrawer(currentRoute: currentRoute),
        body: body,
      ),
    );
  }
}
