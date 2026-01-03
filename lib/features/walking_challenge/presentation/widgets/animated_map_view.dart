import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../../../core/services/step_counter_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/waypoint.dart';
import '../bloc/route_bloc.dart';
import '../bloc/route_event.dart';
import '../bloc/route_state.dart';
import '../utils/map_layer_manager.dart';
import '../utils/bearing_calculator.dart';
import 'landmark_info_sheet.dart';

class AnimatedMapView extends StatefulWidget {
  const AnimatedMapView({super.key});

  @override
  State<AnimatedMapView> createState() => _AnimatedMapViewState();
}

class _AnimatedMapViewState extends State<AnimatedMapView>
    with TickerProviderStateMixin {
  MapboxMap? _mapboxMap;
  MapLayerManager? _layerManager;
  bool _animationStarted = false;
  bool _hasShownFullRoute = false;
  bool _hasShownFirstProgress = false;
  AnimationController? _pathAnimationController;
  AnimationController? _progressAnimationController;
  List<List<double>>? _previousProgressCoords;

  static const double targetLongitude = 100.57545;
  static const double targetLatitude = 13.70374;
  static const double spaceZoom = 1.0;
  static const double navigationZoom = 17.0;
  static const double navigationPitch = 60.0;
  static const int navigationAnimationDuration = 1800;

  @override
  void initState() {
    super.initState();
    _pathAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );
    _progressAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _pathAnimationController?.dispose();
    _progressAnimationController?.dispose();
    super.dispose();
  }

  void _onMapCreated(MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
    _layerManager = MapLayerManager(mapboxMap);
  }

  void _onStyleLoaded(StyleLoadedEventData data) {
    if (!_animationStarted) {
      _animationStarted = true;
      _startAnimation();
    }
  }

  Future<void> _startAnimation() async {
    if (_mapboxMap == null || !mounted) return;

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    _mapboxMap!.easeTo(
      CameraOptions(
        center: Point(coordinates: Position(targetLongitude, 0)),
        zoom: spaceZoom,
        bearing: 0,
        pitch: 0,
      ),
      MapAnimationOptions(duration: 6000, startDelay: 0),
    );
    await Future.delayed(const Duration(milliseconds: 6000));
    if (!mounted) return;

    _loadRouteData();
  }

  /// Load route data using BLoC
  void _loadRouteData() {
    if (!mounted) return;
    try {
      context.read<RouteBloc>().add(const LoadRouteEvent());
    } catch (e) {
      debugPrint('RouteBloc not available yet: $e');
    }
  }

  /// Draw full route path (without animation)
  Future<void> _drawFullRoutePath(List<Waypoint> waypoints) async {
    if (_layerManager == null || waypoints.isEmpty) return;

    final allCoordinates = waypoints.map((w) {
      final coords = w.toCoordinates();
      return [coords[0].toDouble(), coords[1].toDouble()];
    }).toList();

    await _layerManager!.addFullRoutePathWithCoordinates(allCoordinates);
  }

  /// Animate path drawing from start to end with smooth easing
  Future<void> _animatePathDrawing(List<Waypoint> waypoints) async {
    if (_pathAnimationController == null || _layerManager == null) return;

    final curvedAnimation = CurvedAnimation(
      parent: _pathAnimationController!,
      curve: Curves.easeInOutCubic,
    );

    _pathAnimationController!.reset();

    void updatePath() {
      final progress = curvedAnimation.value;
      final pointsToShow = (waypoints.length * progress).round().clamp(
        2,
        waypoints.length,
      );
      final partialWaypoints = waypoints.sublist(0, pointsToShow);
      _layerManager!.updateFullRoutePath(partialWaypoints);
    }

    curvedAnimation.addListener(updatePath);
    await _pathAnimationController!.forward();
    curvedAnimation.removeListener(updatePath);
    curvedAnimation.dispose();
  }

  /// Update progress path from reached waypoints + user position
  /// Uses all waypoints with no simplification to ensure perfect alignment with orange line
  /// Animates smoothly from previous progress to new progress
  Future<void> _animateProgressPath(
    List<Waypoint> allWaypoints,
    List<Waypoint> newReachedWaypoints,
    double userLatitude,
    double userLongitude,
  ) async {
    if (_layerManager == null || newReachedWaypoints.isEmpty) {
      return;
    }

    final targetCoordinates = <List<double>>[];
    for (final waypoint in newReachedWaypoints) {
      final coords = waypoint.toCoordinates();
      targetCoordinates.add([coords[0].toDouble(), coords[1].toDouble()]);
    }

    targetCoordinates.add([userLongitude, userLatitude]);

    if (_previousProgressCoords == null || _previousProgressCoords!.isEmpty) {
      _previousProgressCoords = targetCoordinates.sublist(
        0,
        2.clamp(0, targetCoordinates.length),
      );
    }

    if (_progressAnimationController == null || !mounted) return;

    _progressAnimationController!.reset();

    final curvedAnimation = CurvedAnimation(
      parent: _progressAnimationController!,
      curve: Curves.easeInOutCubic,
    );

    void updateProgress() {
      if (!mounted || _layerManager == null) return;

      final progress = curvedAnimation.value;

      if (targetCoordinates.length >= _previousProgressCoords!.length) {
        final coordsToShow =
            (_previousProgressCoords!.length +
                    (targetCoordinates.length -
                            _previousProgressCoords!.length) *
                        progress)
                .round()
                .clamp(2, targetCoordinates.length);

        final animatedCoords = targetCoordinates.sublist(0, coordsToShow);

        _layerManager!.updateProgressPathWithCoordinates(animatedCoords);

        final currentEndPoint = animatedCoords.last;
        _layerManager!.updateUserMarker(
          currentEndPoint[1],
          currentEndPoint[0],
        );
      } else {
        _layerManager!.updateProgressPathWithCoordinates(targetCoordinates);
        _layerManager!.updateUserMarker(userLatitude, userLongitude);
      }
    }

    curvedAnimation.addListener(updateProgress);
    await _progressAnimationController!.forward();
    curvedAnimation.removeListener(updateProgress);
    curvedAnimation.dispose();

    _previousProgressCoords = targetCoordinates;
  }

  /// Fit camera to show all route waypoints
  /// Used when route is first drawn to show the complete path
  Future<void> _fitCameraToRoute(List<Waypoint> waypoints) async {
    if (_mapboxMap == null || !mounted || waypoints.isEmpty) return;

    double minLat = waypoints.first.latitude;
    double maxLat = waypoints.first.latitude;
    double minLon = waypoints.first.longitude;
    double maxLon = waypoints.first.longitude;

    for (final waypoint in waypoints) {
      if (waypoint.latitude < minLat) minLat = waypoint.latitude;
      if (waypoint.latitude > maxLat) maxLat = waypoint.latitude;
      if (waypoint.longitude < minLon) minLon = waypoint.longitude;
      if (waypoint.longitude > maxLon) maxLon = waypoint.longitude;
    }

    final latPadding = (maxLat - minLat) * 0.2;
    final lonPadding = (maxLon - minLon) * 0.2;

    final centerLat = (minLat + maxLat) / 2;
    final centerLon = (minLon + maxLon) / 2;

    final latDelta = (maxLat - minLat) + (latPadding * 2);
    final lonDelta = (maxLon - minLon) + (lonPadding * 2);
    final maxDelta = latDelta > lonDelta ? latDelta : lonDelta;

    double zoom = 11.0;
    if (maxDelta < 0.01) {
      zoom = 15.0;
    } else if (maxDelta < 0.05) {
      zoom = 13.0;
    } else if (maxDelta < 0.1) {
      zoom = 12.0;
    } else if (maxDelta < 0.5) {
      zoom = 10.0;
    } else if (maxDelta < 1.0) {
      zoom = 9.0;
    } else {
      zoom = 8.0;
    }

    await _mapboxMap!.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(centerLon, centerLat)),
        zoom: zoom,
        bearing: 0,
        pitch: 0,
      ),
      MapAnimationOptions(duration: 2000, startDelay: 0),
    );
  }

  /// Update camera to follow user's current position in navigation mode
  /// Path will point upward (bearing rotates map so direction of travel is up)
  Future<void> _updateNavigationCamera(
    List<Waypoint> allWaypoints,
    double currentLat,
    double currentLon,
    int currentWaypointIndex,
  ) async {
    if (_mapboxMap == null || !mounted) return;

    final bearing = BearingCalculator.calculatePathBearing(
      allWaypoints,
      currentWaypointIndex,
      currentLat,
      currentLon,
    );

    _mapboxMap!.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(currentLon, currentLat)),
        zoom: navigationZoom,
        bearing: bearing,
        pitch: navigationPitch,
      ),
      MapAnimationOptions(duration: navigationAnimationDuration, startDelay: 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          BlocBuilder<RouteBloc, RouteState>(
            builder: (context, state) {
              if (state is RouteLoaded) {
                return Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: () {
                        final currentSteps =
                            StepCounterService.getUserStepCount();
                        final newSteps = (currentSteps - 1000).clamp(0, 999999);
                        StepCounterService.setUserStepCount(newSteps);
                        context.read<RouteBloc>().add(
                          UpdateUserStepsEvent(newSteps),
                        );
                      },
                    ),
                    Text(
                      '${state.userSteps}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        StepCounterService.incrementSteps(1000);
                        final newSteps = StepCounterService.getUserStepCount();
                        context.read<RouteBloc>().add(
                          UpdateUserStepsEvent(newSteps),
                        );
                      },
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          MapWidget(
            cameraOptions: CameraOptions(
              center: Point(coordinates: Position(0, 20)),
              zoom: spaceZoom,
              bearing: 0,
              pitch: 0,
            ),
            onMapCreated: _onMapCreated,
            onStyleLoadedListener: _onStyleLoaded,
          ),
          BlocConsumer<RouteBloc, RouteState>(
            listener: (context, state) async {
              if (state is RouteLoaded) {
                if (!_hasShownFullRoute && state.allWaypoints.isNotEmpty) {
                  await _fitCameraToRoute(state.allWaypoints);
                  if (!mounted) return;

                  await _animatePathDrawing(state.allWaypoints);
                  _hasShownFullRoute = true;
                  if (!mounted) return;
                } else {
                  await _drawFullRoutePath(state.allWaypoints);
                  if (!mounted) return;
                }

                await _layerManager!.updateLandmarkMarkers(
                  state.landmarks,
                  state.userSteps,
                );
                if (!mounted) return;

                if (state.userSteps > 0 && _layerManager != null) {
                  if (!_hasShownFirstProgress && _hasShownFullRoute) {
                    await _animateProgressPath(
                      state.allWaypoints,
                      state.reachedWaypoints,
                      state.currentPosition.latitude,
                      state.currentPosition.longitude,
                    );
                    if (!mounted) return;

                    if (_mapboxMap != null && state.allWaypoints.isNotEmpty) {
                      await _updateNavigationCamera(
                        state.allWaypoints,
                        state.currentPosition.latitude,
                        state.currentPosition.longitude,
                        state.currentPosition.waypointIndex,
                      );
                      if (!mounted) return;
                    }

                    _hasShownFirstProgress = true;
                  } else {
                    final futures = <Future<void>>[];

                    futures.add(
                      _animateProgressPath(
                        state.allWaypoints,
                        state.reachedWaypoints,
                        state.currentPosition.latitude,
                        state.currentPosition.longitude,
                      ),
                    );

                    if (_hasShownFullRoute &&
                        _mapboxMap != null &&
                        state.allWaypoints.isNotEmpty) {
                      futures.add(
                        _updateNavigationCamera(
                          state.allWaypoints,
                          state.currentPosition.latitude,
                          state.currentPosition.longitude,
                          state.currentPosition.waypointIndex,
                        ),
                      );
                    }

                    await Future.wait(futures);
                    if (!mounted) return;
                  }
                }

                if (state.selectedLandmark != null && mounted) {
                  LandmarkInfoSheet.show(
                    context,
                    state.selectedLandmark!,
                    state.userSteps,
                  );
                  if (mounted) {
                    context.read<RouteBloc>().add(
                      const DismissLandmarkInfoEvent(),
                    );
                  }
                }
              }
            },
            builder: (context, state) {
              if (state is RouteLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.white),
                );
              }

              if (state is RouteError) {
                return Center(
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.errorBackground.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppColors.white,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading route',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.message,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            context.read<RouteBloc>().add(
                              const LoadRouteEvent(),
                            );
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }
}
