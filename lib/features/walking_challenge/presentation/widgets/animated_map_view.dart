import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../../../core/services/step_counter_service.dart';
import '../../domain/entities/waypoint.dart';
import '../bloc/route_bloc.dart';
import '../bloc/route_event.dart';
import '../bloc/route_state.dart';
import '../utils/map_layer_manager.dart';
import '../utils/bearing_calculator.dart';
import 'landmark_info_sheet.dart';

/// Enhanced AnimatedMapView with walking challenge route visualization
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
  bool _isFirstDraw = true;
  bool _hasShownFullRoute = false; // Track if we've shown the full route view
  AnimationController? _pathAnimationController;
  AnimationController? _progressAnimationController;

  static const double targetLongitude = 100.57545;
  static const double targetLatitude = 13.70374;
  static const double spaceZoom = 1.0;
  static const double targetZoom = 14.0;

  // Navigation mode camera settings
  static const double navigationZoom = 17.0; // Street-level zoom
  static const double navigationPitch = 60.0; // 3D perspective
  static const int navigationAnimationDuration =
      1800; // 1.8 seconds smooth transition

  @override
  void initState() {
    super.initState();
    // Initialize path animation controller with smooth easing
    _pathAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 4000,
      ), // 4 seconds for smooth drawing
    );

    // Initialize progress animation controller for smooth step updates
    _progressAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 1500,
      ), // 1.5 seconds for progress updates
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

    // Small delay to ensure map is fully ready
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    // Step 1: Rotation animation - globe spins to show route area
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

    // Step 2: Load route data immediately
    // The route fitting will handle the final camera position
    _loadRouteData();
  }

  /// Load route data using BLoC
  void _loadRouteData() {
    if (!mounted) return;
    try {
      context.read<RouteBloc>().add(const LoadRouteEvent());
    } catch (e) {
      // BLoC not available yet, will retry via didChangeDependencies
      debugPrint('RouteBloc not available yet: $e');
    }
  }

  /// Draw full route path with optional animation
  Future<void> _drawFullRoutePath(
    List<Waypoint> waypoints,
    bool animated,
  ) async {
    if (_layerManager == null || waypoints.isEmpty) return;

    if (animated && _isFirstDraw) {
      // Animated drawing for first time
      await _animatePathDrawing(waypoints);
      _isFirstDraw = false;
    } else {
      // Instant drawing
      await _layerManager!.addFullRoutePath(waypoints);
    }
  }

  /// Animate path drawing from start to end with smooth easing
  Future<void> _animatePathDrawing(List<Waypoint> waypoints) async {
    if (_pathAnimationController == null || _layerManager == null) return;

    // Create smooth curved animation
    final curvedAnimation = CurvedAnimation(
      parent: _pathAnimationController!,
      curve: Curves.easeInOutCubic, // Smooth acceleration and deceleration
    );

    _pathAnimationController!.reset();

    // Listen to animation progress with curved easing
    // Non-async for smoother updates without await delays
    void updatePath() {
      final progress = curvedAnimation.value;
      final pointsToShow = (waypoints.length * progress).round().clamp(
        2,
        waypoints.length,
      );
      final partialWaypoints = waypoints.sublist(0, pointsToShow);

      // Update without await for smooth continuous animation
      _layerManager!.updateFullRoutePath(partialWaypoints);
    }

    curvedAnimation.addListener(updatePath);

    // Start the animation
    await _pathAnimationController!.forward();

    // Clean up listener
    curvedAnimation.removeListener(updatePath);
    curvedAnimation.dispose();
  }

  /// Update progress path (simple, no animation)
  Future<void> _animateProgressPath(
    List<Waypoint> allWaypoints,
    List<Waypoint> newReachedWaypoints,
  ) async {
    if (_layerManager == null) return;

    // Update the progress path
    await _layerManager!.updateProgressPath(newReachedWaypoints);

    // Update marker at the end of reached waypoints
    if (newReachedWaypoints.isNotEmpty) {
      final lastWaypoint = newReachedWaypoints.last;
      await _layerManager!.updateUserMarker(
        lastWaypoint.latitude,
        lastWaypoint.longitude,
      );
    }
  }

  /// Fit camera to show all route waypoints
  /// Used when route is first drawn to show the complete path
  Future<void> _fitCameraToRoute(List<Waypoint> waypoints) async {
    if (_mapboxMap == null || !mounted || waypoints.isEmpty) return;

    // Calculate bounding box of all waypoints
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

    // Add padding to the bounds (20% on each side for better visibility)
    final latPadding = (maxLat - minLat) * 0.2;
    final lonPadding = (maxLon - minLon) * 0.2;

    // Calculate center point
    final centerLat = (minLat + maxLat) / 2;
    final centerLon = (minLon + maxLon) / 2;

    // Calculate appropriate zoom level to fit the route
    // This is a rough approximation - adjust the divisor to control tightness
    final latDelta = (maxLat - minLat) + (latPadding * 2);
    final lonDelta = (maxLon - minLon) + (lonPadding * 2);
    final maxDelta = latDelta > lonDelta ? latDelta : lonDelta;

    // Zoom level calculation: smaller delta = higher zoom
    // Reduced zoom levels to ensure full route visibility
    double zoom = 11.0; // Default zoom (zoomed out more)
    if (maxDelta < 0.01) {
      zoom = 15.0; // Very small route
    } else if (maxDelta < 0.05) {
      zoom = 13.0; // Small route
    } else if (maxDelta < 0.1) {
      zoom = 12.0; // Medium-small route
    } else if (maxDelta < 0.5) {
      zoom = 10.0; // Medium route
    } else if (maxDelta < 1.0) {
      zoom = 9.0; // Large route
    } else {
      zoom = 8.0; // Very large route
    }

    print(
      '📏 Fitting camera to route: center($centerLat, $centerLon), zoom: $zoom',
    );

    // Animate camera to show full route
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

    // Calculate bearing of the path ahead
    final bearing = BearingCalculator.calculatePathBearing(
      allWaypoints,
      currentWaypointIndex,
      currentLat,
      currentLon,
    );

    print(
      '🧭 Navigation: Position ($currentLat, $currentLon), Bearing: ${bearing.toStringAsFixed(1)}°',
    );

    // Update camera with smooth flyTo animation (like Google Maps)
    // flyTo creates a smooth arc movement instead of linear easeTo
    _mapboxMap!.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(currentLon, currentLat)),
        zoom: navigationZoom,
        bearing: bearing, // Rotate map so path points upward
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
          // Test buttons for step increment (for development)
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
          // Mapbox map widget
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

          // Route state listener and UI
          BlocConsumer<RouteBloc, RouteState>(
            listener: (context, state) async {
              if (state is RouteLoaded) {
                // On first draw: Run camera fit and path drawing in parallel
                if (!_hasShownFullRoute && state.allWaypoints.isNotEmpty) {
                  // Start both animations simultaneously for smooth experience
                  await Future.wait([
                    _fitCameraToRoute(state.allWaypoints),
                    _drawFullRoutePath(state.allWaypoints, _isFirstDraw),
                  ]);
                  _hasShownFullRoute = true;
                  if (!mounted) return;
                } else {
                  // Subsequent updates: Just update the route
                  await _drawFullRoutePath(state.allWaypoints, _isFirstDraw);
                  if (!mounted) return;
                }

                // Animate progress path smoothly (yellow line)
                if (_layerManager != null) {
                  await _animateProgressPath(
                    state.allWaypoints,
                    state.reachedWaypoints,
                  );
                  if (!mounted) return;

                  // Update landmark markers
                  await _layerManager!.updateLandmarkMarkers(
                    state.landmarks,
                    state.userSteps,
                  );
                  if (!mounted) return;

                  // User marker is already updated during path animation
                  // No need to update it again here
                }

                // Navigation mode: Follow user's current position with camera
                // Only activate when user starts interacting (step count > 0)
                if (_hasShownFullRoute &&
                    _mapboxMap != null &&
                    state.allWaypoints.isNotEmpty &&
                    state.userSteps > 0) {
                  // Only track when user has steps
                  await _updateNavigationCamera(
                    state.allWaypoints,
                    state.currentPosition.latitude,
                    state.currentPosition.longitude,
                    state.currentPosition.waypointIndex,
                  );
                  if (!mounted) return;
                }

                // Show landmark info if selected
                if (state.selectedLandmark != null && mounted) {
                  LandmarkInfoSheet.show(
                    context,
                    state.selectedLandmark!,
                    state.userSteps,
                  );
                  // Dismiss selection after showing
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
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }

              if (state is RouteError) {
                return Center(
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.white,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading route',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.message,
                          style: const TextStyle(
                            color: Colors.white,
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
