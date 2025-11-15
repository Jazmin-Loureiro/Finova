import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../widgets/custom_scaffold.dart';
import '../services/api_service.dart';
import '../widgets/loading_widget.dart';
import '../widgets/badge_grid_widget.dart';
import '../widgets/custom_refresh_wrapper.dart';
import '../../main.dart';
import '../widgets/info_icon_widget.dart';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:multiavatar/multiavatar.dart';

class ChallengeProfileScreen extends StatefulWidget {
  const ChallengeProfileScreen({super.key});

  @override
  State<ChallengeProfileScreen> createState() => _ChallengeProfileScreenState();
}

class _ChallengeProfileScreenState extends State<ChallengeProfileScreen>
    with RouteAware {
  final ApiService api = ApiService();
  late Future<Map<String, dynamic>> _profileFuture;

  bool _isPulsing = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _startPulse();
  }

  void _loadProfile() {
    _profileFuture = api.getGamificationProfile();
  }

  void _startPulse() {
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) {
        setState(() => _isPulsing = !_isPulsing);
        _startPulse();
      }
    });
  }

  @override
  void didPopNext() {
    super.didPopNext();
    setState(() => _loadProfile());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  double _requiredForLevel(int level, {double base = 150, double growth = 1.5}) {
    if (level <= 0) return base;
    return (base * (math.pow(growth, (level - 1)))).toDouble();
  }

  double _levelProgress(int level, int points) {
    final required = _requiredForLevel(level);
    if (required <= 0) return 0;
    final v = points / required;
    return v.clamp(0.0, 1.0);
  }

  Widget _streakCard({
    required int current,
    required int longest,
    String? lastActivityIso,
  }) {
    final cs = Theme.of(context).colorScheme;
    final progress = (longest > 0) ? (current / longest).clamp(0.0, 1.0) : 0.0;

    String subtitle;
    if (current == 0 && longest == 0) {
      subtitle = 'Aún sin racha. ¡Completá un desafío hoy!';
    } else if (current == 0) {
      subtitle = 'Tu récord es $longest 🔥';
    } else {
      subtitle = 'Racha actual: $current • Récord: $longest';
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                cs.surface.withOpacity(0.35),
                cs.surface.withOpacity(0.15),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: cs.primary.withOpacity(0.25)),
            boxShadow: [
              BoxShadow(
                color: cs.primary.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cs.primary.withOpacity(0.12),
                    ),
                    child: Icon(
                      Icons.local_fire_department_rounded,
                      color: cs.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Racha activa',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(width: 6),
                  InfoIcon(
                    title: "Racha activa",
                    message:
                        "Es la cantidad de días seguidos en los que completaste al menos un desafío. Si un día no completás ninguno, la racha vuelve a 0. También se muestra tu récord histórico de días consecutivos.",
                    iconSize: 18,
                  ),
                  const Spacer(),
                  Text(
                    '${current}d',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: cs.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress.isNaN ? 0 : progress,
                  minHeight: 8,
                  backgroundColor: cs.onSurface.withOpacity(0.08),
                  color: cs.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 12,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _animatedStatCard({
    required IconData icon,
    required String label,
    required int value,
    required List<Color> gradient,
  }) {
    final cs = Theme.of(context).colorScheme;
    final double baseHeight = 130;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutBack,
      builder: (context, anim, child) {
        return Transform.scale(
          scale: anim,
          child: Container(
            height: baseHeight,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: gradient.first.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 26),
                ),
                const SizedBox(height: 8),
                TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: value),
                  duration: const Duration(milliseconds: 800),
                  builder: (context, animatedValue, _) => Text(
                    '$animatedValue',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: 'Mi Perfil de Desafíos',
      currentRoute: 'user',
      showNavigation: false,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _profileFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: LoadingWidget(message: 'Cargando perfil...'),
            );
          }

          if (snap.hasError) {
            return Center(
              child: Text(
                'Error: ${snap.error}',
                style: TextStyle(color: Colors.red),
              ),
            );
          }

          return CustomRefreshWrapper(
            onRefresh: () async {
              setState(() => _loadProfile());
              await _profileFuture;
            },
            child: _buildProfileContent(snap.data!),
          );
        },
      ),
    );
  }

  Widget _buildProfileContent(Map<String, dynamic> data) {
    final cs = Theme.of(context).colorScheme;

    final user = data['user'] ?? {};
    final challenges = data['challenges'] ?? {};

    final level = user['level'] ?? 0;
    final points = user['points'] ?? 0;
    final name = user['name'] ?? 'Usuario Finova';
    final badges = (data['badges'] as List?) ?? [];

    final streak = (data['streak'] as Map?) ?? {};
    final int currentStreak = (streak['current'] ?? 0) as int;
    final int longestStreak = (streak['longest'] ?? 0) as int;
    final String? lastActivityIso = streak['last_activity'] as String?;

    final inProgress =
        (challenges['in_progress'] as List?)?.length ?? 0;
    final completed =
        (challenges['completed'] as List?)?.length ?? 0;
    final failed =
        (challenges['failed'] as List?)?.length ?? 0;

    final nextLevelPts = _requiredForLevel(level + 1).toInt();
    final remaining = (nextLevelPts - points).clamp(0, nextLevelPts);
    final total = completed + failed + inProgress;
    final completionRate =
        total > 0 ? ((completed / total) * 100).round() : 0;

    // AVATAR + GLOW
    Widget innerAvatar;
    final iconValue =
        user['full_icon_url'] ??
        user['avatar_seed'] ??
        user['icon'];

    if (iconValue != null && iconValue.toString().isNotEmpty) {
      if (iconValue.toString().contains('/')) {
        innerAvatar = CircleAvatar(
          radius: 70,
          backgroundImage: NetworkImage(iconValue),
        );
      } else {
        final svgCode = multiavatar(iconValue);
        innerAvatar = CircleAvatar(
          radius: 70,
          backgroundColor: Colors.grey[200],
          child: SvgPicture.string(
            svgCode,
            width: 140,
            height: 140,
          ),
        );
      }
    } else {
      final svgCode = multiavatar("default_seed");
      innerAvatar = CircleAvatar(
        radius: 70,
        backgroundColor: Colors.grey[200],
        child: SvgPicture.string(
          svgCode,
          width: 140,
          height: 140,
        ),
      );
    }

    Widget avatar = Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.purpleAccent.withOpacity(0.55),
            blurRadius: 28,
            spreadRadius: 4,
          ),
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.35),
            blurRadius: 38,
            spreadRadius: 1,
          ),
        ],
      ),
      child: innerAvatar,
    );

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // HEADER NIVEL + AVATAR
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: [cs.primary, cs.secondary.withOpacity(0.85)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: cs.primary.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  avatar,
                  const SizedBox(height: 10),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ShaderMask(
                        shaderCallback: (rect) => LinearGradient(
                          colors: [cs.primary, Colors.white, cs.secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          tileMode: TileMode.mirror,
                        ).createShader(rect),
                        child: const Text(
                          'Nivel ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      ShaderMask(
                        shaderCallback: (rect) => LinearGradient(
                          colors: [cs.primary, Colors.white, cs.secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          tileMode: TileMode.mirror,
                        ).createShader(rect),
                        child: Text(
                          '$level — $points pts',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      InfoIcon(
                        title: "Nivel y puntos",
                        message:
                            "Tus puntos se suman cada vez que completás desafíos. Cada nivel requiere una cantidad determinada de puntos. La barra y el texto de abajo muestran qué tan cerca estás del próximo nivel y cuántos puntos te faltan.",
                        iconSize: 18,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _levelProgress(level, points),
                        backgroundColor: Colors.white.withOpacity(0.3),
                        color: cs.secondary,
                        minHeight: 8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Faltan $remaining pts para el nivel ${level + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Racha
            AnimatedScale(
              scale: currentStreak > 0 && _isPulsing ? 1.03 : 1.0,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOut,
              child: _streakCard(
                current: currentStreak,
                longest: longestStreak,
                lastActivityIso: lastActivityIso,
              ),
            ),

            const SizedBox(height: 16),

            // Stats
            Row(
              children: [
                Expanded(
                  child: _animatedStatCard(
                    icon: Icons.check_circle_rounded,
                    label: 'Completados',
                    value: completed,
                    gradient: [cs.primary, cs.secondary],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _animatedStatCard(
                    icon: Icons.timelapse_rounded,
                    label: 'En progreso',
                    value: inProgress,
                    gradient: [cs.secondary, cs.primary.withOpacity(0.8)],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _animatedStatCard(
                    icon: Icons.cancel_rounded,
                    label: 'Fallidos',
                    value: failed,
                    gradient: [Colors.redAccent, cs.primary],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Texto "¿Qué significa cada uno?"
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InfoIcon(
                  title: "Resumen de desafíos",
                  message:
                      "Completados son los desafíos que terminaste con éxito. En progreso son los que aceptaste y todavía están activos. Fallidos son los desafíos que no pudiste completar a tiempo o no cumplieron la condición definida.",
                  iconSize: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  '¿Qué significa cada uno?',
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Tasa de éxito
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: cs.surface.withOpacity(0.15),
                border: Border.all(color: cs.primary.withOpacity(0.25)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.trending_up_rounded,
                          color: cs.onSurface, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        'Tasa de éxito',
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 6),
                      InfoIcon(
                        title: "Tasa de éxito",
                        message:
                            "Representa el porcentaje de desafíos que lograste completar en relación al total de desafíos que iniciaste. Se calcula usando los desafíos completados, en progreso y fallidos. Cuanto más alta sea la tasa, mayor es tu consistencia realizando desafíos.",
                        iconSize: 18,
                      ),
                    ],
                  ),
                  Text(
                    '$completionRate%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: cs.secondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            const SizedBox(height: 20),

            // Insignias
            Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),

                // 🟣 Nuevo borde + glassmorphism
                gradient: LinearGradient(
                  colors: [
                    cs.surface.withOpacity(0.30),
                    cs.surface.withOpacity(0.10),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),

                border: Border.all(
                  color: cs.primary.withOpacity(0.35),
                  width: 1.4,
                ),

                boxShadow: [
                  BoxShadow(
                    color: cs.primary.withOpacity(0.18),
                    blurRadius: 22,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: cs.secondary.withOpacity(0.10),
                    blurRadius: 30,
                    spreadRadius: 0.5,
                  ),
                ],
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.emoji_events_outlined,
                        color: cs.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Insignias',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(width: 6),
                      InfoIcon(
                        title: "Insignias",
                        message:
                            "Son logros especiales que desbloqueás al cumplir metas. Representan hitos clave de tu progreso.",
                        iconSize: 18,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  if (badges.isEmpty)
                    Center(
                      child: Text(
                        'Todavía no desbloqueaste ninguna insignia 🏅',
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final int crossAxisCount =
                            ((constraints.maxWidth ~/ 80).clamp(3, 5)).toInt();

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: badges.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 20,
                            childAspectRatio: 0.7,
                          ),
                          itemBuilder: (context, index) {
                            final badge = badges[index] as Map<String, dynamic>;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),

                              // 🟣 ESTA ES TU INSIGNIA ORIGINAL
                              child: GestureDetector(
                                onTap: () => showBadgeInfo(context, badge),
                                child: buildBadge(context, badge),
                              ),

                            );
                          },
                        );
                      },
                    ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _statCard(IconData icon, String label, int value, Color color) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 6),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
