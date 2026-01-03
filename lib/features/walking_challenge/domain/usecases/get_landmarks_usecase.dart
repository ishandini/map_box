import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/waypoint.dart';
import '../repositories/route_repository.dart';

class GetLandmarksUseCase
    implements SyncUseCase<List<Waypoint>, LandmarkParams> {
  final RouteRepository repository;

  GetLandmarksUseCase(this.repository);

  @override
  Either<Failure, List<Waypoint>> call(LandmarkParams params) {
    return repository.getLandmarks(params.waypoints);
  }
}

class LandmarkParams {
  final List<Waypoint> waypoints;

  const LandmarkParams({required this.waypoints});
}
