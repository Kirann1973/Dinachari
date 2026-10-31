import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app.dart';

/// A simple bar chart: one bar per value (0..1), labels under the bars.
/// Null values draw as an empty slot (nothing due that day).
class BarChart extends StatelessWidget {
  const BarChart({
    super.key,
    required this.values,
    required this.labels,
    this.height = 140,
    this.color = DC.accent,
    this.highlight,
    this.semanticsLabel,
  });

  final List<double?> values;
  final List<String> labels;
  final double height;
  final Color color;

  /// Index drawn with a dark outline (e.g. today).
  final int? highlight;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      child: SizedBox(
        height: height,
        child: CustomPaint(
          size: Size.infinite,
          painter: _BarPainter(values, labels, color, highlight),
        ),
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter(this.values, this.labels, this.color, this.highlight);

  final List<double?> values;
  final List<String> labels;
  final Color color;
  final int? highlight;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    const labelHeight = 18.0;
    final chartH = size.height - labelHeight - 4;
    final slot = size.width / values.length;
    final barW = math.min(28.0, slot * 0.62);
    final track = Paint()..color = DC.soft;
    final fill = Paint()..color = color;

    // Guide lines at 50% and 100%.
    final guide = Paint()
      ..color = DC.line
      ..strokeWidth = 1;
    for (final f in [0.5, 1.0]) {
      final y = chartH * (1 - f);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), guide);
    }

    for (var i = 0; i < values.length; i++) {
      final x = slot * i + (slot - barW) / 2;
      final r = Radius.circular(math.min(6, barW / 2));
      canvas.drawRRect(RRect.fromLTRBR(x, 0, x + barW, chartH, r), track);
      final v = values[i];
      if (v != null && v > 0) {
        final h = chartH * v.clamp(0, 1);
        canvas.drawRRect(
          RRect.fromLTRBR(x, chartH - h, x + barW, chartH, r),
          fill,
        );
      }
      if (i == highlight) {
        canvas.drawRRect(
          RRect.fromLTRBR(x - 1.5, -1.5, x + barW + 1.5, chartH + 1.5, r),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = DC.ink,
        );
      }
      // Only label some bars when there are many.
      final every = values.length > 14 ? 5 : 1;
      if (i < labels.length && (i % every == 0 || i == values.length - 1)) {
        final tp = TextPainter(
          text: TextSpan(
            text: labels[i],
            style: const TextStyle(
              fontFamily: DC.body,
              fontSize: 11,
              color: DC.muted,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(slot * i + (slot - tp.width) / 2, chartH + 6));
      }
    }
  }

  @override
  bool shouldRepaint(_BarPainter old) =>
      old.values != values || old.color != color || old.highlight != highlight;
}

/// The streak plant, drawn for levels 0 (seed) to 5 (in bloom).
class PlantPainter extends CustomPainter {
  PlantPainter(this.level);

  final int level;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final potTop = h * 0.72;

    // Soil peeking out of the pot.
    final soil = Paint()..color = const Color(0xFF6B4423);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, potTop),
        width: w * 0.42,
        height: h * 0.06,
      ),
      soil,
    );

    final stemTop = potTop - h * [0.0, 0.14, 0.26, 0.40, 0.52, 0.60][level];
    if (level == 0) {
      // A seed.
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, potTop - h * 0.02),
          width: w * 0.07,
          height: h * 0.05,
        ),
        Paint()..color = const Color(0xFF8B5A2B),
      );
    } else {
      final stem = Paint()
        ..color = const Color(0xFF2F7D3E)
        ..strokeWidth = w * 0.022
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(cx, potTop), Offset(cx, stemTop), stem);

      final leafDark = Paint()..color = const Color(0xFF4CAF5C);
      final leafLight = Paint()..color = const Color(0xFF6BC478);
      final leaves = [2, 2, 4, 6, 6][level - 1];
      for (var i = 0; i < leaves; i++) {
        final t = (i ~/ 2 + 1) / (leaves / 2 + 1);
        final y = potTop - (potTop - stemTop) * t;
        final left = i.isEven;
        final len = w * (0.18 - 0.02 * (i ~/ 2));
        final path = Path()
          ..moveTo(cx, y)
          ..quadraticBezierTo(
            cx + (left ? -len : len),
            y - len * 0.1,
            cx + (left ? -len : len),
            y - len * 0.75,
          )
          ..quadraticBezierTo(
            cx + (left ? -len * 0.2 : len * 0.2),
            y - len * 0.6,
            cx,
            y,
          );
        canvas.drawPath(path, i % 4 < 2 ? leafDark : leafLight);
      }

      if (level == 5) {
        final petal = Paint()..color = const Color(0xFFF97316);
        for (var i = 0; i < 6; i++) {
          final a = i * math.pi / 3;
          canvas.drawCircle(
            Offset(
              cx + math.cos(a) * w * 0.05,
              stemTop + math.sin(a) * w * 0.05,
            ),
            w * 0.045,
            petal,
          );
        }
        canvas.drawCircle(
          Offset(cx, stemTop),
          w * 0.04,
          Paint()..color = const Color(0xFFFCD34D),
        );
      }
    }

    // The pot, in the app's orange.
    final pot = Path()
      ..moveTo(cx - w * 0.2, potTop)
      ..lineTo(cx + w * 0.2, potTop)
      ..lineTo(cx + w * 0.16, h * 0.98)
      ..lineTo(cx - w * 0.16, h * 0.98)
      ..close();
    canvas.drawPath(pot, Paint()..color = DC.accentDeep);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - w * 0.23, potTop - h * 0.02, w * 0.46, h * 0.07),
        const Radius.circular(4),
      ),
      Paint()..color = DC.accentDarker,
    );
  }

  @override
  bool shouldRepaint(PlantPainter old) => old.level != level;
}
