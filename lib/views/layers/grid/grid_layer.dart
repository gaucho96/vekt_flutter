
import 'package:flutter/widgets.dart';
import 'package:vekt_flutter/domain/grid.dart';
import 'grid_renderer.dart';
import 'grid.config.dart';

class Grid extends CustomPainter {
  final GridConfig gridConfig;
  final bool showGrid;
  final bool showXY;

  const Grid({required this.gridConfig, this.showGrid = true, this.showXY = true});

  @override
  void paint(Canvas canvas, Size size) {
    
    // Grid Background
    final backgroundPaint = Paint()
      ..color = gridBackgroundColor
      ..style = PaintingStyle.fill
    ;
    canvas.drawRect(
      Offset.zero & size,
      backgroundPaint,
    );

    if (showGrid) {
      drawGrid(
        canvas: canvas,
        size: size,
        paint: gridPaint,
        geometry: calculateGridGeometry(
          config: gridConfig,
          viewport: (
            width: size.width,
            height: size.height,
          ),
        ),
      );
    }

    if (showXY) {
      drawXY(
        canvas: canvas, 
        size: size, 
        paint: axesPaint
      );
    }

  }

  @override
  bool shouldRepaint(covariant Grid oldDelegate) {
    return false;
  }
}
