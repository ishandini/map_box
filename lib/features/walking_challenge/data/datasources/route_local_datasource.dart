import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/waypoint_model.dart';

abstract class RouteLocalDataSource {
  Future<List<WaypointModel>> loadRouteWaypoints();
}

class RouteLocalDataSourceImpl implements RouteLocalDataSource {
  static const String _routeAssetPath = 'assets/jsons/bankok.json';

  @override
  Future<List<WaypointModel>> loadRouteWaypoints() async {
    try {
      final String jsonString = await rootBundle.loadString(_routeAssetPath);

      final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;

      final List<WaypointModel> waypoints = jsonList
          .map((json) => WaypointModel.fromJson(json as Map<String, dynamic>))
          .toList();

      return waypoints;
    } catch (e) {
      throw DataSourceException('Failed to load route data: ${e.toString()}');
    }
  }
}

class DataSourceException implements Exception {
  final String message;

  DataSourceException(this.message);

  @override
  String toString() => 'DataSourceException: $message';
}
