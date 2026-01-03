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
  bool _hasShownFullRoute = false; // Track if we've shown the full route view
  bool _hasShownFirstProgress = false; // Track if we've shown the first progress animation
  AnimationController? _pathAnimationController;
  AnimationController? _progressAnimationController;

  // Track previous progress coordinates for smooth animation
  List<List<double>>? _previousProgressCoords;

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

  /// Draw full route path (without animation)
  Future<void> _drawFullRoutePath(List<Waypoint> waypoints) async {
    if (_layerManager == null || waypoints.isEmpty) return;

    print('🔵 Starting _drawFullRoutePath with ${waypoints.length} waypoints');

    // Convert waypoints to coordinates - NO simplification
    // This ensures perfect alignment with the green progress line
    final allCoordinates = waypoints.map((w) {
      final coords = w.toCoordinates();
      return [coords[0].toDouble(), coords[1].toDouble()];
    }).toList();

    print('🔵 Drawing route path with all ${allCoordinates.length} coordinates (no simplification)');
    await _layerManager!.addFullRoutePathWithCoordinates(allCoordinates);
    print('✅ Route path drawn');
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

  /// Update progress path from reached waypoints + user position
  /// Uses all waypoints with no simplification to ensure perfect alignment with orange line
  /// Animates smoothly from previous progress to new progress
  Future<void> _animateProgressPath(
    List<Waypoint> allWaypoints,
    List<Waypoint> newReachedWaypoints,
    double userLatitude,
    double userLongitude,
  ) async {
    print('  🔍 _animateProgressPath: Starting');
    if (_layerManager == null || newReachedWaypoints.isEmpty) {
      print('  ⚠️ _animateProgressPath: Early return - missing data');
      return;
    }

    print('  🔍 Building progress path from ${newReachedWaypoints.length} waypoints + user position');

    // Build target coordinates from reached waypoints - NO simplification
    // This preserves all curves perfectly
    final targetCoordinates = <List<double>>[];
    for (final waypoint in newReachedWaypoints) {
      final coords = waypoint.toCoordinates();
      targetCoordinates.add([coords[0].toDouble(), coords[1].toDouble()]);
    }

    // Add user's exact position as the final point
    targetCoordinates.add([userLongitude, userLatitude]);

    print('  🔍 Target progress path has ${targetCoordinates.length} coordinates');

    // If this is the first draw, animate from start (2 coords) to target
    // This ensures user sees the green line grow even on first load
    if (_previousProgressCoords == null || _previousProgressCoords!.isEmpty) {
      print('  🔍 First progress draw - animating from start');
      // Start with just the first 2 coordinates
      _previousProgressCoords = targetCoordinates.sublist(0, 2.clamp(0, targetCoordinates.length));
      // Don't return - continue to animation below
    }

    // Animate from previous coordinates to new coordinates
    print('  🎬 Animating from ${_previousProgressCoords!.length} to ${targetCoordinates.length} coordinates');

    if (_progressAnimationController == null || !mounted) return;

    // Reset animation controller
    _progressAnimationController!.reset();

    // Create smooth curved animation
    final curvedAnimation = CurvedAnimation(
      parent: _progressAnimationController!,
      curve: Curves.easeInOutCubic,
    );

    // Animation listener for smooth progress growth
    void updateProgress() {
      if (!mounted || _layerManager == null) return;

      final progress = curvedAnimation.value;

      // If target is longer, interpolate the growth
      if (targetCoordinates.length >= _previousProgressCoords!.length) {
        // Calculate how many coordinates to show based on progress
        final coordsToShow = (_previousProgressCoords!.length +
          (targetCoordinates.length - _previousProgressCoords!.length) * progress)
          .round()
          .clamp(2, targetCoordinates.length);

        final animatedCoords = targetCoordinates.sublist(0, coordsToShow);

        // Update progress path without await for smooth animation
        _layerManager!.updateProgressPathWithCoordinates(animatedCoords);

        // Update marker to the end of the current animated progress
        // This makes the marker move along with the green line
        final currentEndPoint = animatedCoords.last;
        _layerManager!.updateUserMarker(
          currentEndPoint[1], // latitude
          currentEndPoint[0], // longitude
        );
      } else {
        // If shrinking (unlikely but handle it), just show target
        _layerManager!.updateProgressPathWithCoordinates(targetCoordinates);
        _layerManager!.updateUserMarker(userLatitude, userLongitude);
      }
    }

    curvedAnimation.addListener(updateProgress);

    // Start animation
    await _progressAnimationController!.forward();

    // Clean up
    curvedAnimation.removeListener(updateProgress);
    curvedAnimation.dispose();

    // Store current coordinates as previous for next animation
    _previousProgressCoords = targetCoordinates;
    print('  ✅ Progress animation complete (marker moved with animation)');
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
                print('🟢 RouteLoaded state received');

                // On first draw: Fit camera first, then animate route drawing
                if (!_hasShownFullRoute && state.allWaypoints.isNotEmpty) {
                  print('🔵 First route draw - fitting camera first');

                  // Step 1: Fit camera to show full route (wait for completion)
                  await _fitCameraToRoute(state.allWaypoints);
                  if (!mounted) return;
                  print('✅ Camera fit complete');

                  // Step 2: Animate the route drawing from start to end (4 seconds)
                  print('🔵 Starting animated route drawing...');
                  await _animatePathDrawing(state.allWaypoints);
                  _hasShownFullRoute = true;
                  print('✅ Route drawing animation complete');
                  if (!mounted) return;
                } else {
                  print('🔵 Subsequent update - just drawing path');
                  // Subsequent updates: Just update the route without animation
                  await _drawFullRoutePath(state.allWaypoints);
                  if (!mounted) return;
                }

                // Update landmark markers first
                print('🔵 Updating ${state.landmarks.length} landmark markers...');
                await _layerManager!.updateLandmarkMarkers(
                  state.landmarks,
                  state.userSteps,
                );
                print('✅ Landmark markers updated');
                if (!mounted) return;

                // Handle progress path animation and camera movement
                if (state.userSteps > 0 && _layerManager != null) {
                  // First time: Show progress animation first, then move camera
                  // This lets user see the green line grow on the route overview
                  if (!_hasShownFirstProgress && _hasShownFullRoute) {
                    print('🔵 First progress animation - sequential (animation then camera)...');

                    // Step 1: Animate progress path while camera stays at route overview
                    await _animateProgressPath(
                      state.allWaypoints,
                      state.reachedWaypoints,
                      state.currentPosition.latitude,
                      state.currentPosition.longitude,
                    );
                    print('✅ Progress animation complete');
                    if (!mounted) return;

                    // Step 2: Move camera to user position
                    if (_mapboxMap != null && state.allWaypoints.isNotEmpty) {
                      await _updateNavigationCamera(
                        state.allWaypoints,
                        state.currentPosition.latitude,
                        state.currentPosition.longitude,
                        state.currentPosition.waypointIndex,
                      );
                      print('✅ Camera moved to user position');
                      if (!mounted) return;
                    }

                    _hasShownFirstProgress = true;
                  } else {
                    // Subsequent times: Run animations in parallel for smooth synchronized experience
                    print('🔵 Starting synchronized progress animation and camera movement...');

                    // Build list of futures to run in parallel
                    final futures = <Future<void>>[];

                    // Always animate progress path
                    futures.add(
                      _animateProgressPath(
                        state.allWaypoints,
                        state.reachedWaypoints,
                        state.currentPosition.latitude,
                        state.currentPosition.longitude,
                      ),
                    );

                    // Add camera navigation if route has been shown
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

                    // Run animations in parallel
                    await Future.wait(futures);
                    print('✅ Progress animation and camera movement complete');
                    if (!mounted) return;
                  }
                } else if (state.userSteps == 0) {
                  print('⚠️ Skipping progress animation (user has 0 steps)');
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
