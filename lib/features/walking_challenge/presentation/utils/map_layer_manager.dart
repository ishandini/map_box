import 'dart:convert';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/waypoint.dart';
import 'path_simplifier.dart';

class MapLayerManager {
  static const String fullRouteSourceId = 'full-route-source';
  static const String fullRouteLayerId = 'full-route-layer';
  static const String progressRouteSourceId = 'progress-route-source';
  static const String progressRouteLayerId = 'progress-route-layer';
  static const String landmarksSourceId = 'landmarks-source';
  static const String landmarksLayerId = 'landmarks-layer';
  static const String userMarkerSourceId = 'user-marker-source';
  static const String userMarkerLayerId = 'user-marker-layer';
  static const String userMarkerTextLayerId = 'user-marker-text-layer';

  final MapboxMap mapboxMap;

  MapLayerManager(this.mapboxMap);

  /// Add full route path layer (light blue path)
  Future<void> addFullRoutePath(List<Waypoint> waypoints) async {
    if (waypoints.isEmpty) {
      return;
    }

    // Convert waypoints to coordinates
    final coordinates = waypoints.map((w) => w.toCoordinates()).toList();

    // Simplify path for performance
    final simplifiedCoordinates = PathSimplifier.adaptiveSimplify(
      coordinates,
      14.0,
    );

    // Create GeoJSON for the route
    final geoJson = {
      'type': 'Feature',
      'geometry': {'type': 'LineString', 'coordinates': simplifiedCoordinates},
      'properties': {},
    };

    try {
      // Add source with GeoJSON string
      await mapboxMap.style.addSource(
        GeoJsonSource(id: fullRouteSourceId, data: jsonEncode(geoJson)),
      );

      // Add layer
      await mapboxMap.style.addLayer(
        LineLayer(
          id: fullRouteLayerId,
          sourceId: fullRouteSourceId,
          lineColor: AppColors.routeOrangeInt,
          lineWidth: 6.0,
          lineOpacity: 1.0,
          lineCap: LineCap.ROUND,
          lineJoin: LineJoin.ROUND,
        ),
      );
    } catch (e) {
      // Layer might already exist, update instead
      await updateFullRoutePath(waypoints);
    }
  }

  /// Add full route path using pre-simplified coordinates (non-blocking)
  /// This version uses coordinates that were already simplified in a background isolate
  Future<void> addFullRoutePathWithCoordinates(
    List<List<double>> simplifiedCoordinates,
  ) async {
    if (simplifiedCoordinates.length < 2) {
      return;
    }

    // Create GeoJSON for the route
    final geoJson = {
      'type': 'Feature',
      'geometry': {'type': 'LineString', 'coordinates': simplifiedCoordinates},
      'properties': {},
    };

    try {
      // Add source with GeoJSON string
      await mapboxMap.style.addSource(
        GeoJsonSource(id: fullRouteSourceId, data: jsonEncode(geoJson)),
      );

      // Add layer
      await mapboxMap.style.addLayer(
        LineLayer(
          id: fullRouteLayerId,
          sourceId: fullRouteSourceId,
          lineColor: AppColors.routeOrangeInt,
          lineWidth: 6.0,
          lineOpacity: 1.0,
          lineCap: LineCap.ROUND,
          lineJoin: LineJoin.ROUND,
        ),
      );
    } catch (e) {
      // Layer might already exist, update instead
      await updateFullRoutePathWithCoordinates(simplifiedCoordinates);
    }
  }

  /// Update full route path using pre-simplified coordinates
  Future<void> updateFullRoutePathWithCoordinates(
    List<List<double>> simplifiedCoordinates,
  ) async {
    if (simplifiedCoordinates.length < 2) return;

    final geoJson = {
      'type': 'Feature',
      'geometry': {'type': 'LineString', 'coordinates': simplifiedCoordinates},
      'properties': {},
    };

    try {
      await mapboxMap.style.setStyleSourceProperty(
        fullRouteSourceId,
        'data',
        jsonEncode(geoJson),
      );
    } catch (e) {
      // Source doesn't exist, add it
      await addFullRoutePathWithCoordinates(simplifiedCoordinates);
    }
  }

  /// Update full route path
  Future<void> updateFullRoutePath(List<Waypoint> waypoints) async {
    if (waypoints.isEmpty) return;

    final coordinates = waypoints.map((w) => w.toCoordinates()).toList();
    final simplifiedCoordinates = PathSimplifier.adaptiveSimplify(
      coordinates,
      14.0,
    );

    final geoJson = {
      'type': 'Feature',
      'geometry': {'type': 'LineString', 'coordinates': simplifiedCoordinates},
      'properties': {},
    };

    try {
      await mapboxMap.style.setStyleSourceProperty(
        fullRouteSourceId,
        'data',
        jsonEncode(geoJson),
      );
    } catch (e) {
      // Source doesn't exist, add it
      await addFullRoutePath(waypoints);
    }
  }

  /// Add progress path layer (green overlay)
  Future<void> addProgressPath(List<Waypoint> reachedWaypoints) async {
    if (reachedWaypoints.isEmpty) return;

    final coordinates = reachedWaypoints.map((w) => w.toCoordinates()).toList();

    // Don't simplify progress path to avoid redraw issues during animation
    // (Simplifying subsets gives different results each time)
    final geoJson = {
      'type': 'Feature',
      'geometry': {'type': 'LineString', 'coordinates': coordinates},
      'properties': {},
    };

    try {
      // Add source
      await mapboxMap.style.addSource(
        GeoJsonSource(id: progressRouteSourceId, data: jsonEncode(geoJson)),
      );

      // Add layer (appears on top of full route)
      await mapboxMap.style.addLayer(
        LineLayer(
          id: progressRouteLayerId,
          sourceId: progressRouteSourceId,
          lineColor: AppColors.progressGreenInt,
          lineWidth: 7.0,
          lineOpacity: 1.0,
          lineCap: LineCap.ROUND,
          lineJoin: LineJoin.ROUND,
        ),
      );
    } catch (e) {
      // Layer might already exist, update instead
      await updateProgressPath(reachedWaypoints);
    }
  }

  /// Update progress path with proper alignment to full route
  /// Uses the same simplification as full route to ensure perfect alignment
  /// Returns the last coordinate of the simplified path for marker positioning
  Future<Map<String, double>?> updateProgressPathAligned(
    List<Waypoint> allWaypoints,
    List<Waypoint> reachedWaypoints,
  ) async {
    if (reachedWaypoints.isEmpty) {
      // Remove layer if no progress
      try {
        await mapboxMap.style.removeStyleLayer(progressRouteLayerId);
        await mapboxMap.style.removeStyleSource(progressRouteSourceId);
      } catch (e) {
        // Layer doesn't exist yet
      }
      return null;
    }

    // Simplify ALL waypoints the same way as full route
    final allCoordinates = allWaypoints.map((w) => w.toCoordinates()).toList();
    final allSimplified = PathSimplifier.adaptiveSimplify(allCoordinates, 14.0);

    // Find how many simplified points correspond to reached waypoints
    // by finding the simplified point closest to the last reached waypoint
    final lastReached = reachedWaypoints.last;
    final lastReachedCoord = lastReached.toCoordinates();

    // Find the index in simplified coordinates that's closest to last reached
    int closestIndex = 0;
    double minDistance = double.infinity;

    for (int i = 0; i < allSimplified.length; i++) {
      final simplified = allSimplified[i];
      final distance = _calculateDistance(
        simplified[1],
        simplified[0],
        lastReachedCoord[1],
        lastReachedCoord[0],
      );
      if (distance < minDistance) {
        minDistance = distance;
        closestIndex = i;
      }
    }

    // Take subset of simplified coordinates (at least 2 points for a line)
    final progressSimplified = allSimplified.sublist(
      0,
      (closestIndex + 1).clamp(2, allSimplified.length),
    );

    final geoJson = {
      'type': 'Feature',
      'geometry': {'type': 'LineString', 'coordinates': progressSimplified},
      'properties': {},
    };

    try {
      await mapboxMap.style.setStyleSourceProperty(
        progressRouteSourceId,
        'data',
        jsonEncode(geoJson),
      );
    } catch (e) {
      // Source doesn't exist, add it first
      await mapboxMap.style.addSource(
        GeoJsonSource(id: progressRouteSourceId, data: jsonEncode(geoJson)),
      );
      await mapboxMap.style.addLayer(
        LineLayer(
          id: progressRouteLayerId,
          sourceId: progressRouteSourceId,
          lineColor: AppColors.progressGreenInt,
          lineWidth: 7.0,
          lineOpacity: 1.0,
          lineCap: LineCap.ROUND,
          lineJoin: LineJoin.ROUND,
        ),
      );
    }

    // Return the last coordinate of the simplified path for marker positioning
    final lastCoord = progressSimplified.last;
    return {'latitude': lastCoord[1], 'longitude': lastCoord[0]};
  }

  /// Calculate simple distance between two lat/lng points (Euclidean approximation)
  double _calculateDistance(num lat1, num lon1, num lat2, num lon2) {
    final dLat = lat2.toDouble() - lat1.toDouble();
    final dLon = lon2.toDouble() - lon1.toDouble();
    return dLat * dLat + dLon * dLon; // No need for sqrt for comparison
  }

  /// Update progress path with pre-calculated simplified coordinates
  /// This version doesn't need to simplify, making it faster for animations
  Future<void> updateProgressPathWithCoordinates(
    List<List<double>> simplifiedCoordinates,
  ) async {
    if (simplifiedCoordinates.length < 2) {
      return;
    }

    final geoJson = {
      'type': 'Feature',
      'geometry': {'type': 'LineString', 'coordinates': simplifiedCoordinates},
      'properties': {},
    };

    try {
      // Try to add source (will fail if already exists)
      await mapboxMap.style.addSource(
        GeoJsonSource(id: progressRouteSourceId, data: jsonEncode(geoJson)),
      );

      // Add layer - position it above the full route but below landmarks
      await mapboxMap.style.addLayerAt(
        LineLayer(
          id: progressRouteLayerId,
          sourceId: progressRouteSourceId,
          lineColor: AppColors.progressGreenInt,
          lineWidth: 7.0,
          lineOpacity: 1.0,
          lineCap: LineCap.ROUND,
          lineJoin: LineJoin.ROUND,
        ),
        LayerPosition(above: fullRouteLayerId),
      );
    } catch (e) {
      // Source already exists, update it instead
      try {
        mapboxMap.style.setStyleSourceProperty(
          progressRouteSourceId,
          'data',
          jsonEncode(geoJson),
        );
      } catch (updateError) {
        // Failed to update
      }
    }
  }

  /// Update progress path (legacy method for backward compatibility)
  Future<void> updateProgressPath(List<Waypoint> reachedWaypoints) async {
    if (reachedWaypoints.isEmpty) {
      // Remove layer if no progress
      try {
        await mapboxMap.style.removeStyleLayer(progressRouteLayerId);
        await mapboxMap.style.removeStyleSource(progressRouteSourceId);
      } catch (e) {
        // Layer doesn't exist yet
      }
      return;
    }

    final coordinates = reachedWaypoints.map((w) => w.toCoordinates()).toList();

    // Don't simplify progress path to avoid redraw issues during animation
    // (Simplifying subsets gives different results each time)
    final geoJson = {
      'type': 'Feature',
      'geometry': {'type': 'LineString', 'coordinates': coordinates},
      'properties': {},
    };

    try {
      await mapboxMap.style.setStyleSourceProperty(
        progressRouteSourceId,
        'data',
        jsonEncode(geoJson),
      );
    } catch (e) {
      // Source doesn't exist, add it
      await addProgressPath(reachedWaypoints);
    }
  }

  /// Add landmark markers
  Future<void> addLandmarkMarkers(
    List<Waypoint> landmarks,
    int userSteps,
  ) async {
    if (landmarks.isEmpty) return;

    final features = landmarks.asMap().entries.map((entry) {
      final index = entry.key;
      final landmark = entry.value;
      final hasReached = landmark.hasReached(userSteps);

      return {
        'type': 'Feature',
        'id': index,
        'geometry': {'type': 'Point', 'coordinates': landmark.toCoordinates()},
        'properties': {
          'title': landmark.city,
          'reached': hasReached ? 1 : 0,
          'icon': hasReached ? landmark.flagActive : landmark.flagDeactive,
        },
      };
    }).toList();

    final geoJson = {'type': 'FeatureCollection', 'features': features};

    try {
      // Add source
      await mapboxMap.style.addSource(
        GeoJsonSource(id: landmarksSourceId, data: jsonEncode(geoJson)),
      );

      // Add circle layer for landmarks with bright colors
      await mapboxMap.style.addLayer(
        CircleLayer(
          id: landmarksLayerId,
          sourceId: landmarksSourceId,
          circleRadius: 10.0,
          circleColor: AppColors.landmarkMarkerInt,
          circleStrokeColor: AppColors.whiteInt,
          circleStrokeWidth: 3.0,
        ),
      );
    } catch (e) {
      // Layer might already exist, update instead
      await updateLandmarkMarkers(landmarks, userSteps);
    }
  }

  /// Update landmark markers
  Future<void> updateLandmarkMarkers(
    List<Waypoint> landmarks,
    int userSteps,
  ) async {
    if (landmarks.isEmpty) return;

    final features = landmarks.asMap().entries.map((entry) {
      final index = entry.key;
      final landmark = entry.value;
      final hasReached = landmark.hasReached(userSteps);

      return {
        'type': 'Feature',
        'id': index,
        'geometry': {'type': 'Point', 'coordinates': landmark.toCoordinates()},
        'properties': {
          'title': landmark.city,
          'reached': hasReached ? 1 : 0,
          'icon': hasReached ? landmark.flagActive : landmark.flagDeactive,
        },
      };
    }).toList();

    final geoJson = {'type': 'FeatureCollection', 'features': features};

    try {
      await mapboxMap.style.setStyleSourceProperty(
        landmarksSourceId,
        'data',
        jsonEncode(geoJson),
      );
    } catch (e) {
      // Source doesn't exist, add it
      await addLandmarkMarkers(landmarks, userSteps);
    }
  }

  /// Add or update user position marker at the end of progress path
  Future<void> updateUserMarker(double latitude, double longitude) async {
    final geoJson = {
      'type': 'Feature',
      'geometry': {
        'type': 'Point',
        'coordinates': [longitude, latitude],
      },
      'properties': {'title': 'You'},
    };

    try {
      // Try to update existing marker
      await mapboxMap.style.setStyleSourceProperty(
        userMarkerSourceId,
        'data',
        jsonEncode(geoJson),
      );
    } catch (e) {
      // Marker doesn't exist, create it
      await _addUserMarker(latitude, longitude);
    }
  }

  /// Add user marker for the first time
  Future<void> _addUserMarker(double latitude, double longitude) async {
    final geoJson = {
      'type': 'Feature',
      'geometry': {
        'type': 'Point',
        'coordinates': [longitude, latitude],
      },
      'properties': {'title': 'You'},
    };

    try {
      // Add source
      await mapboxMap.style.addSource(
        GeoJsonSource(id: userMarkerSourceId, data: jsonEncode(geoJson)),
      );

      // Add avatar circle layer (blue circle with white border)
      await mapboxMap.style.addLayer(
        CircleLayer(
          id: userMarkerLayerId,
          sourceId: userMarkerSourceId,
          circleRadius: 12.0,
          circleColor: AppColors.userMarkerInt,
          circleStrokeColor: AppColors.whiteInt,
          circleStrokeWidth: 3.0,
        ),
      );

      // Add text layer for "You" label
      await mapboxMap.style.addLayer(
        SymbolLayer(
          id: userMarkerTextLayerId,
          sourceId: userMarkerSourceId,
          textField: 'You',
          textSize: 12.0,
          textColor: AppColors.whiteInt,
          textHaloColor: AppColors.blackInt,
          textHaloWidth: 1.5,
          textOffset: [0.0, -2.0],
          textAnchor: TextAnchor.BOTTOM,
        ),
      );
    } catch (e) {
      // Error adding user marker
    }
  }

  /// Remove user marker
  Future<void> removeUserMarker() async {
    try {
      await mapboxMap.style.removeStyleLayer(userMarkerTextLayerId);
    } catch (e) {
      // Layer doesn't exist
    }

    try {
      await mapboxMap.style.removeStyleLayer(userMarkerLayerId);
    } catch (e) {
      // Layer doesn't exist
    }

    try {
      await mapboxMap.style.removeStyleSource(userMarkerSourceId);
    } catch (e) {
      // Source doesn't exist
    }
  }

  /// Remove all route layers
  Future<void> removeAllLayers() async {
    try {
      await mapboxMap.style.removeStyleLayer(progressRouteLayerId);
    } catch (e) {
      // Layer doesn't exist
    }

    try {
      await mapboxMap.style.removeStyleLayer(fullRouteLayerId);
    } catch (e) {
      // Layer doesn't exist
    }

    try {
      await mapboxMap.style.removeStyleLayer(landmarksLayerId);
    } catch (e) {
      // Layer doesn't exist
    }

    try {
      await mapboxMap.style.removeStyleSource(progressRouteSourceId);
    } catch (e) {
      // Source doesn't exist
    }

    try {
      await mapboxMap.style.removeStyleSource(fullRouteSourceId);
    } catch (e) {
      // Source doesn't exist
    }

    try {
      await mapboxMap.style.removeStyleSource(landmarksSourceId);
    } catch (e) {
      // Source doesn't exist
    }

    // Remove user marker
    await removeUserMarker();
  }
}
