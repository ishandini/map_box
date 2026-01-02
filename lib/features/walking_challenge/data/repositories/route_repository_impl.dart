import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/waypoint.dart';
import '../../domain/repositories/route_repository.dart';
import '../datasources/route_local_datasource.dart';

/// Implementation of RouteRepository
class RouteRepositoryImpl implements RouteRepository {
  final RouteLocalDataSource localDataSource;

  RouteRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<Waypoint>>> getRouteWaypoints() async {
    try {
      final waypoints = await localDataSource.loadRouteWaypoints();
      return Right(waypoints);
    } on DataSourceException catch (e) {
      return Left(DataSourceFailure(e.message));
    } catch (e) {
      return Left(DataSourceFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Either<Failure, List<Waypoint>> getReachedWaypoints(
    List<Waypoint> waypoints,
    int userSteps,
  ) {
    try {
      if (waypoints.isEmpty) {
        return const Right([]);
      }

      final reachedWaypoints = waypoints
          .where((waypoint) => waypoint.cumulativeSteps <= userSteps)
          .toList();

      return Right(reachedWaypoints);
    } catch (e) {
      return Left(CalculationFailure('Failed to get reached waypoints: $e'));
    }
  }

  @override
  Either<Failure, List<Waypoint>> getLandmarks(List<Waypoint> waypoints) {
    try {
      final landmarks = waypoints.where((w) => w.isLandmark).toList();
      return Right(landmarks);
    } catch (e) {
      return Left(CalculationFailure('Failed to get landmarks: $e'));
    }
  }

  @override
  Either<Failure, WaypointPosition> calculateCurrentPosition(
    List<Waypoint> waypoints,
    int userSteps,
  ) {
    try {
      if (waypoints.isEmpty) {
        return const Left(
          CalculationFailure('Cannot calculate position: waypoints list is empty'),
        );
      }

      // If user hasn't started, return first waypoint
      if (userSteps <= 0) {
        return Right(
          WaypointPosition(
            latitude: waypoints.first.latitude,
            longitude: waypoints.first.longitude,
            waypointIndex: 0,
            progressToNext: 0.0,
          ),
        );
      }

      // If user has completed the route, return last waypoint
      if (userSteps >= waypoints.last.cumulativeSteps) {
        return Right(
          WaypointPosition(
            latitude: waypoints.last.latitude,
            longitude: waypoints.last.longitude,
            waypointIndex: waypoints.length - 1,
            progressToNext: 1.0,
          ),
        );
      }

      // Find the waypoint segment user is currently in
      for (int i = 0; i < waypoints.length - 1; i++) {
        final currentWaypoint = waypoints[i];
        final nextWaypoint = waypoints[i + 1];

        if (userSteps >= currentWaypoint.cumulativeSteps &&
            userSteps < nextWaypoint.cumulativeSteps) {
          // Calculate progress between current and next waypoint
          final stepsBetween =
              nextWaypoint.cumulativeSteps - currentWaypoint.cumulativeSteps;
          final stepsFromCurrent = userSteps - currentWaypoint.cumulativeSteps;
          final progress = stepsBetween > 0
              ? (stepsFromCurrent / stepsBetween).clamp(0.0, 1.0)
              : 0.0;

          // Interpolate position
          final latitude = _interpolate(
            currentWaypoint.latitude,
            nextWaypoint.latitude,
            progress,
          );
          final longitude = _interpolate(
            currentWaypoint.longitude,
            nextWaypoint.longitude,
            progress,
          );

          return Right(
            WaypointPosition(
              latitude: latitude,
              longitude: longitude,
              waypointIndex: i,
              progressToNext: progress,
            ),
          );
        }
      }

      // Fallback: return last waypoint
      return Right(
        WaypointPosition(
          latitude: waypoints.last.latitude,
          longitude: waypoints.last.longitude,
          waypointIndex: waypoints.length - 1,
          progressToNext: 1.0,
        ),
      );
    } catch (e) {
      return Left(CalculationFailure('Failed to calculate position: $e'));
    }
  }

  /// Linear interpolation between two values
  double _interpolate(double start, double end, double progress) {
    return start + (end - start) * progress;
  }
}
