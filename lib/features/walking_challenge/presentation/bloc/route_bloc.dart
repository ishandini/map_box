import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/waypoint.dart';
import '../../domain/usecases/calculate_progress_usecase.dart';
import '../../domain/usecases/get_landmarks_usecase.dart';
import '../../domain/usecases/load_route_usecase.dart';
import 'route_event.dart';
import 'route_state.dart';

class RouteBloc extends Bloc<RouteEvent, RouteState> {
  final LoadRouteUseCase loadRouteUseCase;
  final CalculateProgressUseCase calculateProgressUseCase;
  final GetLandmarksUseCase getLandmarksUseCase;

  RouteBloc({
    required this.loadRouteUseCase,
    required this.calculateProgressUseCase,
    required this.getLandmarksUseCase,
  }) : super(const RouteInitial()) {
    on<LoadRouteEvent>(_onLoadRoute);
    on<UpdateUserStepsEvent>(_onUpdateUserSteps);
    on<LandmarkTappedEvent>(_onLandmarkTapped);
    on<DismissLandmarkInfoEvent>(_onDismissLandmarkInfo);
  }

  Future<void> _onLoadRoute(
    LoadRouteEvent event,
    Emitter<RouteState> emit,
  ) async {
    emit(const RouteLoading());

    final result = await loadRouteUseCase(const NoParams());

    await result.fold(
      (failure) async {
        emit(RouteError(failure.message));
      },
      (waypoints) async {
        if (waypoints.isEmpty) {
          emit(const RouteError('No waypoints found in route data'));
          return;
        }

        final landmarksResult = getLandmarksUseCase(
          LandmarkParams(waypoints: waypoints),
        );

        await landmarksResult.fold(
          (failure) async {
            emit(RouteError(failure.message));
          },
          (landmarks) async {
            final progressResult = calculateProgressUseCase(
              ProgressParams(waypoints: waypoints, userSteps: 0),
            );

            progressResult.fold(
              (failure) {
                emit(RouteError(failure.message));
              },
              (progressData) {
                emit(
                  RouteLoaded(
                    allWaypoints: waypoints,
                    reachedWaypoints: progressData.reachedWaypoints,
                    landmarks: landmarks,
                    currentPosition: progressData.currentPosition,
                    userSteps: 0,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _onUpdateUserSteps(
    UpdateUserStepsEvent event,
    Emitter<RouteState> emit,
  ) {
    if (state is! RouteLoaded) return;

    final currentState = state as RouteLoaded;

    final progressResult = calculateProgressUseCase(
      ProgressParams(
        waypoints: currentState.allWaypoints,
        userSteps: event.stepCount,
      ),
    );

    progressResult.fold(
      (failure) {
        emit(RouteError(failure.message));
      },
      (progressData) {
        final reachedLandmarks = currentState.landmarks
            .where((landmark) => landmark.hasReached(event.stepCount))
            .toList();

        Waypoint? newLandmark;
        bool shouldZoom = false;

        if (reachedLandmarks.isNotEmpty) {
          final latestReachedLandmark = reachedLandmarks.last;

          if (currentState.lastReachedLandmark == null ||
              latestReachedLandmark.cumulativeSteps !=
                  currentState.lastReachedLandmark!.cumulativeSteps) {
            newLandmark = latestReachedLandmark;
            shouldZoom = true;
          }
        }

        emit(
          currentState.copyWith(
            reachedWaypoints: progressData.reachedWaypoints,
            currentPosition: progressData.currentPosition,
            userSteps: event.stepCount,
            lastReachedLandmark:
                newLandmark ?? currentState.lastReachedLandmark,
            shouldAutoZoom: shouldZoom,
          ),
        );
      },
    );
  }

  void _onLandmarkTapped(LandmarkTappedEvent event, Emitter<RouteState> emit) {
    if (state is! RouteLoaded) return;

    final currentState = state as RouteLoaded;

    if (event.landmarkIndex >= 0 &&
        event.landmarkIndex < currentState.landmarks.length) {
      final landmark = currentState.landmarks[event.landmarkIndex];
      emit(currentState.copyWith(selectedLandmark: landmark));
    }
  }

  void _onDismissLandmarkInfo(
    DismissLandmarkInfoEvent event,
    Emitter<RouteState> emit,
  ) {
    if (state is! RouteLoaded) return;

    final currentState = state as RouteLoaded;
    emit(currentState.copyWith(clearSelectedLandmark: true));
  }
}
