import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'interactive_maps_marker.dart';

class InteractiveMapsController {
  InteractiveMapsMarkerState? _state;

  InteractiveMapsMarkerState? get state => _state;

  void currentState(InteractiveMapsMarkerState state) {
    _state = state;
  }

  void reset({int? index}) {
    Future.delayed(Duration(milliseconds: 200)).then((value) {
      _state?.pageController.jumpToPage(index ?? _state?.currentIndex ?? 0);
      getMapController()?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
              target: _state!.widget.center, zoom: _state!.widget.zoom),
        ),
      );
    });
  }

  GoogleMapController? getMapController() {
    if (_state != null) {
      return _state?.mapController;
    }
    return null;
  }
}
