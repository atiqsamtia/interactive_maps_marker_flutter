import 'package:flutter/material.dart';
import 'package:interactive_maps_marker/interactive_maps_marker.dart';

class AdvancedUsage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Advanced Usage'),
      ),
      body: Center(
        child: Text('Coming Soon'),
      ),
    );
  }
}

class StoreItem implements MarkerItem {
  @override
  int id;

  @override
  double latitude;

  @override
  double longitude;

  String title;
  String subTitle;
  String image;
  String details;

  StoreItem({this.id, this.latitude, this.longitude, this.title, this.subTitle, this.details});
}
