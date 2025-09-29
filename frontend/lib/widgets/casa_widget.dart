import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../providers/house_provider.dart';

class CasaWidget extends StatelessWidget {
  const CasaWidget({super.key});

  // 🔹 Escalas (tamaños relativos)
  final double houseScale = 1.35;
  final double groundScale = 0.12;

  // 🔹 Offsets (posiciones en píxeles)
  final double houseOffsetX = 0;
  final double houseOffsetY = -14.5;
  final double groundOffsetX = 0;
  final double groundOffsetY = 135;

  String getFondoCielo() {
    final hora = DateTime.now().hour;
    if (hora >= 6 && hora < 18) {
      return "dia.png";
    } else if (hora >= 18 && hora < 21) {
      return "atardecer.png";
    } else {
      return "noche.png";
    }
  }

  Widget buildLayer(String path) {
    final esPng = path.toLowerCase().endsWith('.png');
    return esPng
        ? Image.asset("assets/$path", fit: BoxFit.contain, key: ValueKey(path))
        : SvgPicture.asset("assets/$path", key: ValueKey(path));
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final houseData = context.watch<HouseProvider>().houseData;
    final fondoActual = getFondoCielo();

    if (houseData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final casa = houseData['casa'];

    return Stack(
      children: [
        // --- Fondo dinámico de cielo ---
        SizedBox(
          width: screenWidth,
          height: screenHeight + 1000,
          child: AnimatedSwitcher(
            duration: const Duration(seconds: 2),
            child: Image.asset(
              "assets/cielos/$fondoActual",
              key: ValueKey(fondoActual),
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
                ...List<Widget>.from(
                  (casa['suelo']['capas'] as List)
                      .map((s) => Positioned.fill(child: buildLayer(s))),
                ),
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
            scale: houseScale,
            child: Center(
              child: SizedBox(
                width: screenWidth * 0.8,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    buildLayer(casa['base']),
                    ...List<Widget>.from(
                      (casa['modulos'] as List).map((m) => buildLayer(m)),
                    ),
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
  }
}
