import 'package:flutter/material.dart';

// Shows one of the app's illustrations from assets/images/.
// In dark mode it first tries a dark version of the file, e.g. 'empty-homes-dark.png'.
// If that file is missing, it uses the normal light file instead.
// If that is missing too (not generated yet), it falls back to a large icon,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 'empty-homes.png' becomes 'empty-homes-dark.png' in dark mode.
    final darkName = fileName.replaceFirst(RegExp(r'\.png$'), '-dark.png');

    // Last resort: the icon, when no image file could be loaded.
    Widget iconFallback(BuildContext context, Object error, StackTrace? stackTrace) {
      return Icon(
        fallbackIcon,
        size: height * 0.5,
        color: Theme.of(context).colorScheme.primary,
      );
    }

    // The normal light image, used when the dark one is missing.
    Widget lightImage() {
      return Image.asset(
        'assets/images/$fileName',
        height: height,
        fit: BoxFit.contain,
        errorBuilder: iconFallback,
      );
    }

    if (!isDark) return lightImage();

    return Image.asset(
      'assets/images/$darkName',
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => lightImage(),
    );
  }
}
