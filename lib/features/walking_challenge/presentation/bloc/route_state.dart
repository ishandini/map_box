import 'package:equatable/equatable.dart';
import '../../domain/entities/waypoint.dart';
import '../../domain/repositories/route_repository.dart';

/// Base class for all route states
abstract class RouteState extends Equatable {
  const RouteState();

  @override
  List<Object?> get props => [];
}

/// Initial state before loading
class RouteInitial extends RouteState {
  const RouteInitial();
}

/// State when route is being loaded
class RouteLoading extends RouteState {
  const RouteLoading();
}

/// State when route is loaded successfully
class RouteLoaded extends RouteState {
  final List<Waypoint> allWaypoints;
  final List<Waypoint> reachedWaypoints;
  final List<Waypoint> landmarks;
  final WaypointPosition currentPosition;
  final int userSteps;
  final Waypoint? selectedLandmark;
  final Waypoint? lastReachedLandmark; // Track for auto-zoom
  final bool shouldAutoZoom; // Flag to trigger zoom animation

  const RouteLoaded({
    required this.allWaypoints,
    required this.reachedWaypoints,
    required this.landmarks,
    required this.currentPosition,
    required this.userSteps,
    this.selectedLandmark,
    this.lastReachedLandmark,
    this.shouldAutoZoom = false,
  });

  /// Create a copy with updated fields
  RouteLoaded copyWith({
    List<Waypoint>? allWaypoints,
    List<Waypoint>? reachedWaypoints,
    List<Waypoint>? landmarks,
    WaypointPosition? currentPosition,
    int? userSteps,
    Waypoint? selectedLandmark,
    bool clearSelectedLandmark = false,
    Waypoint? lastReachedLandmark,
    bool? shouldAutoZoom,
  }) {
    return RouteLoaded(
      allWaypoints: allWaypoints ?? this.allWaypoints,
      reachedWaypoints: reachedWaypoints ?? this.reachedWaypoints,
      landmarks: landmarks ?? this.landmarks,
      currentPosition: currentPosition ?? this.currentPosition,
      userSteps: userSteps ?? this.userSteps,
      selectedLandmark: clearSelectedLandmark ? null : (selectedLandmark ?? this.selectedLandmark),
      lastReachedLandmark: lastReachedLandmark ?? this.lastReachedLandmark,
      shouldAutoZoom: shouldAutoZoom ?? false,
    );
  }

  @override
  List<Object?> get props => [
        allWaypoints,
        reachedWaypoints,
        landmarks,
        currentPosition,
        userSteps,
        selectedLandmark,
        lastReachedLandmark,
        shouldAutoZoom,
      ];
}

/// State when route loading fails
class RouteError extends RouteState {
  final String message;

  const RouteError(this.message);

  @override
  List<Object?> get props => [message];
}
