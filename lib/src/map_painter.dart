import 'package:flutter/material.dart' hide Path;
import 'package:interactive_country_map/src/Interactive_map_theme.dart';
import 'package:interactive_country_map/src/svg/svg_parser.dart';

class MapPainter extends CustomPainter {
  final List<CountryPath> countries;
  final Offset? cursorPosition;
  final InteractiveMapTheme theme;
  final Offset offset;

  MapPainter({
    super.repaint,
    required this.countries,
    required this.cursorPosition,
    required this.theme,
    required this.offset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scale = theme.zoom;

    final paintFiller = Paint()
      ..color = theme.defaultCountryColor
      ..isAntiAlias = true
      ..style = PaintingStyle.fill
      ..strokeWidth = 2.0;
    final selectedPaintFiller = Paint()
      ..color = theme.defaultSelectedCountryColor
      ..isAntiAlias = true
      ..style = PaintingStyle.fill
      ..strokeWidth = 2.0;
    final paintBorder = Paint()
      ..color = Colors.white
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (var country in countries) {
      final path = country.path.toPath(scale, offset);

      canvas.drawPath(path, paintBorder);

      if (cursorPosition != null && path.contains(cursorPosition!)) {
        canvas.drawPath(path, selectedPaintFiller);
      } else {
        canvas.drawPath(path, paintFiller);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
