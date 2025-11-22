import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../widgets/info_icon_widget.dart';


void showExtraInfo(BuildContext context, Map<String, dynamic> extra, bool unlocked) {
  final cs = Theme.of(context).colorScheme;
  final int requiredLevel = extra['level_required'];

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.40,   
        minChildSize: 0.30,
        maxChildSize: 0.75,       
        builder: (context, scrollCtrl) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 12,
                  offset: const Offset(0, -3),
                )
              ],
            ),
            child: SingleChildScrollView(
              controller: scrollCtrl,
              child: Column(
                children: [
                  // Indicador arrastrable
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 22),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),

                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: unlocked
                          ? cs.primary.withOpacity(0.12)
                          : cs.onSurface.withOpacity(0.08),  // ✔ fondo circular gris
                    ),
                    child: unlocked
                    ? Center(
                        child: SizedBox(
                          width: 90,
                          height: 90,
                          child: FittedBox(
                            fit: BoxFit.contain,
                            child: SvgPicture.asset(
                              "assets/${extra['icon']}".replaceFirst(".svg", "_icon.svg"),
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Icon(
                          Icons.lock_rounded,
                          size: 55,
                          color: cs.onSurface.withOpacity(0.55),
                        ),
                      ),

                  ),


                  const SizedBox(height: 22),

                  // Nombre
                  Text(
                    unlocked ? extra["name"] : "???",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Descripción o requisito
                  Text(
                    unlocked
                        ? "Este objeto lo desbloqueaste al subir al nivel $requiredLevel."
                        : "Alcanza el nivel $requiredLevel para desbloquear este objeto.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.4,
                      color: cs.onSurfaceVariant.withOpacity(0.8),
                    ),
                  ),

                  const SizedBox(height: 26),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

class HouseExtrasWidget extends StatelessWidget {
  final List<dynamic> extras;
  final int level;

  const HouseExtrasWidget({
    super.key,
    required this.extras,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: cs.primary),
              const SizedBox(width: 8),

              Text(
                "Objetos extras de la casa",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),

              InfoIcon(
                title: "¿Qué son los extras?",
                message:
                    "Los extras son decoraciones especiales para tu casa que se desbloquean "
                    "cuando subís de nivel. Cada objeto se agrega automáticamente a tu casa "
                    "en cuanto alcanzás el nivel requerido.",
                iconSize: 22,
              ),
            ],
          ),
          const SizedBox(height: 16),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: extras.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.80,
            ),
            itemBuilder: (context, index) {
              final extra = extras[index];
              final unlocked = level >= extra['level_required'];

              // 👇 ESTA ES LA LÍNEA QUE FALTABA PONER ARRIBA
              final previewIcon =
                "assets/${extra['icon']}".replaceFirst(".svg", "_icon.svg");

              return GestureDetector(
                onTap: () => showExtraInfo(context, extra, unlocked),
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: unlocked
                            ? cs.primary.withOpacity(0.10)
                            : cs.onSurface.withOpacity(0.05),
                        border: Border.all(
                          color: unlocked
                              ? cs.primary.withOpacity(0.4)
                              : cs.onSurfaceVariant.withOpacity(0.2),
                        ),
                      ),
                      width: 90,
                      height: 90,
                      padding: const EdgeInsets.all(12),
                      child: unlocked
                      ? Center(
                          child: SizedBox(
                            width: 60,
                            height: 60,
                            child: FittedBox(
                              fit: BoxFit.contain,
                              child: SvgPicture.asset(previewIcon),
                            ),
                          ),
                        )
                      : Icon(
                          Icons.lock_rounded,
                          size: 40,
                          color: cs.onSurface.withOpacity(0.45),
                        ),
                    ),

                    const SizedBox(height: 6),

                    // ⚠️ Mostrar nombre solo si está desbloqueado
                    unlocked
                        ? Text(
                            extra['name'],
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: cs.onSurface),
                          )
                        : const SizedBox.shrink(),
                  ],
                ),
              );
            },

          )
        ],
      ),
    );
  }
}
