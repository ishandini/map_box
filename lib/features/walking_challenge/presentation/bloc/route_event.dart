import 'package:equatable/equatable.dart';

abstract class RouteEvent extends Equatable {
  const RouteEvent();

  @override
  List<Object?> get props => [];
}

class LoadRouteEvent extends RouteEvent {
  const LoadRouteEvent();
}

class UpdateUserStepsEvent extends RouteEvent {
  final int stepCount;

  const UpdateUserStepsEvent(this.stepCount);

  @override
  List<Object?> get props => [stepCount];
}

class LandmarkTappedEvent extends RouteEvent {
  final int landmarkIndex;

  const LandmarkTappedEvent(this.landmarkIndex);

  @override
  List<Object?> get props => [landmarkIndex];
}

class DismissLandmarkInfoEvent extends RouteEvent {
  const DismissLandmarkInfoEvent();
}
