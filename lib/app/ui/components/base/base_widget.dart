import 'package:flutter/material.dart';

// Base widget class for common functionality
abstract class BaseWidget extends StatelessWidget {
  const BaseWidget({Key? key}) : super(key: key);

  // Shadcn-inspired color palette
  static const Color background = Color(0xFFFFFFFF);
  static const Color foreground = Color(0xFF0F172A);
  static const Color muted = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);
  static const Color accent = Color(0xFFF1F5F9);
  static const Color primary = Color(0xFF0F172A);
  static const Color primaryForeground = Color(0xFFFFFFFF);

  // Common border radius
  static const BorderRadius borderRadius = BorderRadius.all(
    Radius.circular(12),
  );
  static const BorderRadius smallBorderRadius = BorderRadius.all(
    Radius.circular(8),
  );

  // Common padding
  static const EdgeInsets paddingSmall = EdgeInsets.all(8);
  static const EdgeInsets paddingMedium = EdgeInsets.all(16);
  static const EdgeInsets paddingLarge = EdgeInsets.all(24);

  // Common box shadow
  static const List<BoxShadow> defaultShadow = [
    BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 4)),
  ];

  // Text styles
  static const TextStyle headingStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: foreground,
  );

  static const TextStyle subheadingStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: foreground,
  );

  static const TextStyle bodyStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: foreground,
  );

  static const TextStyle captionStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: muted,
  );
}
