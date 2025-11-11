import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_lucide/flutter_lucide.dart'; // o lucide_icons_flutter
import 'package:cached_network_image/cached_network_image.dart';

IconData? _lucideFrom(String name) {
  // Mapea strings a IconData de Lucide. Ejemplo básico:
  switch (name) {
    case 'trophy': return LucideIcons.trophy;
    case 'medal': return LucideIcons.medal;
    case 'crown': return LucideIcons.crown;
    case 'award': return LucideIcons.award;
    default: return null;
  }
}

Widget buildBadge(BuildContext context, Map<String, dynamic> badge) {
  final cs = Theme.of(context).colorScheme;
  final iconStr = (badge['icon'] ?? '') as String;
  final tier = (badge['tier'] ?? 0) as int;
  final unlocked = badge['unlocked'] == true; // 👈 nuevo campo

  // color por tier (solo si está desbloqueada)
  final Color activeColor = switch (tier) {
    3 => Colors.amberAccent,
    2 => Colors.blueGrey.shade200,
    1 => Colors.brown.shade300,
    _ => cs.primary,
  };
  final Color color = unlocked ? activeColor : Colors.grey.shade400;

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
    inner = SvgPicture.network(iconStr,
        width: 36,
        height: 36,
        color: unlocked ? Colors.white : Colors.grey.shade200);
  } else if (iconStr.startsWith('http')) {
    inner = ColorFiltered(
      colorFilter: unlocked
          ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
          : ColorFilter.mode(Colors.grey, BlendMode.saturation),
      child: CachedNetworkImage(imageUrl: iconStr, width: 40, height: 40),
    );
  } else {
    inner = Icon(Icons.emoji_events_outlined,
        size: 36, color: unlocked ? Colors.white : Colors.grey.shade200);
  }

  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      AnimatedOpacity(
        duration: const Duration(milliseconds: 400),
        opacity: unlocked ? 1 : 0.6,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: unlocked
                  ? [color.withOpacity(0.9), color.withOpacity(0.5)]
                  : [Colors.grey.shade300, Colors.grey.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
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
      ),
      const SizedBox(height: 8),
      Text(
        badge['name'] ?? '',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: unlocked ? cs.onSurface : cs.onSurfaceVariant.withOpacity(0.5),
        ),
        maxLines: 2,
      ),
    ],
  );
}

