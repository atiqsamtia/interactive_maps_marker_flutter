import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'interactive_maps_marker.dart';

class InteractiveMapsController {
  InteractiveMapsMarkerState? _state;

  void currentState(InteractiveMapsMarkerState state) {
    _state = state;
  }

  void setCurrentIndex(int index) {
    if (_state != null) {
      _state?.setIndex(index);
    }
  }

  void rebuild([int? index]) {
    _state?.setState(() {
      _state?.setIndex(index ?? _state?.currentIndex ?? 0);
    });
  }

  GoogleMapController? getMapController() {
    if (_state != null) {
      return _state?.mapController;
    }
    return null;
  }
}
