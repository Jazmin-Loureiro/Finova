// lib/widgets/custom_refresh_wrapper.dart
import 'package:flutter/material.dart';

class CustomRefreshWrapper extends StatelessWidget {
  final Future<void> Function() onRefresh; // función para refrescar
  final Widget child; // contenido a envolver
  final EdgeInsetsGeometry? padding; // padding opcional
  final bool alwaysScrollable; // si siempre es scrollable

  const CustomRefreshWrapper({
    super.key,
    required this.onRefresh,
    required this.child,
    this.padding,
    this.alwaysScrollable = true,
  });

  bool _isScrollableWidget(Widget widget) { // verifica si el widget ya es scrollable
    return widget is ScrollView || // incluye ListView, GridView, CustomScrollView
        widget is ListView ||
        widget is GridView ||
        widget is CustomScrollView;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Si el hijo ya es scrollable, no lo envolvemos en otro scroll
    final content = _isScrollableWidget(child)
        ? child
        : SingleChildScrollView(
            physics: alwaysScrollable
                ? const AlwaysScrollableScrollPhysics()
                : const BouncingScrollPhysics(),
            child: Padding(
              padding: padding ?? EdgeInsets.zero,
              child: child,
            ),
          );

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: cs.primary,
      backgroundColor: cs.surface,
      strokeWidth: 2.8,
      displacement: 40,
      child: content,
    );
  }
}
