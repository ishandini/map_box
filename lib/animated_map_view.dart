import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class AnimatedMapView extends StatefulWidget {
  const AnimatedMapView({super.key});

  @override
  State<AnimatedMapView> createState() => _AnimatedMapViewState();
}

class _AnimatedMapViewState extends State<AnimatedMapView> {
  MapboxMap? _mapboxMap;
  bool _animationStarted = false;

  static const double targetLongitude = 172.5857475;
  static const double targetLatitude = -43.5359019;

  static const double spaceZoom = 1.0;
  static const double targetZoom = 14.0;

  void _onMapCreated(MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
  }

  void _onStyleLoaded(StyleLoadedEventData data) {
    if (!_animationStarted) {
      _animationStarted = true;
      _startAnimation();
    }
  }

  Future<void> _startAnimation() async {
    if (_mapboxMap == null) return;

    // Small delay to ensure map is fully ready
    await Future.delayed(const Duration(milliseconds: 500));

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

    _mapboxMap!.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(targetLongitude, targetLatitude)),
        zoom: targetZoom,
        bearing: 0,
        pitch: 45,
      ),
      MapAnimationOptions(duration: 8000, startDelay: 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: MapWidget(
        cameraOptions: CameraOptions(
          center: Point(coordinates: Position(0, 20)),
          zoom: spaceZoom,
          bearing: 0,
          pitch: 0,
        ),
        onMapCreated: _onMapCreated,
        onStyleLoadedListener: _onStyleLoaded,
      ),
    );
  }
}
