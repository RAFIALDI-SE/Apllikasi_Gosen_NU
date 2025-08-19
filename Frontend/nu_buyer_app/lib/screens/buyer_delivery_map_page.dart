import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';

class DeliveryMapPage extends StatefulWidget {
  final LatLng seller;
  final LatLng buyer;
  final LatLng driver;

  const DeliveryMapPage({
    super.key,
    required this.seller,
    required this.buyer,
    required this.driver,
  });

  @override
  State<DeliveryMapPage> createState() => _DeliveryMapPageState();
}

class _DeliveryMapPageState extends State<DeliveryMapPage> {
  List<LatLng> polylinePoints = [];
  late LatLng driverPosition;
  int _currentStep = 0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();

    polylinePoints = [
      widget.driver,
      widget.seller,
      widget.buyer,
    ];
    driverPosition = widget.driver;

    _startAnimation();
  }

  void _startAnimation() {
    const duration = Duration(milliseconds: 800);
    _timer = Timer.periodic(duration, (timer) {
      if (_currentStep < polylinePoints.length - 1) {
        final current = polylinePoints[_currentStep];
        final next = polylinePoints[_currentStep + 1];

        final latDiff = (next.latitude - current.latitude) / 20;
        final lngDiff = (next.longitude - current.longitude) / 20;

        setState(() {
          driverPosition = LatLng(
            driverPosition.latitude + latDiff,
            driverPosition.longitude + lngDiff,
          );
        });

        if ((driverPosition.latitude - next.latitude).abs() < 0.0001 &&
            (driverPosition.longitude - next.longitude).abs() < 0.0001) {
          _currentStep++;
          driverPosition = next;
        }
      } else {
        _timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Simulasi Pengiriman"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: widget.seller,
          initialZoom: 14.0,
        ),
        children: [
          TileLayer(
            urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            userAgentPackageName: 'com.example.nu_buyer_app',
          ),
          PolylineLayer(
            polylines: [
              Polyline(
                points: polylinePoints,
                color: Colors.blue,
                strokeWidth: 4.0,
              ),
            ],
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: widget.seller,
                width: 30,
                height: 30,
                child: const Icon(Icons.store, color: Colors.orange, size: 30),
              ),
              Marker(
                point: widget.buyer,
                width: 30,
                height: 30,
                child: const Icon(Icons.home, color: Colors.green, size: 30),
              ),
              Marker(
                point: driverPosition,
                width: 40,
                height: 40,
                child:
                    const Icon(Icons.motorcycle, color: Colors.red, size: 40),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
