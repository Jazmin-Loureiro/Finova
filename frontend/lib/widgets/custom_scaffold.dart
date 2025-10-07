import 'package:flutter/material.dart';
import 'custom_app_bar.dart';
import 'custom_drawer.dart';
import 'navigation_bar_widget.dart'; // 👈 importás tu barra

class CustomScaffold extends StatelessWidget {
  final String title;
  final String currentRoute;
  final Widget body;
  final List<Widget>? actions;
  final bool extendBody;
  final bool extendBodyBehindAppBar;
  final bool showNavigation; // 👈 si querés ocultar la barra en alguna pantalla

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: extendBody,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      appBar: CustomAppBar(title: title, actions: actions),
      drawer: CustomDrawer(currentRoute: currentRoute),
      body: body,

      // 👇 solo se muestra la barra si está habilitada
      bottomNavigationBar:
          showNavigation ? NavigationBarWidget.bottomAppBar(context) : null,
      floatingActionButton:
          showNavigation ? NavigationBarWidget.fab(context) : null,
      floatingActionButtonLocation: showNavigation
          ? FloatingActionButtonLocation.centerDocked
          : null,
    );
  }
}
