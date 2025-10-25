import 'package:flutter/material.dart';

class InfoIcon extends StatelessWidget {
  final String title;
  final String message;
  final double iconSize;

  const InfoIcon({
    super.key,
    required this.title,
    required this.message,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              title,
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              message,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                height: 1.4,
              ),
            ),
            actions: [
              TextButton(
                child: const Text('Entendido'),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
        );
      },
      child: Icon(
        Icons.info_outline_rounded,
        color: theme.colorScheme.primary,
        size: iconSize,
      ),
    );
  }
}
