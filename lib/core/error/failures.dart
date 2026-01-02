import 'package:equatable/equatable.dart';

/// Base class for all failures in the application
/// Following clean architecture principles for error handling
abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

/// Failure when data source operations fail
class DataSourceFailure extends Failure {
  const DataSourceFailure(super.message);
}

/// Failure when JSON parsing fails
class ParsingFailure extends Failure {
  const ParsingFailure(super.message);
}

/// Failure when calculations fail
class CalculationFailure extends Failure {
  const CalculationFailure(super.message);
}

/// Failure when cache operations fail
class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

/// Failure when file operations fail
class FileFailure extends Failure {
  const FileFailure(super.message);
}
