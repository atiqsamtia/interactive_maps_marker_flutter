library interactive_maps_marker; // interactive_marker_list

import 'dart:async';

import 'package:fluster/fluster.dart';
import "package:flutter/material.dart";
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:interactive_maps_marker/interactive_maps_controller.dart';
export 'package:interactive_maps_marker/interactive_maps_controller.dart';

import 'helpers/map_helper.dart';
import 'helpers/map_marker.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mp;

class MarkerItem {
  int id;
  LatLng location;
  String ville;
  MarkerItem({required this.id, required this.location, required this.ville});
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
  final IndexedWidgetBuilder? restItemBuilder;
  final EdgeInsetsGeometry itemPadding;
  final Alignment contentAlignment;
  final LatLng? initialPositionFromlist;
  final String? filteredCity;
  final String? originalCity;
  final Function(dynamic) onValueReceived;

  InteractiveMapsController? controller;
  VoidCallback? onLastItem;
  final List<int?> keys;
  final List<int?> remainingKeys;
  InteractiveMapsMarker(
      {required this.items,
      Key? key,
      this.itemBuilder,
      required this.onValueReceived,
      this.restItemBuilder,
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
      required this.keys,
      required this.remainingKeys,
      this.initialPositionFromlist,
      this.filteredCity,
      this.originalCity})
      : super(key: key) {
    if (itemBuilder == null && itemContent == null) {
      throw Exception('itemBuilder or itemContent must be provided');
    }
  }
  void sendValueToParent(dynamic data) {
    onValueReceived(data);
  }

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
  bool setFromSameCity = false;
  bool markerTapped = false;
  bool showDetailsNabeul = false;
  bool showDetailsTunis = false;
  bool isNabeul = false;
  bool isTunis = false;
  String city = "";
  String previousCity = "";

  /// Url image used on normal markers
  /// Url image used on normal markers
  final String _markerImageUrl =
      'packages/interactive_maps_marker/assets/marker.png';

  final String _markerImageDarkUrl =
      'packages/interactive_maps_marker/assets/marker_darkmode.png';

  /// Color of the cluster circle
  final Color _clusterColor = Color(0xFFff5f5f);

  /// Color of the cluster text
  final Color _clusterTextColor = Colors.white;
  final List<MapMarker> markers = [];
  Map<int, int> indexMapping = {};
  Map<int, int> indexMappingRemaining = {};
  List<mp.LatLng> polygonPoints = [
    mp.LatLng(36.53, 10.33),
    mp.LatLng(36.92, 10.96),
    mp.LatLng(36.66, 11.32),
    mp.LatLng(36.34, 10.56),
  ];
  List<mp.LatLng> polygonPointsTunis = [
    mp.LatLng(36.91, 9.95),
    mp.LatLng(37.00, 10.25),
    mp.LatLng(36.84, 10.47),
    mp.LatLng(36.62, 10.18),
  ];

  late List<LatLng> newMarkerPostions = [];
  late int? originalIndex = null;
  @override
  void initState() {
    newMarkerPostions = widget.items.map((e) => e.location).toList();
    indexMapping = Map.fromIterable(widget.keys,
        key: (item) => widget.keys.indexOf(item), value: (item) => item);
    indexMappingRemaining = Map.fromIterable(widget.remainingKeys,
        key: (item) => widget.remainingKeys.indexOf(item),
        value: (item) => item);
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  int? getKeyForValue(Map<int, int> map, int targetValue) {
    for (var entry in map.entries) {
      if (entry.value == targetValue) {
        return entry.key;
      }
    }
    return null; // Return null if the value is not found.
  }

  /// Inits [Fluster] and all the markers with network images and updates the loading state.
  void _initMarkers() async {
    for (LatLng markerLocation in newMarkerPostions) {
      final BitmapDescriptor markerImage =
          await MapHelper.getMarkerImageFromAsset(
              Theme.of(context).brightness == Brightness.dark
                  ? _markerImageDarkUrl
                  : _markerImageUrl,
              targetWidth: 80);
      markers.add(
        MapMarker(
          onTap: () {
            int tappedIndex = newMarkerPostions.indexOf(markerLocation);
            originalIndex = getKeyForValue(indexMapping, tappedIndex);
            setFromSameCity = true;
            setState(() {
              markerTapped = true;
            });
            if (getKeyForValue(indexMapping, tappedIndex) == null) {
              originalIndex =
                  getKeyForValue(indexMappingRemaining, tappedIndex);
              setFromSameCity = false;
            }
            if (_currentZoom > 10) {
              pageController.animateToPage(
                originalIndex!,
                duration: Duration(milliseconds: 500),
                curve: Curves.bounceInOut,
              );
            }
            _pageChanged(tappedIndex!);
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
    if (_currentZoom <= 10) {
      markerTapped = false;
    } else
      markerTapped = true;

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

  bool isInPolygon(LatLng point, List<mp.LatLng> polygonPoints) {
    final pointMp = mp.LatLng(point.latitude, point.longitude);

    return mp.PolygonUtil.containsLocation(pointMp, polygonPoints, false);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int?>(
      stream: null,
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
                  child: markerTapped && (showDetailsNabeul || showDetailsTunis)
                      ? PageView.builder(
                          itemCount: originalIndex != null && !setFromSameCity
                              ? indexMappingRemaining.length
                              : indexMapping.length,
                          controller: pageController,
                          onPageChanged: (int pageIndex) {
                            final NeworiginalIndex =
                                originalIndex != null && !setFromSameCity
                                    ? indexMappingRemaining[pageIndex]
                                    : indexMapping[pageIndex];
                            if (NeworiginalIndex != null) {
                              _pageChanged(NeworiginalIndex);
                            }
                          },
                          itemBuilder: originalIndex != null && !setFromSameCity
                              ? widget.restItemBuilder!
                              : widget.itemBuilder!)
                      : SizedBox.shrink(),
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
              target: widget.initialPositionFromlist != null
                  ? widget.initialPositionFromlist as LatLng
                  : widget.initialPositionFromlist as LatLng,
              zoom: widget.zoom,
            ),
            onCameraMove: (position) => {
              setState(() {
                isNabeul = isInPolygon(position.target, polygonPoints);
                isTunis = isInPolygon(position.target, polygonPointsTunis);
                city = isNabeul
                    ? "Nabeul"
                    : (isTunis ? "Tunis" : "different city");

                showDetailsNabeul = isNabeul;
                showDetailsTunis = isTunis;
                if (city != previousCity) {
                  if (previousCity == "different city" && city == "Nabeul") {
                    // City changed from Tunis to Nabeul
                    print("City changed from Tunis to Nabeul");
                    setFromSameCity = true;
                    originalIndex = 1;
                  } else if (previousCity == "different city" &&
                      city == "Tunis") {
                    // City changed from Nabeul to Tunis
                    setFromSameCity = false;
                    originalIndex = 1;
                    print("City changed from Nabeul to Tunis");
                  }

                  // Update the previousCity
                  previousCity = city;
                }
              }),
              widget.sendValueToParent(city),
              _updateMarkers(position.zoom),
            },
          );
        },
      ),
    );
  }

  void _pageChanged(int index) {
    try {
      setState(() => currentIndex = index);
      if (widget.onLastItem != null && index == widget.items.length - 1) {
        widget.onLastItem!();
      }
      Marker marker = markers.elementAt(index).toMarker();
      if (_currentZoom <= 10) {
        Future.delayed(Duration(milliseconds: 500), () {
          pageController.animateToPage(
            index,
            duration: Duration(milliseconds: 500),
            curve: Curves.bounceInOut,
          );
        });
      }
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
}
