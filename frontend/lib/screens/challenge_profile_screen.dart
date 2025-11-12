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
                          avatarSeed: user['avatar_seed'], // lo que venga del backend
                          radius: 40,
                          onTap: () {
                            // 🔹 más adelante podés abrir un modal para cambiar la foto
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _statCard(Icons.check_circle_outline, 'Completados',
                          completed, cs.primary),
                      _statCard(Icons.timelapse_outlined, 'En progreso',
                          inProgress, cs.tertiary),
                      _statCard(Icons.cancel_outlined, 'Fallidos',
                          failed, Colors.redAccent),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // 🔹 Insignias del usuario
Container(
  padding: const EdgeInsets.all(20),
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(16),
    color: cs.surfaceContainerHighest.withOpacity(0.2),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(Icons.emoji_events_outlined, color: cs.primary, size: 30),
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
        GridView.builder(
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  itemCount: badges.length,
  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 4, // 👈 antes era 3 → ahora 4 por fila
    crossAxisSpacing: 12,
    mainAxisSpacing: 12,
    childAspectRatio: 1.1, // 👈 ajusta la proporción
  ),
  itemBuilder: (context, index) {
    final badge = badges[index] as Map<String, dynamic>;
    return buildBadge(context, badge);
  },
),

      const SizedBox(height: 12),
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
