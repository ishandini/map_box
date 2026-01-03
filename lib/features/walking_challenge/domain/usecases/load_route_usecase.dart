import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/waypoint.dart';
import '../repositories/route_repository.dart';

class LoadRouteUseCase implements UseCase<List<Waypoint>, NoParams> {
  final RouteRepository repository;

  LoadRouteUseCase(this.repository);

  @override
  Future<Either<Failure, List<Waypoint>>> call(NoParams params) async {
    return await repository.getRouteWaypoints();
  }
}
