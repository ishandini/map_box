import 'dart:convert';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../domain/entities/waypoint.dart';
import 'path_simplifier.dart';

/// Manager class for handling Mapbox layers and sources
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
      print('⚠️ No waypoints to draw');
      return;
    }

    print('🗺️ Drawing full route path with ${waypoints.length} waypoints');

    // Convert waypoints to coordinates
    final coordinates = waypoints.map((w) => w.toCoordinates()).toList();
    print('📍 Converted to ${coordinates.length} coordinates');

    // Simplify path for performance
    final simplifiedCoordinates = PathSimplifier.adaptiveSimplify(
      coordinates,
      14.0,
    );
    print('✂️ Simplified to ${simplifiedCoordinates.length} coordinates');

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
      print('✅ Added source: $fullRouteSourceId');

      // Add layer
      await mapboxMap.style.addLayer(
        LineLayer(
          id: fullRouteLayerId,
          sourceId: fullRouteSourceId,
          lineColor: 0xFFFFA726, // Bright orange color - very visible!
          lineWidth: 6.0,
          lineOpacity: 1.0, // Full opacity for better visibility
          lineCap: LineCap.ROUND, // Rounded line ends
          lineJoin: LineJoin.ROUND, // Rounded corners
        ),
      );
      print('✅ Added layer: $fullRouteLayerId (bright orange, 6px width)');
    } catch (e) {
      print('⚠️ Layer exists, updating instead: $e');
      // Layer might already exist, update instead
      await updateFullRoutePath(waypoints);
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
          lineColor: 0xFF19b30b,
          lineWidth: 7.0, // Thicker for better visibility
          lineOpacity: 1.0,
          lineCap: LineCap.ROUND, // Rounded line ends
          lineJoin: LineJoin.ROUND, // Rounded corners
        ),
      );
      print(
        '✅ Added progress layer: $progressRouteLayerId (bright yellow, 7px width)',
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
        simplified[1], simplified[0],
        lastReachedCoord[1], lastReachedCoord[0],
      );
      if (distance < minDistance) {
        minDistance = distance;
        closestIndex = i;
      }
    }

    // Take subset of simplified coordinates (at least 2 points for a line)
    final progressSimplified = allSimplified.sublist(0, (closestIndex + 1).clamp(2, allSimplified.length));

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
          lineColor: 0xFF19b30b,
          lineWidth: 7.0,
          lineOpacity: 1.0,
          lineCap: LineCap.ROUND,
          lineJoin: LineJoin.ROUND,
        ),
      );
    }

    // Return the last coordinate of the simplified path for marker positioning
    final lastCoord = progressSimplified.last;
    return {
      'latitude': lastCoord[1] as double,
      'longitude': lastCoord[0] as double,
    };
  }

  /// Calculate simple distance between two lat/lng points (Euclidean approximation)
  double _calculateDistance(num lat1, num lon1, num lat2, num lon2) {
    final dLat = lat2.toDouble() - lat1.toDouble();
    final dLon = lon2.toDouble() - lon1.toDouble();
    return dLat * dLat + dLon * dLon; // No need for sqrt for comparison
  }

  /// Get simplified coordinates for a list of coordinates
  /// Used for pre-calculation before animation
  Future<List<List<double>>> getSimplifiedCoordinates(List<List<num>> coordinates) async {
    // Convert List<List<num>> to List<List<double>>
    final doubleCoordinates = coordinates.map((coord) =>
      coord.map((value) => value.toDouble()).toList()
    ).toList();

    return PathSimplifier.adaptiveSimplify(doubleCoordinates, 14.0);
  }

  /// Update progress path with pre-calculated simplified coordinates
  /// This version doesn't need to simplify, making it faster for animations
  void updateProgressPathWithCoordinates(List<List<double>> simplifiedCoordinates) {
    if (simplifiedCoordinates.length < 2) return;

    final geoJson = {
      'type': 'Feature',
      'geometry': {'type': 'LineString', 'coordinates': simplifiedCoordinates},
      'properties': {},
    };

    try {
      mapboxMap.style.setStyleSourceProperty(
        progressRouteSourceId,
        'data',
        jsonEncode(geoJson),
      );
    } catch (e) {
      // Source doesn't exist, add it first
      mapboxMap.style.addSource(
        GeoJsonSource(id: progressRouteSourceId, data: jsonEncode(geoJson)),
      );
      mapboxMap.style.addLayer(
        LineLayer(
          id: progressRouteLayerId,
          sourceId: progressRouteSourceId,
          lineColor: 0xFF19b30b,
          lineWidth: 7.0,
          lineOpacity: 1.0,
          lineCap: LineCap.ROUND,
          lineJoin: LineJoin.ROUND,
        ),
      );
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
          circleRadius: 10.0, // Larger for better visibility
          circleColor: 0xFFFF5722, // Bright red-orange - very visible!
          circleStrokeColor: 0xFFFFFFFF, // White stroke
          circleStrokeWidth: 3.0, // Thicker stroke
        ),
      );
      print(
        '✅ Added landmarks layer: $landmarksLayerId (bright red-orange, 10px radius)',
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
      'properties': {
        'title': 'You',
      },
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
      'properties': {
        'title': 'You',
      },
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
          circleColor: 0xFF2196F3, // Blue color for user
          circleStrokeColor: 0xFFFFFFFF, // White border
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
          textColor: 0xFFFFFFFF, // White text
          textHaloColor: 0xFF000000, // Black halo for readability
          textHaloWidth: 1.5,
          textOffset: [0.0, -2.0], // Offset text above the marker
          textAnchor: TextAnchor.BOTTOM,
        ),
      );

      print('✅ Added user marker at ($latitude, $longitude)');
    } catch (e) {
      print('⚠️ Error adding user marker: $e');
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
