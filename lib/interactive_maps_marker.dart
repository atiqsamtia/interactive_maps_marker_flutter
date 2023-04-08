library interactive_maps_marker; // interactive_marker_list

import 'dart:async';
import 'dart:typed_data';

import "package:flutter/material.dart";
import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import './utils.dart';

class MarkerItem {
  int id;
  double latitude;
  double longitude;

  MarkerItem({required this.id, required this.latitude, required this.longitude});
}

class InteractiveMapsMarker extends StatefulWidget {
  final LatLng center;
  final double itemHeight;
  final double zoom;
  @required
  List<MarkerItem> items;
  @required
  final IndexedWidgetBuilder? itemContent;

  final IndexedWidgetBuilder? itemBuilder;
  final EdgeInsetsGeometry itemPadding;
  final Alignment contentAlignment;

  InteractiveMapsMarker({
    required this.items,
    this.itemBuilder,
    this.center = const LatLng(0.0, 0.0),
    this.itemContent,
    this.itemHeight = 116,
    this.zoom = 12.0,
    this.itemPadding = const EdgeInsets.only(bottom: 80.0),
    this.contentAlignment = Alignment.bottomCenter,
  }){
    if(itemBuilder == null && itemContent == null){
      throw Exception('itemBuilder or itemContent must be provided');
    }
    readIcons();
  }

  void readIcons() async {
    if (markerIcon == null) markerIcon = await getBytesFromAsset('packages/interactive_maps_marker/assets/marker.png', 100);
    if (markerIconSelected == null) markerIconSelected = await getBytesFromAsset('packages/interactive_maps_marker/assets/marker_selected.png', 100);
  }

  Uint8List? markerIcon;
  Uint8List? markerIconSelected;

  @override
  _InteractiveMapsMarkerState createState() => _InteractiveMapsMarkerState();
}

class _InteractiveMapsMarkerState extends State<InteractiveMapsMarker> {
  Completer<GoogleMapController> _controller = Completer();
  GoogleMapController? mapController;
  PageController pageController = PageController(viewportFraction: 0.9);

  Set<Marker> markers = {};
  int currentIndex = 0;
  ValueNotifier selectedMarker = ValueNotifier<int?>(null);

  @override
  void initState() {
    rebuildMarkers(currentIndex);
    super.initState();
  }

  @override
  void didChangeDependencies() {
    rebuildMarkers(currentIndex);
    super.didChangeDependencies();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _controller.complete(controller);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      initialData: 0,
      builder: (context, snapshot) {
        return Stack(
          children: <Widget>[
            _buildMap(),
            Align(
              alignment: widget.contentAlignment,
              child: Padding(
                padding: widget.itemPadding,
                child: SizedBox(
                  height: widget.itemHeight,
                  child: PageView.builder(
                    itemCount: widget.items.length,
                    controller: pageController,
                    onPageChanged: _pageChanged,
                    itemBuilder: widget.itemBuilder != null ? widget.itemBuilder! : _buildItem,
                  ),
                ),
              ),
            )
          ],
        );
      },
    );
  }

  Widget _buildMap() {
    return Positioned.fill(
      child: ValueListenableBuilder(
        valueListenable: selectedMarker,
        builder: (context, value, child) {
          return GoogleMap(
            zoomControlsEnabled: false,
            markers: value == null ? {} : markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: widget.center,
              zoom: widget.zoom,
            ),
          );
        },
      ),
    );
  }

  Widget? _buildItem(BuildContext context, int i) {
    return Transform.scale(
      scale: i == currentIndex ? 1 : 0.9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10.0),
        child: Container(
          height: widget.itemHeight,
          decoration: BoxDecoration(
            color: Color(0xffffffff),
            boxShadow: [
              BoxShadow(
                offset: Offset(0.5, 0.5),
                color: Color(0xff000000).withOpacity(0.12),
                blurRadius: 20,
              ),
            ],
          ),
          child: widget.itemContent!(context, i),
        ),
      ),
    );
  }

  void _pageChanged(int index) {
    try {
      setState(() => currentIndex = index);
      Marker marker = markers.elementAt(index);
      rebuildMarkers(index);

      mapController
          ?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: marker.position, zoom: 15),
        ),
      )
          .then((val) {
        setState(() {});
      });
    } catch (e) {
      print(e);
    }
  }

  Future<void> rebuildMarkers(int index) async {
    int current = widget.items[index].id;

    Set<Marker> _markers = Set<Marker>();

    widget.items.forEach((item) {
      _markers.add(
        Marker(
          markerId: MarkerId(item.id.toString()),
          position: LatLng(item.latitude, item.longitude),
          onTap: () {
            int tappedIndex = widget.items.indexWhere((element) => element.id == item.id);
            pageController.animateToPage(
              tappedIndex,
              duration: Duration(milliseconds: 300),
              curve: Curves.bounceInOut,
            );
            _pageChanged(tappedIndex);
          },
          icon:  BitmapDescriptor.defaultMarkerWithHue(item.id == current ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed),
          // icon: item.id == current ? BitmapDescriptor.fromBytes(widget.markerIconSelected!) : BitmapDescriptor.fromBytes(widget.markerIcon!),
        ),
      );
    });

    setState(() {
      markers = _markers;
    });
    selectedMarker.value = current;
  }
}
