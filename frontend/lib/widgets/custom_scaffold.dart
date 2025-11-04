import 'package:flutter/material.dart';
import 'custom_app_bar.dart';
import 'custom_drawer.dart';
import 'navigation_bar_widget.dart'; 

class CustomScaffold extends StatelessWidget {
  final String title;
  final String currentRoute; // usado para saber cuál está activa
  final Widget body;
  final List<Widget>? actions;
  final bool extendBody;
  final bool extendBodyBehindAppBar;
  final bool showNavigation;

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
      case 'user':
        return 4;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: extendBody,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      appBar: CustomAppBar(title: title, actions: actions),
      drawer: CustomDrawer(currentRoute: currentRoute),
      body: body,
      bottomNavigationBar:
          showNavigation ? NavigationBarWidget(currentIndex: _getCurrentIndex()) : null,
    );
  }
}
