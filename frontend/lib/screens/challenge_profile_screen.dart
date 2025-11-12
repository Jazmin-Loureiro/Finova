import 'package:flutter/material.dart';
import '../widgets/custom_scaffold.dart';
import '../services/api_service.dart';
import '../widgets/loading_widget.dart';
import '../widgets/badge_grid_widget.dart';
import '../widgets/user_avatar_widget.dart';


class ChallengeProfileScreen extends StatefulWidget {
  const ChallengeProfileScreen({super.key});

  @override
  State<ChallengeProfileScreen> createState() => _ChallengeProfileScreenState();
}

class _ChallengeProfileScreenState extends State<ChallengeProfileScreen> {
  final ApiService api = ApiService();
  late Future<Map<String, dynamic>> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = api.getGamificationProfile();
  }

  Widget _animatedStatCard({
    required IconData icon,
    required String label,
    required int value,
    required List<Color> gradient,
    int delay = 0,
  }) {
    final cs = Theme.of(context).colorScheme;
    final double baseHeight = 130; // altura base uniforme

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutBack,
      builder: (context, anim, child) {
        return Transform.scale(
          scale: anim,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // 📱 Detecta pantallas pequeñas
              final bool isSmall = constraints.maxWidth < 110;
              final double textScale = MediaQuery.of(context).textScaleFactor;

              return Container(
                height: baseHeight * (textScale > 1.2 ? 1.2 : 1.0),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: gradient.map((c) => c.withOpacity(0.85)).toList(),
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
                    // 🎯 Ícono circular
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: isSmall ? 22 : 26,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // 🔢 Contador animado
                    TweenAnimationBuilder<int>(
                      tween: IntTween(begin: 0, end: value),
                      duration: const Duration(milliseconds: 800),
                      builder: (context, animatedValue, _) {
                        return Text(
                          '$animatedValue',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isSmall ? 17 : 20,
                            fontWeight: FontWeight.bold,
                            height: 1.0,
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 4),

                    // 🏷️ Label adaptable (Completados / Fallidos / etc.)
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: isSmall ? 10 : 12,
                            fontWeight: FontWeight.w500,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return CustomScaffold(
      title: 'Mi Perfil Finova',
      currentRoute: 'user',
      body: FutureBuilder<Map<String, dynamic>>(
        future: _profileFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const LoadingWidget(message: 'Cargando perfil...');
          }

          if (snap.hasError) {
            return Center(
              child: Text('Error: ${snap.error}',
                  style: const TextStyle(color: Colors.red)),
            );
          }

          final data = snap.data ?? {};
          final user = data['user'] ?? {};
          final challenges = data['challenges'] ?? {};

          final level = user['level'] ?? 0;
          final points = user['points'] ?? 0;
          final name = user['name'] ?? 'Usuario Finova';
          final badges = (data['badges'] as List?) ?? [];

          final inProgress =
              (challenges['in_progress'] as List?)?.length ?? 0;
          final completed = (challenges['completed'] as List?)?.length ?? 0;
          final failed = (challenges['failed'] as List?)?.length ?? 0;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // 🔹 Header visual con gradiente
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 24, horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        colors: [
                          cs.primary.withOpacity(0.85),
                          cs.secondary.withOpacity(0.85),
                        ],
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
                        UserAvatarWidget(
                          avatarSeed: user['avatar_seed'] ?? user['icon'] ?? user['full_icon_url'],
                          radius: 40,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Función para cambiar avatar')),
                            );
                          },
                        ),
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
                        Text(
                          'Nivel $level — $points pts',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: (points % 150) / 150,
                              backgroundColor:
                                  Colors.white.withOpacity(0.3),
                              color: Colors.amberAccent,
                              minHeight: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 🔹 Resumen de desafíos
                  // 🔹 Resumen de desafíos (reemplaza tu bloque Row)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: _animatedStatCard(
                            icon: Icons.check_circle_rounded,
                            label: 'Completados',
                            value: completed,
                            gradient: [cs.primary, cs.secondary],
                            delay: 0,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _animatedStatCard(
                            icon: Icons.timelapse_rounded,
                            label: 'En progreso',
                            value: inProgress,
                            gradient: [Colors.tealAccent.shade700, Colors.teal],
                            delay: 150,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _animatedStatCard(
                            icon: Icons.cancel_rounded,
                            label: 'Fallidos',
                            value: failed,
                            gradient: [Colors.redAccent, Colors.deepOrange],
                            delay: 300,
                          ),
                        ),
                      ],
                    ),
                  ),


                  const SizedBox(height: 40),

                  // 🔹 Insignias del usuario
                  Container(
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: cs.surfaceContainerHighest.withOpacity(0.2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.emoji_events_outlined, color: cs.primary, size: 28),
                            const SizedBox(width: 8),
                            Text(
                              'Insignias',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: cs.onSurface,
                              ),
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
                              // ✅ Calcula automáticamente el ancho disponible
                              final crossAxisCount =
                                  (constraints.maxWidth ~/ 80).clamp(3, 5); // entre 3 y 5 por fila

                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: badges.length,
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 20,
                                  childAspectRatio: 0.7, // más alto para que entre el texto
                                ),
                                itemBuilder: (context, index) {
                                  final badge = badges[index] as Map<String, dynamic>;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: buildBadge(context, badge),
                                  );
                                },
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _statCard(IconData icon, String label, int value, Color color) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.2),
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
