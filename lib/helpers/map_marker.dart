import 'package:fluster/fluster.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapMarker extends Clusterable {
  final String id;
  final LatLng position;
  BitmapDescriptor? icon;
  final Function()? onTap; // Add onTap callback

  MapMarker({
    required this.id,
    required this.position,
    this.icon,
    this.onTap, // Initialize onTap property
    isCluster = false,
    clusterId,
    pointsSize,
    childMarkerId,
  }) : super(
          markerId: id,
          latitude: position.latitude,
          longitude: position.longitude,
          isCluster: isCluster,
          clusterId: clusterId,
          pointsSize: pointsSize,
          childMarkerId: childMarkerId,
        );

  Marker toMarker() {
    final marker = Marker(
      markerId: MarkerId(isCluster! ? 'cl_$id' : id),
      position: LatLng(
        position.latitude,
        position.longitude,
      ),
      icon: icon!,
      onTap: onTap, // Set the onTap callback for the Marker
    );

    return marker;
  }
}
