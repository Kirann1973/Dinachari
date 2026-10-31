import 'dart:io';

import 'package:flutter/material.dart';

import '../app.dart';
import '../domain/habit_look.dart';
import '../domain/habit_style.dart';
import '../domain/symbols.dart';

/// Draws a habit's look (emoji, icon, photo or text) in a circle.
class HabitLookView extends StatelessWidget {
  const HabitLookView({
    super.key,
    required this.look,
    required this.color,
    this.size = 36,
    this.filled = false,
  });

  /// The stored look string, e.g. `emoji:🛁🧴` or `icon:fitness_center`.
  final String look;
  final Color color;
  final double size;

  /// Solid habit color behind the look instead of a light tint.
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final parsed = HabitLook.parse(look);
    final fg = filled ? Colors.white : deepOf(color);
    final bg = filled ? deepOf(color) : tintOf(color);

    final Widget inner = switch (parsed) {
      PhotoLook(:final path) => ClipOval(
        child: Image.file(
          File(path),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _glyph('broken_image', fg),
        ),
      ),
      EmojiLook(:final emoji) => _emoji(emoji),
      TextLook(:final text) => Text(
        text,
        maxLines: 1,
        style: TextStyle(
          fontFamily: DC.display,
          fontWeight: FontWeight.w700,
          fontSize: size * (text.characters.length > 2 ? 0.3 : 0.38),
          color: fg,
          height: 1,
        ),
      ),
      IconLook(:final name) => _glyph(name, fg),
    };

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: parsed is PhotoLook ? null : bg,
      ),
      child: inner,
    );
  }

  Widget _emoji(String emoji) {
    final n = emoji.characters.length.clamp(1, HabitLook.maxParts);
    return Text(
      emoji,
      maxLines: 1,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize:
            size *
            (n == 1
                ? 0.52
                : n == 2
                ? 0.34
                : 0.26),
        height: 1,
      ),
    );
  }

  Widget _glyph(String name, Color fg) {
    final symbol = SymbolCatalog.instance.byName(name);
    if (symbol == null) {
      return Icon(Icons.check_circle_outline, size: size * 0.58, color: fg);
    }
    return SymbolGlyph(symbol, size: size * 0.58, color: fg);
  }
}

/// One Material Symbols icon drawn from the bundled font.
class SymbolGlyph extends StatelessWidget {
  const SymbolGlyph(
    this.symbol, {
    super.key,
    required this.size,
    required this.color,
  });

  final SymbolIcon symbol;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      symbol.glyph,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: SymbolCatalog.fontFamily,
        fontSize: size,
        height: 1,
        color: color,
        // Keep the font's own glyph shapes, not a fallback font.
        fontFamilyFallback: const [],
      ),
    );
  }
}
