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
      child: child,
    );
  }
}
