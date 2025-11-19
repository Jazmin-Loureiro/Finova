import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ExtraUnlockedScreen extends StatefulWidget {
  final String extraName;
  final String iconPath;     // EJ: "assets/maceta.svg"
  final int levelUnlocked;

  const ExtraUnlockedScreen({
    super.key,
    required this.extraName,
    required this.iconPath,
    required this.levelUnlocked,
  });

  @override
  State<ExtraUnlockedScreen> createState() => _ExtraUnlockedScreenState();
}

class _ExtraUnlockedScreenState extends State<ExtraUnlockedScreen> {
  bool _pulse = false;

  @override
  void initState() {
    super.initState();
    _startPulse();
  }

  void _startPulse() {
    Future.delayed(const Duration(milliseconds: 550), () {
      if (!mounted) return;
      setState(() => _pulse = !_pulse);
      _startPulse();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).scaffoldBackgroundColor.withOpacity(0.95),
              cs.primary.withOpacity(0.20),
              cs.secondary.withOpacity(0.15),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            // ✨ Fondo confetti suave
            Positioned.fill(
              child: Opacity(
                opacity: 0.40,
                child: Lottie.asset(
                  "assets/lottie/confetti.json",
                  fit: BoxFit.cover,
                ),
              ),
            ),

            Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      const SizedBox(height: 60),

                      // 🎉 Confetti principal + SVG del extra
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 250,
                            height: 250,
                            child: Lottie.asset(
                              "assets/lottie/confetti.json",
                              fit: BoxFit.cover,
                            ),
                          ),
                          AnimatedScale(
                            scale: _pulse ? 1.12 : 1.0,
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeInOut,
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: cs.surface.withOpacity(0.25),
                                boxShadow: [
                                  BoxShadow(
                                    color: cs.primary.withOpacity(0.45),
                                    blurRadius: 45,
                                    spreadRadius: 6,
                                  ),
                                  BoxShadow(
                                    color: cs.secondary.withOpacity(0.35),
                                    blurRadius: 55,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                              child: SvgPicture.asset(
                                widget.iconPath,     // ✔ ASSET LOCAL
                                width: 140,
                                height: 140,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [
                            Colors.white,
                            Colors.amberAccent,
                            Colors.white,
                          ],
                        ).createShader(bounds),
                        child: Text(
                          "¡Nuevo extra desbloqueado!",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: cs.onSurface,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      Text(
                        widget.extraName,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface.withOpacity(0.9),
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        "Desbloqueado al alcanzar el nivel ${widget.levelUnlocked}.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: cs.onSurface.withOpacity(0.8),
                        ),
                      ),

                      const SizedBox(height: 40),

                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 40),
                          backgroundColor: cs.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          "Continuar",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                      ),

                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
