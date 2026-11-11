import 'package:flutter/material.dart';

// Shows one of the app's illustrations from assets/images/.
// If the image file is missing (not generated yet), it falls back to a large icon,
// so screens still look fine while the artwork is being made.
class Illustration extends StatelessWidget {
  const Illustration(
    this.fileName, {
    super.key,
    required this.fallbackIcon,
    this.height = 180,
  });

  final String fileName; // e.g. 'empty-homes.png'
  final IconData fallbackIcon;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/$fileName',
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Icon(
        fallbackIcon,
        size: height * 0.5,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
