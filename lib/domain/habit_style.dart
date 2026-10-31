import 'package:flutter/material.dart';

/// Habit colors. Each is dark enough for white text and icons on top.
const List<Color> habitColors = [
  Color(0xFFF97316), // orange
  Color(0xFF1D4ED8), // blue
  Color(0xFF16A34A), // green
  Color(0xFF0D9488), // teal
  Color(0xFF7C3AED), // purple
  Color(0xFFDB2777), // pink
  Color(0xFFDC2626), // red
  Color(0xFFCA8A04), // amber
];

/// A light tint of [c] for backgrounds behind the habit's icon.
Color tintOf(Color c) =>
    Color.alphaBlend(c.withValues(alpha: 0.12), Colors.white);
