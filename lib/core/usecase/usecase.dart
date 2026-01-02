import 'package:dartz/dartz.dart';
import '../error/failures.dart';

/// Base class for all use cases
/// T is the return type, Params is the input parameters
abstract class UseCase<T, Params> {
  Future<Either<Failure, T>> call(Params params);
}

/// Base class for synchronous use cases
abstract class SyncUseCase<T, Params> {
  Either<Failure, T> call(Params params);
}

/// Used when a use case doesn't require any parameters
class NoParams {
  const NoParams();
}
