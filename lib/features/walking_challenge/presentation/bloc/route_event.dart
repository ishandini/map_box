import 'package:equatable/equatable.dart';

/// Base class for all route events
abstract class RouteEvent extends Equatable {
  const RouteEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load route data from data source
class LoadRouteEvent extends RouteEvent {
  const LoadRouteEvent();
}

/// Event to update user's step count and recalculate progress
class UpdateUserStepsEvent extends RouteEvent {
  final int stepCount;

  const UpdateUserStepsEvent(this.stepCount);

  @override
  List<Object?> get props => [stepCount];
}

/// Event to handle landmark tap
class LandmarkTappedEvent extends RouteEvent {
  final int landmarkIndex;

  const LandmarkTappedEvent(this.landmarkIndex);

  @override
  List<Object?> get props => [landmarkIndex];
}

/// Event to dismiss landmark info
class DismissLandmarkInfoEvent extends RouteEvent {
  const DismissLandmarkInfoEvent();
}
