import 'package:flutter/widgets.dart';
import 'package:vekt_flutter/domain/grid.dart' show GridConfig;
import 'layers/grid/grid_layer.dart';
import 'layers/grid/grid.config.dart';

typedef Layers = Widget;
class Stage extends StatelessWidget {
  const Stage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Stack(
      // Stack is Directionality-sensitive, thus to avoid app-level Error we MUST explicitly set [textDirection], for example:
      textDirection: TextDirection.ltr,
      fit: StackFit.expand,
      children: <Layers>[
        CustomPaint(
          painter: Grid(
            gridConfig: gridConfig as GridConfig,
            showGrid: !false,
            showXY: !false,
          )
        ),
      ],
    );
  }
}
