import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:multiavatar/multiavatar.dart';

class UserAvatarWidget extends StatelessWidget {
  final File? iconFile;       // archivo local (foto subida desde el dispositivo)
  final String? avatarSeed;   // valor que viene del backend (puede ser ruta o seed)
  final double radius;
  final VoidCallback? onTap;
  

  const UserAvatarWidget({
    super.key,
    this.iconFile,
    this.avatarSeed,
    this.radius = 40,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget child;

    if (iconFile != null) {
      // 📂 Imagen local
      child = CircleAvatar(
        radius: radius,
        backgroundImage: FileImage(iconFile!),
      );
    } else if (avatarSeed != null && avatarSeed!.isNotEmpty) {
      if (avatarSeed!.contains('/')) {
        // 🌐 Ruta → imagen subida en backend
        child = CircleAvatar(
          radius: radius,
          backgroundImage: NetworkImage(avatarSeed!),
        );
      } else {
        // 🎨 Seed → generamos avatar
        final svgCode = multiavatar(avatarSeed!);
        child = CircleAvatar(
          radius: radius,
          backgroundColor: Colors.grey[200],
          child: SvgPicture.string(
            svgCode,
            width: radius * 2,
            height: radius * 2,
          ),
        );
      }
    } else {
      // 🟦 Fallback → avatar por defecto
      final svgCode = multiavatar("default_seed");
      child = CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey[200],
        child: SvgPicture.string(
          svgCode,
          width: radius * 2,
          height: radius * 2,
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 🔹 Marco con borde
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: colorScheme.primary.withOpacity(0.8),
                width: 3,
              ),
            ),
            child: ClipOval(child: child),
          ),

          // 🔹 Ícono de cámara en la esquina inferior derecha
          Positioned(
            bottom: 2,
            right: 4,
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(4),
              child: const Icon(
                Icons.camera_alt_outlined,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
