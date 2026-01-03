import 'dart:math' as math;
import '../../domain/entities/waypoint.dart';

class BearingCalculator {
  /// Calculate bearing from point A to point B in degrees (0-360)
  /// 0° = North, 90° = East, 180° = South, 270° = West
  static double calculateBearing(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    // Convert to radians
    final lat1Rad = _degreesToRadians(lat1);
    final lat2Rad = _degreesToRadians(lat2);
    final dLon = _degreesToRadians(lon2 - lon1);

    // Calculate bearing using formula
    final y = math.sin(dLon) * math.cos(lat2Rad);
    final x =
        math.cos(lat1Rad) * math.sin(lat2Rad) -
        math.sin(lat1Rad) * math.cos(lat2Rad) * math.cos(dLon);

    final bearingRad = math.atan2(y, x);
    final bearingDeg = _radiansToDegrees(bearingRad);

    // Normalize to 0-360
    return (bearingDeg + 360) % 360;
  }

  /// Calculate bearing for the path ahead based on current position and waypoints
  /// Returns bearing in degrees for camera rotation
  static double calculatePathBearing(
    List<Waypoint> allWaypoints,
    int currentWaypointIndex,
    double currentLat,
    double currentLon,
  ) {
    // If we're at or past the last waypoint, use the bearing of the last segment
    if (currentWaypointIndex >= allWaypoints.length - 1) {
      if (allWaypoints.length >= 2) {
        final secondLast = allWaypoints[allWaypoints.length - 2];
        final last = allWaypoints[allWaypoints.length - 1];
        return calculateBearing(
          secondLast.latitude,
          secondLast.longitude,
          last.latitude,
          last.longitude,
        );
      }
      return 0; // Default to north if not enough points
    }

    // Calculate bearing to the next waypoint
    final nextWaypoint = allWaypoints[currentWaypointIndex + 1];
    return calculateBearing(
      currentLat,
      currentLon,
      nextWaypoint.latitude,
      nextWaypoint.longitude,
    );
  }

  static double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180.0;
  }

  static double _radiansToDegrees(double radians) {
    return radians * 180.0 / math.pi;
  }
}
