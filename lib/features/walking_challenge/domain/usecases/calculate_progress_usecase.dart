import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/waypoint.dart';
import '../repositories/route_repository.dart';

class CalculateProgressUseCase
    implements SyncUseCase<ProgressResult, ProgressParams> {
  final RouteRepository repository;

  CalculateProgressUseCase(this.repository);

  @override
  Either<Failure, ProgressResult> call(ProgressParams params) {
    final reachedResult = repository.getReachedWaypoints(
      params.waypoints,
      params.userSteps,
    );

    return reachedResult.fold((failure) => Left(failure), (reachedWaypoints) {
      final positionResult = repository.calculateCurrentPosition(
        params.waypoints,
        params.userSteps,
      );

      return positionResult.fold(
        (failure) => Left(failure),
        (currentPosition) => Right(
          ProgressResult(
            reachedWaypoints: reachedWaypoints,
            currentPosition: currentPosition,
          ),
        ),
      );
    });
  }
}

class ProgressParams {
  final List<Waypoint> waypoints;
  final int userSteps;

  const ProgressParams({required this.waypoints, required this.userSteps});
}

class ProgressResult {
  final List<Waypoint> reachedWaypoints;
  final WaypointPosition currentPosition;

  const ProgressResult({
    required this.reachedWaypoints,
    required this.currentPosition,
  });
}
