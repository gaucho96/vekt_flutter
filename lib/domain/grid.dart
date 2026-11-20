typedef GridConfig = ({
  double spacing,
});

typedef ViewportSize = ({
  double width,
  double height,
});

typedef GridGeometry = ({
  List<double> verticalLines,
  List<double> horizontalLines,
});

/// Calculates grid-line positions along one dimension.
List<double> _gridLinePositions({
  required double extent,
  required double center,
  required double spacing,
}) 
{
  final minIndex = (-center / spacing).ceil();
  final maxIndex = ((extent - center) / spacing).floor();

  return List<double>.unmodifiable([
    for (var i = minIndex; i <= maxIndex; i++)
      center + i * spacing,
  ]);
}

/// Calculates grid geometry from configuration and viewport dimensions.
GridGeometry calculateGridGeometry({
  required GridConfig config,
  required ViewportSize viewport,
}) 
{
  final centerX = viewport.width / 2, centerY = viewport.height / 2;
  final spacing = config.spacing;
  /// Make sure [spacing] is valid positive non-infinite, non-zero value
  if (!spacing.isFinite || spacing <= 0) {
    throw ArgumentError.value(
      spacing,
      'spacing',
      'Grid spacing must be finite and greater than zero.',
    );
  }

  return (
    verticalLines: _gridLinePositions(
      extent: viewport.width,
      center: centerX,
      spacing: spacing,
    ),
    horizontalLines: _gridLinePositions(
      extent: viewport.height,
      center: centerY,
      spacing: spacing,
    ),
  );
}

