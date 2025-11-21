import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../providers/house_provider.dart';
import '../widgets/loading_widget.dart'; 

class CasaWidget extends StatefulWidget {
  const CasaWidget({super.key});

  @override
  State<CasaWidget> createState() => _CasaWidgetState();
}

class _CasaWidgetState extends State<CasaWidget>
    with SingleTickerProviderStateMixin {
  final double houseScale = 1.35;
  final double groundScale = 0.12;

  final double houseOffsetX = 0;
  final double houseOffsetY = -14.5;
  final double groundOffsetX = 0;
  final double groundOffsetY = 135;

  late AnimationController _fadeController;
  late Animation<double> _fade;
  String _fondoActual = 'dia.png';
  String? _fondoAnterior;

  @override
  void initState() {
    super.initState();
    _fondoActual = getFondoCielo();
    _fadeController =
        AnimationController(vsync: this, duration: const Duration(seconds: 4));
    _fade = CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkCambioCielo();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  String getFondoCielo() {
    final hora = DateTime.now().hour;
    if (hora >= 6 && hora < 18) return "dia.png";
    if (hora >= 18 && hora < 21) return "atardecer.png";
    return "noche.png";
  }

  void _checkCambioCielo() {
    final nuevo = getFondoCielo();
    if (nuevo != _fondoActual) {
      setState(() => _fondoAnterior = _fondoActual);
      _fondoActual = nuevo;
      _fadeController.forward(from: 0);
    }
  }

  Widget _imgCielo(String nombre) {
    return Image.asset(
      "assets/cielos/$nombre",
      fit: BoxFit.cover,
    );
  }

  Widget buildLayer(String path) {
    final esPng = path.toLowerCase().endsWith('.png');
    return esPng
        ? Image.asset("assets/$path", fit: BoxFit.contain, key: ValueKey(path))
        : SvgPicture.asset("assets/$path", key: ValueKey(path));
  }

  @override
  Widget build(BuildContext context) {
    _checkCambioCielo();

    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final houseData = context.watch<HouseProvider>().houseData;

    // 🔹 APLICADO TU LOADER
    if (houseData == null) {
      return const LoadingWidget(message: "Cargando casa...");
    }

    final casa = houseData['casa'];

    return Stack(
      children: [
        // 🌤 Cielo
        SizedBox(
          width: screenWidth,
          height: screenHeight + 1000,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_fondoAnterior != null)
                FadeTransition(
                  opacity: Tween(begin: 1.0, end: 0.0).animate(_fade),
                  child: _imgCielo(_fondoAnterior!),
                ),
              _imgCielo(_fondoActual),
            ],
          ),
        ),

        // 🌱 Suelo
        Positioned(
          bottom: groundOffsetY,
          left: groundOffsetX,
          right: groundOffsetX,
          child: AnimatedSwitcher(
            duration: const Duration(seconds: 1),
            child: SizedBox(
              key: ValueKey(casa['suelo'].toString()),
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
        ),

        // 🚗 Calle
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: buildLayer('calle/calle.svg'),
        ),

        // 🏠 Casa
        Positioned(
          bottom: (screenHeight * groundScale) + houseOffsetY,
          left: houseOffsetX,
          right: houseOffsetX,
          child: Transform.scale(
            scale: houseScale,
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(seconds: 1),
                child: SizedBox(
                  key: ValueKey(casa.toString()),
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
                      ...List<Widget>.from(
                        (casa['extras'] as List)
                            .where((e) => e['unlocked'] == true)
                            .toList()
                            .map((extra) => Positioned(
                                  child: buildLayer(extra['icon']),
                                )),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
