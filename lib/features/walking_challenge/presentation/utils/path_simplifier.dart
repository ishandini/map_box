import 'dart:math' as math;

/// Utility class for simplifying paths using Douglas-Peucker algorithm
/// This helps optimize performance when rendering routes with thousands of waypoints
class PathSimplifier {
  /// Simplify a path using Douglas-Peucker algorithm
  /// [points] - List of coordinates as [longitude, latitude]
  /// [tolerance] - Maximum distance deviation (in degrees)
  static List<List<double>> simplify(
    List<List<double>> points,
    double tolerance,
  ) {
    if (points.length <= 2) return points;

    // Find the point with the maximum distance
    double maxDistance = 0;
    int index = 0;

    final first = points.first;
    final last = points.last;

    for (int i = 1; i < points.length - 1; i++) {
      final distance = _perpendicularDistance(points[i], first, last);
      if (distance > maxDistance) {
        index = i;
        maxDistance = distance;
      }
    }

    // If max distance is greater than tolerance, recursively simplify
    if (maxDistance > tolerance) {
      // Recursive call
      final firstHalf = simplify(points.sublist(0, index + 1), tolerance);
      final secondHalf = simplify(points.sublist(index), tolerance);

      // Combine results (remove duplicate middle point)
      return [...firstHalf.sublist(0, firstHalf.length - 1), ...secondHalf];
    } else {
      // Return just the endpoints
      return [first, last];
    }
  }

  /// Calculate perpendicular distance from point to line segment
  static double _perpendicularDistance(
    List<double> point,
    List<double> lineStart,
    List<double> lineEnd,
  ) {
    final x = point[0];
    final y = point[1];
    final x1 = lineStart[0];
    final y1 = lineStart[1];
    final x2 = lineEnd[0];
    final y2 = lineEnd[1];

    final A = x - x1;
    final B = y - y1;
    final C = x2 - x1;
    final D = y2 - y1;

    final dot = A * C + B * D;
    final lenSq = C * C + D * D;

    if (lenSq == 0) {
      // Line segment is a point
      return math.sqrt((x - x1) * (x - x1) + (y - y1) * (y - y1));
    }

    final param = dot / lenSq;

    double xx, yy;

    if (param < 0) {
      xx = x1;
      yy = y1;
    } else if (param > 1) {
      xx = x2;
      yy = y2;
    } else {
      xx = x1 + param * C;
      yy = y1 + param * D;
    }

    final dx = x - xx;
    final dy = y - yy;

    return math.sqrt(dx * dx + dy * dy);
  }

  /// Adaptive simplification based on zoom level
  /// Higher zoom = less simplification
  static List<List<double>> adaptiveSimplify(
    List<List<double>> points,
    double zoomLevel,
  ) {
    // Adjust tolerance based on zoom level
    // Higher zoom = smaller tolerance (more detail)
    // Lower zoom = larger tolerance (more simplification)
    final tolerance = _calculateTolerance(zoomLevel);
    return simplify(points, tolerance);
  }

  static double _calculateTolerance(double zoomLevel) {
    // Zoom levels typically range from 0 to 22
    // At zoom 0 (world view): high tolerance (lots of simplification)
    // At zoom 22 (street view): low tolerance (minimal simplification)
    if (zoomLevel >= 16) return 0.00001; // Very detailed
    if (zoomLevel >= 12) return 0.00005; // Detailed
    if (zoomLevel >= 8) return 0.0001; // Moderate
    if (zoomLevel >= 4) return 0.0005; // Simplified
    return 0.001; // Very simplified
  }
}
