import 'package:dartz/dartz.dart';
import '../entities/waypoint.dart';
import '../../../../core/error/failures.dart';

/// Abstract repository interface for route operations
/// Following the Dependency Inversion Principle - domain layer defines the contract
abstract class RouteRepository {
  /// Load all waypoints from the route data source
  Future<Either<Failure, List<Waypoint>>> getRouteWaypoints();

  /// Get all waypoints that user has reached based on step count
  Either<Failure, List<Waypoint>> getReachedWaypoints(
    List<Waypoint> waypoints,
    int userSteps,
  );

  /// Get all landmark waypoints from the route
  Either<Failure, List<Waypoint>> getLandmarks(List<Waypoint> waypoints);

  /// Calculate user's current position on the route based on steps
  /// Returns interpolated position if user is between waypoints
  Either<Failure, WaypointPosition> calculateCurrentPosition(
    List<Waypoint> waypoints,
    int userSteps,
  );
}

/// Represents user's current position on the route
class WaypointPosition {
  final double latitude;
  final double longitude;
  final int waypointIndex;
  final double progressToNext; // 0.0 to 1.0

  const WaypointPosition({
    required this.latitude,
    required this.longitude,
    required this.waypointIndex,
    required this.progressToNext,
  });
}
