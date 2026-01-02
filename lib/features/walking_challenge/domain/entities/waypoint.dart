import 'package:equatable/equatable.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

/// Domain entity representing a waypoint in the walking route
/// This is the core business object that is independent of data sources
class Waypoint extends Equatable {
  final double latitude;
  final double longitude;
  final int distance;
  final int cumulativeSteps;
  final int zoomLevel;
  final String action;
  final String link;
  final String flagActive;
  final String flagDeactive;
  final int stepsToNext;
  final String nextCity;
  final String city;
  final String cityMessage;
  final String cityImage;
  final String welcomeMessage;
  final String currentCity;

  const Waypoint({
    required this.latitude,
    required this.longitude,
    required this.distance,
    required this.cumulativeSteps,
    required this.zoomLevel,
    required this.action,
    required this.link,
    required this.flagActive,
    required this.flagDeactive,
    required this.stepsToNext,
    required this.nextCity,
    required this.city,
    required this.cityMessage,
    required this.cityImage,
    required this.welcomeMessage,
    required this.currentCity,
  });

  /// Check if this waypoint is a landmark (has city information)
  /// Shows all waypoints that have a city name (not just native_post)
  bool get isLandmark => city != '-' && city.isNotEmpty;

  /// Check if user has reached this waypoint
  bool hasReached(int userSteps) => userSteps >= cumulativeSteps;

  /// Convert to Mapbox Point
  Point toPoint() => Point(
        coordinates: Position(longitude, latitude),
      );

  /// Get position as [longitude, latitude] array for GeoJSON
  List<double> toCoordinates() => [longitude, latitude];

  @override
  List<Object?> get props => [
        latitude,
        longitude,
        distance,
        cumulativeSteps,
        zoomLevel,
        action,
        link,
        flagActive,
        flagDeactive,
        stepsToNext,
        nextCity,
        city,
        cityMessage,
        cityImage,
        welcomeMessage,
        currentCity,
      ];
}
