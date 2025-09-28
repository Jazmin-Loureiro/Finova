import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/api_service.dart';

class CasaWidget extends StatefulWidget {
  const CasaWidget({super.key});

  @override
  State<CasaWidget> createState() => _CasaWidgetState();
}

class _CasaWidgetState extends State<CasaWidget> {
  late Timer _timer;
  String _fondoActual = "";

  // 🔹 Escalas (tamaños relativos)
  double houseScale = 1.35;   // Zoom de la casa → EJ: 1.2 más grande, 0.8 más chica
  double groundScale = 0.12;  // Tamaño del suelo en proporción a la pantalla

  // 🔹 Offsets (posiciones en píxeles)
  double houseOffsetX = 0;     // mover casa a la izquierda/derecha
  double houseOffsetY = -14.5;   // mover casa arriba/abajo (ajuste fino)
  double groundOffsetX = 0;    // mover suelo izquierda/derecha
  double groundOffsetY = 135;  // mover suelo arriba/abajo (ajuste fino)

  @override
  void initState() {
    super.initState();
    _fondoActual = getFondoCielo();

    // refresca cada minuto para detectar cambio de hora
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      final nuevoFondo = getFondoCielo();
      if (nuevoFondo != _fondoActual) {
        setState(() {
          _fondoActual = nuevoFondo;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  /// Decide qué cielo mostrar según la hora
  String getFondoCielo() {
    final hora = DateTime.now().hour;

    if (hora >= 6 && hora < 12) {
      return "dia.png";
    } else if (hora >= 12 && hora < 18) {
      return "atardecer.png";
    } else {
      return "noche.png";
    }
  }

  /// Construye capa (PNG o SVG) con transición fade
  Widget buildLayer(String path) {
    final esPng = path.toLowerCase().endsWith('.png');
    return AnimatedSwitcher(
      duration: const Duration(seconds: 1),
      child: esPng
          ? Image.asset(
              "assets/$path",
              key: ValueKey(path), // 🔑 clave única para animar cambios
              fit: BoxFit.contain,
            )
          : SvgPicture.asset(
              "assets/$path",
              key: ValueKey(path), // 🔑 igual para los SVG
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final api = ApiService();
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return FutureBuilder<Map<String, dynamic>>(
      future: api.getHouseStatus(),
      builder: (context, snapshot) {
        // 🔹 Antes: mostraba el circulito de carga
        // if (snapshot.connectionState == ConnectionState.waiting) {
        //   return const Center(child: CircularProgressIndicator());
        // }

        // 🔹 Ahora: si todavía no hay datos, mostramos un contenedor vacío
        if (!snapshot.hasData) {
          return const SizedBox();
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final data = snapshot.data!;
        final casa = data['casa'];

        return Stack(
          children: [
            // --- Fondo dinámico de cielo con transición ---
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: const Duration(seconds: 2),
                child: Image.asset(
                  "assets/cielos/$_fondoActual",
                  key: ValueKey(_fondoActual), // 🔑 para que detecte el cambio
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // --- Suelo ---
            Positioned(
              bottom: groundOffsetY,
              left: groundOffsetX,
              right: groundOffsetX,
              child: SizedBox(
                width: screenWidth,
                height: screenHeight * groundScale,
                child: Stack(
                  children: [
                    // 🔹 capas dinámicas del suelo con fade
                    ...List<Widget>.from(
                      (casa['suelo']['capas'] as List).map((s) =>
                        Positioned.fill(child: buildLayer(s)),
                      ),
                    ),
                    // 🔹 vereda fija con fade también
                    Positioned.fill(child: buildLayer(casa['suelo']['vereda'])),
                  ],
                ),
              ),
            ),

            // --- Casa ---
            Positioned(
              bottom: (screenHeight * groundScale) + houseOffsetY,
              left: houseOffsetX,
              right: houseOffsetX,
              child: Transform.scale(
                scale: houseScale, // 🔹 zoom de la casa
                child: Center(
                  child: SizedBox(
                    width: screenWidth * 0.8, // ancho base
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        // 🔹 base con fade
                        buildLayer(casa['base']),
                        // 🔹 módulos con fade
                        ...List<Widget>.from(
                          (casa['modulos'] as List).map((m) => buildLayer(m)),
                        ),
                        // 🔹 deterioro con fade
                        ...List<Widget>.from(
                          (casa['deterioro'] as List).map((d) => buildLayer(d)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
