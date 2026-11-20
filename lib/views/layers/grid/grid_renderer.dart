import 'dart:ui';
import 'package:vekt_flutter/domain/grid.dart';

typedef XYRec = ({
  Color gridAxisColor,
  PaintingStyle strokeStyle,
  double stroke,
});

/// Draws precomputed grid geometry onto a Canvas.
void drawGrid({
  required Canvas canvas,
  required Size size,
  required GridGeometry geometry,
  required Paint paint,
}) 
{

  // Vertical lines: top → bottom.
  for (final x in geometry.verticalLines) {
    canvas.drawLine(
      Offset(x, 0),
      Offset(x, size.height),
      paint,
    );
  }

  // Horizontal lines: left → right.
  for (final y in geometry.horizontalLines) {
    canvas.drawLine(
      Offset(0, y),
      Offset(size.width, y),
      paint,
    );
  }
}

void drawXY({
  required Canvas canvas,
  required Size size,
  required Paint paint,
})
{

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    canvas.drawLine(
      Offset(centerX, 0),
      Offset(centerX, size.height),
      paint,
    );

    canvas.drawLine(
      Offset(0, centerY),
      Offset(size.width, centerY),
      paint,
    );

}