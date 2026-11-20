import 'package:flutter/widgets.dart';

const Record gridConfig = (spacing: 40.0);

const Color gridBackgroundColor = Color.fromARGB(255, 255, 255, 255);

// Grid rendering
final gridPaint = Paint()
  ..color = const Color.fromARGB(155, 5, 105, 255)
  ..strokeWidth = 1.0
  ..style = PaintingStyle.stroke
;

// Coordinate axes
final axesPaint = Paint()
  ..color = const Color.fromARGB(255, 255, 0, 0)
  ..strokeWidth = 1.5
  ..style = PaintingStyle.stroke
;