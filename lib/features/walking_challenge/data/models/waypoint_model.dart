import '../../domain/entities/waypoint.dart';

class WaypointModel {
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

  const WaypointModel({
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

  Waypoint toEntity() {
    return Waypoint(
      latitude: latitude,
      longitude: longitude,
      distance: distance,
      cumulativeSteps: cumulativeSteps,
      zoomLevel: zoomLevel,
      action: action,
      link: link,
      flagActive: flagActive,
      flagDeactive: flagDeactive,
      stepsToNext: stepsToNext,
      nextCity: nextCity,
      city: city,
      cityMessage: cityMessage,
      cityImage: cityImage,
      welcomeMessage: welcomeMessage,
      currentCity: currentCity,
    );
  }

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
