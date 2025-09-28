import 'package:flutter/material.dart';

class NavigationBar extends StatelessWidget {
  const NavigationBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Center(
        child: Text("Contenido principal acá"),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(), // curva si hay FAB
        notchMargin: 6.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              onPressed: () {}, // vacío por ahora
              icon: const Icon(Icons.home),
            ),
            IconButton(
              onPressed: () {}, // vacío por ahora
              icon: const Icon(Icons.search),
            ),
            IconButton(
              onPressed: () {}, // vacío por ahora
              icon: const Icon(Icons.person),
            ),
          ],
        ),
      ),
    );
  }
}
