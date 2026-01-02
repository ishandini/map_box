import '../../domain/entities/waypoint.dart';

/// Data model for Waypoint with JSON serialization
/// Extends domain entity and adds fromJson/toJson capabilities
class WaypointModel extends Waypoint {
  const WaypointModel({
    required super.latitude,
    required super.longitude,
    required super.distance,
    required super.cumulativeSteps,
    required super.zoomLevel,
    required super.action,
    required super.link,
    required super.flagActive,
    required super.flagDeactive,
    required super.stepsToNext,
    required super.nextCity,
    required super.city,
    required super.cityMessage,
    required super.cityImage,
    required super.welcomeMessage,
    required super.currentCity,
  });

  /// Create WaypointModel from JSON
  factory WaypointModel.fromJson(Map<String, dynamic> json) {
    return WaypointModel(
      latitude: _parseDouble(json['lat']),
      longitude: _parseDouble(json['long']),
      distance: _parseInt(json['distance']),
      cumulativeSteps: _parseInt(json['steps']),
      zoomLevel: _parseInt(json['zooml']),
      action: _parseString(json['action']),
      link: _parseString(json['link']),
      flagActive: _parseString(json['flag_act']),
      flagDeactive: _parseString(json['flag_deact']),
      stepsToNext: _parseInt(json['stepstonext']),
      nextCity: _parseString(json['nextcity']),
      city: _parseString(json['city']),
      cityMessage: _parseString(json['citymsg']),
      cityImage: _parseString(json['cityimg']),
      welcomeMessage: _parseString(json['wc']),
      currentCity: _parseString(json['currentcity']),
    );
  }

  /// Convert WaypointModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'lat': latitude,
      'long': longitude,
      'distance': distance,
      'steps': cumulativeSteps,
      'zooml': zoomLevel,
      'action': action,
      'link': link,
      'flag_act': flagActive,
      'flag_deact': flagDeactive,
      'stepstonext': stepsToNext,
      'nextcity': nextCity,
      'city': city,
      'citymsg': cityMessage,
      'cityimg': cityImage,
      'wc': welcomeMessage,
      'currentcity': currentCity,
    };
  }

  /// Convert domain entity to model
  factory WaypointModel.fromEntity(Waypoint waypoint) {
    return WaypointModel(
      latitude: waypoint.latitude,
      longitude: waypoint.longitude,
      distance: waypoint.distance,
      cumulativeSteps: waypoint.cumulativeSteps,
      zoomLevel: waypoint.zoomLevel,
      action: waypoint.action,
      link: waypoint.link,
      flagActive: waypoint.flagActive,
      flagDeactive: waypoint.flagDeactive,
      stepsToNext: waypoint.stepsToNext,
      nextCity: waypoint.nextCity,
      city: waypoint.city,
      cityMessage: waypoint.cityMessage,
      cityImage: waypoint.cityImage,
      welcomeMessage: waypoint.welcomeMessage,
      currentCity: waypoint.currentCity,
    );
  }

  // Helper methods for safe parsing
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static String _parseString(dynamic value) {
    if (value == null) return '-';
    return value.toString();
  }
}
