import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:cached_network_image/cached_network_image.dart';

// ✅ la hacemos estática para que se mantenga entre reconstrucciones
final Set<int> _animatedBadges = <int>{};

IconData? _lucideFrom(String name) {
  switch (name) {
    case 'trophy': return LucideIcons.trophy;
    case 'medal': return LucideIcons.medal;
    case 'crown': return LucideIcons.crown;
    case 'award': return LucideIcons.award;
    case 'zap': return LucideIcons.zap;
    case 'piggy-bank': return LucideIcons.piggy_bank;
    case 'chart-line': return LucideIcons.trending_up;
    case 'calendar-check': return LucideIcons.calendar_check_2;
    case 'repeat': return LucideIcons.repeat;
    case 'flame': return LucideIcons.flame;
    default: return LucideIcons.badge_check;
  }
}

void showBadgeInfo(BuildContext context, Map<String, dynamic> badge) {
  final cs = Theme.of(context).colorScheme;
  final unlocked = badge['unlocked'] == true;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.40,     // ↓ abre con altura justa
        minChildSize: 0.30,         // ↓ mínimo si la descripción es corta
        maxChildSize: 0.70,         // ↑ suficiente si hay más texto
        builder: (context, scrollCtrl) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                )
              ],
            ),
            child: SingleChildScrollView(
              controller: scrollCtrl,
              child: Column(
                children: [
                  // indicador superior
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),

                  // insignia
                  Center(
                    child: Transform.scale(
                      scale: 1.4,
                      child: buildBadge(context, badge, showLabel: false),
                    ),

                  ),

                  const SizedBox(height: 18),

                  // nombre
                  Text(
                    badge['name'] ?? '',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // descripción
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Text(
                      unlocked
                          ? (badge['description'] ?? 'Sin descripción')
                          : 'Todavía no desbloqueaste esta insignia.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}



Widget buildBadge(BuildContext context, Map<String, dynamic> badge, {bool showLabel = true}) {
  final cs = Theme.of(context).colorScheme;
  final iconStr = (badge['icon'] ?? '') as String;
  final tier = (badge['tier'] ?? 0) as int;
  final unlocked = badge['unlocked'] == true;
  final badgeId = badge['badge_id'] ?? badge['id'] ?? badge.hashCode;

  // 🎨 Colores suaves compatibles con blanco/violeta
  final Color activeColor = switch (tier) {
    3 => const Color(0xFFFFD700), // Oro brillante
    2 => const Color(0xFFC0C0C0), // Plata clásica
    1 => const Color(0xFFCD7F32), // Bronce real
    _ => cs.primary,              // Violeta de tu tema
  };

  final Color color = unlocked ? activeColor : const Color(0xFFE0E0E0);

  // 🧩 Construir el ícono
  Widget inner;
  if (iconStr.startsWith('lucide:')) {
    final name = iconStr.split(':').last;
    final iconData = _lucideFrom(name);
    inner = Icon(
      iconData ?? Icons.emoji_events_outlined,
      size: 26,
      color: unlocked ? Colors.white : Colors.grey.shade200,
    );
  } else if (iconStr.endsWith('.svg')) {
    inner = SvgPicture.network(
      iconStr,
      width: 26,
      height: 26,
      color: unlocked ? Colors.white : Colors.grey.shade200,
    );
  } else if (iconStr.startsWith('http')) {
    inner = ColorFiltered(
      colorFilter: unlocked
          ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
          : const ColorFilter.mode(Colors.grey, BlendMode.saturation),
      child: CachedNetworkImage(imageUrl: iconStr, width: 32, height: 32),
    );
  } else {
    inner = Icon(
      Icons.emoji_events_outlined,
      size: 26,
      color: unlocked ? Colors.white : Colors.grey.shade200,
    );
  }

  // 🌟 Animación de logro solo una vez
  final bool showAchievementAnim =
      unlocked && !_animatedBadges.contains(badgeId);

  if (showAchievementAnim) {
    _animatedBadges.add(badgeId);
  }

  return TweenAnimationBuilder<double>(
    tween: Tween(begin: showAchievementAnim ? 0.0 : 1.0, end: 1.0),
    duration: const Duration(milliseconds: 1200),
    curve: Curves.easeOutBack,
    builder: (context, scale, child) {
  // 🔒 Asegura que scale no sobrepase el rango válido
  final double safeScale = scale.clamp(0.0, 1.2);
  final double safeOpacity = scale.clamp(0.0, 1.0);

  return Transform.scale(
    scale: safeScale, // ✅ usamos safeScale en vez de scale
    child: Stack(
      alignment: Alignment.center,
      children: [
        if (showAchievementAnim)
          AnimatedOpacity(
            opacity: safeOpacity, // ✅ ahora sí se usa correctamente
            duration: const Duration(milliseconds: 1200),
            child: Container(
              width: 75,
              height: 75,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withOpacity(0.7),
                    color.withOpacity(0.3),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
        // 🎖️ Insignia base
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: unlocked
                      ? [color.withOpacity(0.9), cs.secondary.withOpacity(0.6)]
                      : [Colors.grey.shade300, Colors.grey.shade500],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: unlocked
                        ? color.withOpacity(0.4)
                        : Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
                border: Border.all(
                  color: unlocked
                      ? Colors.white.withOpacity(0.25)
                      : Colors.grey.withOpacity(0.2),
                  width: 1,
                ),
              ),
              alignment: Alignment.center,
              child: inner,
            ),
            const SizedBox(height: 8),
            if (showLabel)
              Text(
                badge['name'] ?? '',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: unlocked
                      ? cs.onSurface.withOpacity(0.9)
                      : cs.onSurfaceVariant.withOpacity(0.5),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

          ],
        ),
      ],
    ),
  );
},

  );
}
