import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:multiavatar/multiavatar.dart';

class ChallengeCompletedScreen extends StatefulWidget {
  final String userName;
  final String avatarSeedOrUrl;
  final int pointsEarned;
  final int totalPoints;
  final bool leveledUp;
  final int? newLevel;
  final String? badgeName;

  const ChallengeCompletedScreen({
    super.key,
    required this.userName,
    required this.avatarSeedOrUrl,
    required this.pointsEarned,
    required this.totalPoints,
    required this.leveledUp,
    required this.newLevel,
    required this.badgeName,
  });

  @override
  State<ChallengeCompletedScreen> createState() =>
      _ChallengeCompletedScreenState();
}

class _ChallengeCompletedScreenState extends State<ChallengeCompletedScreen> {
  bool _pulse = false;

  @override
  void initState() {
    super.initState();
    _startPulse();
  }

  void _startPulse() {
    Future.delayed(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      setState(() => _pulse = !_pulse);
      _startPulse();
    });
  }

  Widget _buildAvatar(String iconValue, ColorScheme cs) {
    Widget avatarImg;

    if (iconValue.isNotEmpty && iconValue.contains('/')) {
      avatarImg = CircleAvatar(
        radius: 65,
        backgroundImage: NetworkImage(iconValue),
      );
    } else if (iconValue.isNotEmpty) {
      final svg = multiavatar(iconValue);
      avatarImg = CircleAvatar(
        radius: 65,
        backgroundColor: Colors.grey[200],
        child: SvgPicture.string(svg, width: 120, height: 120),
      );
    } else {
      final svg = multiavatar("default_seed");
      avatarImg = CircleAvatar(
        radius: 65,
        backgroundColor: Colors.grey[200],
        child: SvgPicture.string(svg, width: 120, height: 120),
      );
    }

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: cs.primary.withOpacity(0.7),
            blurRadius: 30,
            spreadRadius: 5,
          ),
          BoxShadow(
            color: cs.secondary.withOpacity(0.4),
            blurRadius: 40,
            spreadRadius: 2,
          ),
        ],
      ),
      child: avatarImg,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final avatar = _buildAvatar(widget.avatarSeedOrUrl, cs);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).scaffoldBackgroundColor.withOpacity(0.96),
              cs.primary.withOpacity(0.20),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            // 🔦 Spotlight desde arriba
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                height: 30,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.4),
                    radius: 1.2,
                    colors: [
                      cs.onSurface.withOpacity(0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // ✨ Partículas suaves encima de todo
            Positioned.fill(
              child: IgnorePointer(
                ignoring: true,
                child: Opacity(
                  opacity: 0.4,
                  child: Lottie.asset(
                    "assets/lottie/confetti.json",
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

            Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 70),

                      // 🎊 AVATAR + CONFETI PRINCIPAL
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 230,
                            height: 230,
                            child: Lottie.asset(
                              "assets/lottie/confetti.json",
                              fit: BoxFit.cover,
                            ),
                          ),
                          avatar,
                        ],
                      ),

                      const SizedBox(height: 24),

                      ShaderMask(
                        shaderCallback: (Rect bounds) {
                          return LinearGradient(
                            colors: [
                              Colors.white,
                              Colors.amberAccent,
                              Colors.white,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds);
                        },
                        child: Text(
                          "¡Desafío completado!",
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: cs.onSurface
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        widget.userName,
                        style: TextStyle(
                          fontSize: 18,
                          color: cs.onSurface.withOpacity(0.92),
                        ),
                      ),

                      const SizedBox(height: 26),

                      // 🎬 TARJETA CINEMÁTICA
                      AnimatedScale(
                        scale: _pulse ? 1.03 : 1.0,
                        duration: const Duration(milliseconds: 650),
                        curve: Curves.easeInOut,
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: cs.onSurface.withOpacity(0.5),
                              width: 1.4,
                            ),
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.12),
                                Colors.white.withOpacity(0.03),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: cs.onSurface.withOpacity(0.25),
                                blurRadius: 25,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  children: [
                                    Text(
                                      "Ganaste ${widget.pointsEarned} puntos 🎉",
                                      style: TextStyle(
                                        color: cs.onSurface,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      "Total acumulado: ${widget.totalPoints} pts",
                                      style: TextStyle(
                                        color: cs.onSurface.withOpacity(0.9),
                                        fontSize: 16,
                                      ),
                                    ),
                                    if (widget.leveledUp) ...[
                                      const SizedBox(height: 12),
                                      Text(
                                        "🚀 ¡Subiste al nivel ${widget.newLevel}! ",
                                        style: const TextStyle(
                                          color: Colors.amberAccent,
                                          fontSize: 19,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                    if (widget.badgeName != null) ...[
                                      const SizedBox(height: 12),
                                      Text(
                                        "🏅 Nueva insignia: ${widget.badgeName}",
                                        style: TextStyle(
                                          color: cs.onSurface,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // 🔘 BOTÓN CON HALO
                      AnimatedScale(
                        scale: _pulse ? 1.05 : 1.0,
                        duration: const Duration(milliseconds: 650),
                        curve: Curves.easeInOut,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: cs.secondary.withOpacity(0.7),
                                blurRadius: 18,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: cs.primary, // VIOLETA
                              foregroundColor: cs.onSurface,
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
                              textStyle: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                letterSpacing: 0.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              shadowColor: cs.primary.withOpacity(0.4),
                              elevation: 8,
                            ),
                            child: const Text("Continuar"),
                          ),
                        ),
                      ),

                      const SizedBox(height: 70),
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
