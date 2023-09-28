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
import 'helpers/map_helper.dart';
import 'helpers/map_marker.dart';

class MarkerItem {
  int id;
  LatLng location;

  MarkerItem({required this.id, required this.location});
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

  List<Marker> googleMarkers = [];
/*   Set<Marker> markers = {};
 */
  int currentIndex = 0;
  ValueNotifier selectedMarker = ValueNotifier<int?>(0);

  /// Set of displayed markers and cluster markers on the map
  final Set<Marker> _markers = Set();

  /// Minimum zoom at which the markers will cluster
  final int _minClusterZoom = 0;

  /// Maximum zoom at which the markers will cluster
  final int _maxClusterZoom = 19;

  /// [Fluster] instance used to manage the clusters
  Fluster<MapMarker>? _clusterManager;

  /// Current map zoom. Initial zoom will be 15, street level
  double _currentZoom = 15;

  /// Map loading flag
  bool _isMapLoading = true;

  /// Markers loading flag
  bool _areMarkersLoading = true;

  /// Url image used on normal markers
  /// Url image used on normal markers
  final String _markerImageUrl = 'https://i.ibb.co/jZmy40R/marker.png';

  final String _markerImageDarkUrl =
      'https://i.ibb.co/TTnV65k/marker-darkmode.png';

  /// Color of the cluster circle
  final Color _clusterColor = Color(0xFFff5f5f);

  /// Color of the cluster text
  final Color _clusterTextColor = Colors.white;
  final List<MapMarker> markers = [];
  late List<LatLng> newMarkerPostions =
      widget.items.map((e) => e.location).toList();

  /// Example marker coordinates
  final List<LatLng> _markerLocations = [
    LatLng(36.860832, 10.253826),
    LatLng(36.837446, 10.177410),
    LatLng(36.813458, 10.133916),
    LatLng(36.80324799649396, 10.178795859199756),
    LatLng(36.84867719670467, 10.173551048840771),
    LatLng(36.83304905048471, 10.23132067865196),
    LatLng(36.85052619143521, 10.27096510507772),
    LatLng(36.453724423821065, 10.741209233267941),
    LatLng(36.44834969677488, 10.736808809719832),
    LatLng(36.419724494437965, 10.665472609479401),
  ];

  @override
  void initState() {
    _getUserLocation();

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

  /// Inits [Fluster] and all the markers with network images and updates the loading state.
  void _initMarkers() async {
    for (LatLng markerLocation in newMarkerPostions) {
      final BitmapDescriptor markerImage =
          await MapHelper.getMarkerImageFromUrl(
              Theme.of(context).brightness == Brightness.dark
                  ? _markerImageDarkUrl
                  : _markerImageUrl,
              targetWidth: 80);
      markers.add(
        MapMarker(
          onTap: () {
            int tappedIndex = newMarkerPostions.indexOf(markerLocation);
            pageController.animateToPage(
              tappedIndex,
              duration: Duration(milliseconds: 300),
              curve: Curves.bounceInOut,
            );
            _pageChanged(tappedIndex);
          },
          id: newMarkerPostions.indexOf(markerLocation).toString(),
          position: markerLocation,
          icon: markerImage,
        ),
      );
    }

    _clusterManager = (await MapHelper.initClusterManager(
      markers,
      _minClusterZoom,
      _maxClusterZoom,
    )) as Fluster<MapMarker>?;

    await _updateMarkers();
  }

  Future<void> _updateMarkers([double? updatedZoom]) async {
    if (_clusterManager == null || updatedZoom == _currentZoom) return;

    if (updatedZoom != null) {
      _currentZoom = updatedZoom;
    }

    setState(() {
      _areMarkersLoading = true;
    });

    final updatedMarkers = await MapHelper.getClusterMarkers(
      _clusterManager,
      _currentZoom,
      _clusterColor,
      _clusterTextColor,
      80,
    );

    _markers
      ..clear()
      ..addAll(updatedMarkers);

    setState(() {
      _areMarkersLoading = false;
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
                : Center(child: CircularProgressIndicator()),
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
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            padding: EdgeInsets.only(
              top: 40.0,
            ),
            onMapCreated: (GoogleMapController controller) async {
              mapController = controller;
              await mapController?.setMapStyle(
                await DefaultAssetBundle.of(context).loadString(
                  Theme.of(context).brightness != Brightness.dark
                      ? "assets/json/mapstyle_light.json"
                      : "assets/json/mapstyle_dark.json",
                ),
              );
              _initMarkers();
            },
            initialCameraPosition: CameraPosition(
              target: _initialPosition as LatLng,
              zoom: widget.zoom,
            ),
            onCameraMove: (position) => {
              _updateMarkers(position.zoom),
              if (position.zoom > 10)
                {newMarkerPostions = _markerLocations, _updateMarkers()}
            },
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
