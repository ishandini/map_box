import 'package:dartz/dartz.dart';
import '../entities/waypoint.dart';
import '../../../../core/error/failures.dart';

abstract class RouteRepository {
  Future<Either<Failure, List<Waypoint>>> getRouteWaypoints();

  Either<Failure, List<Waypoint>> getReachedWaypoints(
    List<Waypoint> waypoints,
    int userSteps,
  );

  Either<Failure, List<Waypoint>> getLandmarks(List<Waypoint> waypoints);

  Either<Failure, WaypointPosition> calculateCurrentPosition(
    List<Waypoint> waypoints,
    int userSteps,
  );
}

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
