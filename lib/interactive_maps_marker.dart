library interactive_maps_marker; // interactive_marker_list

import 'dart:async';
import 'dart:ui' as ui;

import 'package:fluster/fluster.dart';
import "package:flutter/material.dart";
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:interactive_maps_marker/interactive_maps_controller.dart';
export 'package:interactive_maps_marker/interactive_maps_controller.dart';
import 'package:geolocator/geolocator.dart';

import './utils.dart';

class MapMarker extends Clusterable {
  final String id;
  final LatLng position;
  final BitmapDescriptor icon;
  MapMarker({
    required this.id,
    required this.position,
    required this.icon,
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
  Marker toMarker() => Marker(
        markerId: MarkerId(id),
        position: LatLng(
          position.latitude,
          position.longitude,
        ),
        icon: icon,
      );
}

class MarkerItem {
  int id;
  double latitude;
  double longitude;

  MarkerItem(
      {required this.id, required this.latitude, required this.longitude});
}

class InteractiveMapsMarker extends StatefulWidget {
  final LatLng center;
  final double itemHeight;
  final double zoom;
  final double zoomFocus;
  final bool zoomKeepOnTap;
  @required
  List<MarkerItem> items;
  @required
  final IndexedWidgetBuilder? itemContent;

  final IndexedWidgetBuilder? itemBuilder;
  final EdgeInsetsGeometry itemPadding;
  final Alignment contentAlignment;

  InteractiveMapsController? controller;
  VoidCallback? onLastItem;

  InteractiveMapsMarker({
    required this.items,
    this.itemBuilder,
    this.center = const LatLng(0.0, 0.0),
    this.itemContent,
    this.itemHeight = 116,
    this.zoom = 12.0,
    this.zoomFocus = 15.0,
    this.zoomKeepOnTap = false,
    this.itemPadding = const EdgeInsets.only(bottom: 80.0),
    this.contentAlignment = Alignment.bottomCenter,
    this.controller,
    this.onLastItem,
  }) {
    if (itemBuilder == null && itemContent == null) {
      throw Exception('itemBuilder or itemContent must be provided');
    }
/*     readIcons();
 */
  }

  /* void readIcons() async {
    if (markerIcon == null)
      markerIcon = await getBytesFromAsset(
          'packages/interactive_maps_marker/assets/marker.png', 100);
    if (markerIconSelected == null)
      markerIconSelected = await getBytesFromAsset(
          'packages/interactive_maps_marker/assets/marker_selected.png', 100);
  } */

  Uint8List? markerIcon;
  Uint8List? markerIconSelected;
  Uint8List? markerIconDark;
  Uint8List? markerIconSelectedDark;

  @override
  InteractiveMapsMarkerState createState() {
    var state = InteractiveMapsMarkerState();
    if (controller != null) {
      controller!.currentState(state);
    }
    return state;
  }
}

class InteractiveMapsMarkerState extends State<InteractiveMapsMarker> {
  Completer<GoogleMapController> _controller = Completer();
  GoogleMapController? mapController;
  PageController pageController = PageController(viewportFraction: 0.9);
  LatLng? _initialPosition;
   final List<MapMarker> markers = [];
  final List<LatLng> markerLocations = [
    LatLng(41.147125, -8.611249),
    LatLng(41.145599, -8.610691),
  ];
  late List<Marker> googleMarkers;
/*   Set<Marker> markers = {};
 */
  int currentIndex = 0;
  ValueNotifier selectedMarker = ValueNotifier<int?>(0);

  @override
  void initState() {
    _getUserLocation();
    for (LatLng markerLocation in markerLocations) {
      markers.add(
        MapMarker(
          id: markerLocations.indexOf(markerLocation).toString(),
          position: markerLocation,
          icon: BitmapDescriptor.hueGreen as BitmapDescriptor,
        ),
      );
    }
    final Fluster<MapMarker> fluster = Fluster<MapMarker>(
      minZoom: 7, // The min zoom at clusters will show
      maxZoom: 15, // The max zoom at clusters will show
      radius: 150, // Cluster radius in pixels
      extent: 2048, // Tile extent. Radius is calculated with it.
      nodeSize: 64, // Size of the KD-tree leaf node.
      points: markers, // The list of markers created before
      createCluster: (
        // Create cluster marker
        BaseCluster cluster,
        double lng,
        double lat,
      ) =>
          MapMarker(
        id: cluster.id.toString(),
        position: LatLng(lat, lng),
        icon: BitmapDescriptor.hueRed as BitmapDescriptor,
        isCluster: cluster.isCluster,
        clusterId: cluster.id,
        pointsSize: cluster.pointsSize,
        childMarkerId: cluster.childMarkerId,
      ),
    );
    final List<Marker> googleMarkers = fluster
      .clusters([-180, -85, 180, 85], 10)
      .map((cluster) => cluster.toMarker())
      .toList();
    rebuildMarkers(currentIndex);
    super.initState();
  }

  @override
  void didChangeDependencies() {
    rebuildMarkers(currentIndex);
    super.didChangeDependencies();
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location services are disabled. Please enable the services')));
      return false;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')));
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location permissions are permanently denied, we cannot request permissions.')));
      return false;
    }
    return true;
  }

  void _getUserLocation() async {
    final hasPermission = await _handleLocationPermission();

    if (!hasPermission) return;
    var position = await GeolocatorPlatform.instance.getCurrentPosition(
        locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation));

    setState(() {
      _initialPosition = LatLng(position.latitude, position.longitude);
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int?>(
      stream: null,
      initialData: 0,
      builder: (context, snapshot) {
        return Stack(
          children: <Widget>[
            _initialPosition != null
                ? _buildMap()
                : Container(
                    child: Center(
                      child: Text(
                        'loading map..',
                        style: TextStyle(
                            fontFamily: 'Avenir-Medium',
                            color: Colors.grey[400]),
                      ),
                    ),
                  ),
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
                    itemBuilder: widget.itemBuilder != null
                        ? widget.itemBuilder!
                        : _buildItem,
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
          print('Values changed');
          return GoogleMap(
            zoomControlsEnabled: false,
            markers:  googleMarkers.toSet(),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            onMapCreated: (GoogleMapController controller) async {
              mapController = controller;
              await mapController?.setMapStyle(
                await DefaultAssetBundle.of(context).loadString(
                  Theme.of(context).brightness != Brightness.dark
                      ? "assets/json/mapstyle_light.json"
                      : "assets/json/mapstyle_dark.json",
                ),
              );
            },
            initialCameraPosition: CameraPosition(
              target: _initialPosition as LatLng,
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
      if (widget.onLastItem != null && index == widget.items.length - 1) {
        widget.onLastItem!();
      }
      rebuildMarkers(index);
      Marker marker = markers.elementAt(index).toMarker();

      mapController
          ?.animateCamera(
        widget.zoomKeepOnTap
            ? CameraUpdate.newLatLng(
                LatLng(marker.position.latitude, marker.position.longitude),
              )
            : CameraUpdate.newCameraPosition(
                CameraPosition(target: marker.position, zoom: widget.zoomFocus),
              ),
      )
          .then((val) {
        setState(() {});
      });
    } catch (e) {
      print(e);
    }
  }

  /*  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  } */

  Future<void> rebuildMarkers(int index) async {
    if (widget.items.length == 0) return;
    int current = widget.items[index].id;

    Set<Marker> _markers = Set<Marker>();
    if (widget.markerIcon == null)
      widget.markerIcon = await getBytesFromAsset(
          'packages/interactive_maps_marker/assets/marker.png', 100);
    if (widget.markerIconSelected == null)
      widget.markerIconSelected = await getBytesFromAsset(
          'packages/interactive_maps_marker/assets/marker_selected.png', 100);
    if (widget.markerIconDark == null)
      widget.markerIconDark = await getBytesFromAsset(
          'packages/interactive_maps_marker/assets/marker_darkmode.png', 100);
    if (widget.markerIconSelectedDark == null)
      widget.markerIconSelectedDark = await getBytesFromAsset(
          'packages/interactive_maps_marker/assets/selectedMarker_darkmode.png',
          100);
/*     widget.items.forEach((item) async {
      _markers.add(
        Marker(
          markerId: MarkerId(item.id.toString()),
          position: LatLng(item.latitude, item.longitude),
          onTap: () {
            int tappedIndex =
                widget.items.indexWhere((element) => element.id == item.id);
            pageController.animateToPage(
              tappedIndex,
              duration: Duration(milliseconds: 300),
              curve: Curves.bounceInOut,
            );
            _pageChanged(tappedIndex);
          },
          /* icon: BitmapDescriptor.defaultMarkerWithHue(item.id == current
              ? BitmapDescriptor.hueGreen
              : BitmapDescriptor.hueRed),
          // */
          icon: item.id == current
              ? BitmapDescriptor.fromBytes(
                  Theme.of(context).brightness != Brightness.dark
                      ? widget.markerIconSelected as Uint8List
                      : widget.markerIconSelectedDark as Uint8List)
              : BitmapDescriptor.fromBytes(
                  Theme.of(context).brightness != Brightness.dark
                      ? widget.markerIcon as Uint8List
                      : widget.markerIconDark as Uint8List),
        ),
      );
    });

    setState(() {
      markers = _markers;
    }); */
    // selectedMarker.value = current;
    selectedMarker.value = current;
    // selectedMarker.notifyListeners();
  }

  void setIndex(int index) {
    pageController.animateToPage(
      index,
      duration: Duration(milliseconds: 300),
      curve: Curves.bounceInOut,
    );
    _pageChanged(index);
  }
}
