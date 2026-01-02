import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/waypoint_model.dart';

/// Abstract interface for route data source
abstract class RouteLocalDataSource {
  /// Load route waypoints from local JSON file
  Future<List<WaypointModel>> loadRouteWaypoints();
}

/// Implementation of RouteLocalDataSource using Flutter assets
class RouteLocalDataSourceImpl implements RouteLocalDataSource {
  static const String _routeAssetPath = 'assets/jsons/bankok.json';

  @override
  Future<List<WaypointModel>> loadRouteWaypoints() async {
    try {
      print('📍 Loading route from: $_routeAssetPath');

      // Load JSON file from assets
      final String jsonString = await rootBundle.loadString(_routeAssetPath);
      print('✅ JSON loaded, length: ${jsonString.length} characters');

      // Parse JSON string
      final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
      print('✅ JSON parsed, ${jsonList.length} waypoints found');

      // Convert to WaypointModel list
      final List<WaypointModel> waypoints = jsonList
          .map((json) => WaypointModel.fromJson(json as Map<String, dynamic>))
          .toList();

      print('✅ Route loaded successfully: ${waypoints.length} waypoints');
      print('📌 First waypoint: lat=${waypoints.first.latitude}, lng=${waypoints.first.longitude}');
      print('📌 Last waypoint: lat=${waypoints.last.latitude}, lng=${waypoints.last.longitude}');

      return waypoints;
    } catch (e) {
      print('❌ Failed to load route: ${e.toString()}');
      throw DataSourceException('Failed to load route data: ${e.toString()}');
    }
  }
}

/// Exception thrown when data source operations fail
class DataSourceException implements Exception {
  final String message;

  DataSourceException(this.message);

  @override
  String toString() => 'DataSourceException: $message';
}
