import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class DataSourceFailure extends Failure {
  const DataSourceFailure(super.message);
}

class ParsingFailure extends Failure {
  const ParsingFailure(super.message);
}

class CalculationFailure extends Failure {
  const CalculationFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

class FileFailure extends Failure {
  const FileFailure(super.message);
}
