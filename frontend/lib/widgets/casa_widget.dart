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
  Map<String, dynamic>? _houseData; // 🔹 guardamos los datos de la casa

  // 🔹 Escalas (tamaños relativos)
  double houseScale = 1.35;
  double groundScale = 0.12;

  // 🔹 Offsets (posiciones en píxeles)
  double houseOffsetX = 0;
  double houseOffsetY = -14.5;
  double groundOffsetX = 0;
  double groundOffsetY = 135;

  @override
  void initState() {
    super.initState();
    _fondoActual = getFondoCielo();

    // 🔹 cargar la casa al inicio
    _loadHouse();

    // 🔹 refrescar cada minuto el cielo
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      final nuevoFondo = getFondoCielo();
      if (nuevoFondo != _fondoActual) {
        setState(() {
          _fondoActual = nuevoFondo;
        });
      }
    });

    // 🔹 refrescar la casa cada 4 segundos
    Timer.periodic(const Duration(seconds: 4), (_) => _loadHouse());
  }

  Future<void> _loadHouse() async {
    final api = ApiService();
    try {
      final data = await api.getHouseStatus();
      setState(() {
        _houseData = data;
      });
    } catch (e) {
      // opcional: manejar errores de red
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

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
    return AnimatedSwitcher(
      duration: const Duration(seconds: 1),
      child: esPng
          ? Image.asset(
              "assets/$path",
              key: ValueKey(path),
              fit: BoxFit.contain,
            )
          : SvgPicture.asset(
              "assets/$path",
              key: ValueKey(path),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    if (_houseData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final casa = _houseData!['casa'];

    return Stack(
      children: [
        // --- Fondo dinámico de cielo con transición (estirado +100 px) ---
        SizedBox(
          width: screenWidth,
          height: screenHeight + 1000, // 👈 estiramos para cubrir el notch/FAB
          child: AnimatedSwitcher(
            duration: const Duration(seconds: 2),
            child: Image.asset(
              "assets/cielos/$_fondoActual",
              key: ValueKey(_fondoActual),
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
