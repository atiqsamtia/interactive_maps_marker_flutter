import 'package:example/simple_usage.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:interactive_maps_marker/interactive_maps_marker.dart';

class StatefulExample extends StatefulWidget {
  @override
  _StatefulExampleState createState() => _StatefulExampleState();
}

class _StatefulExampleState extends State<StatefulExample> {
  List<MarkerItem> markers = [];
  InteractiveMapsController controller = InteractiveMapsController();

  @override
  void initState() {
    super.initState();
//    Fake delay for simulating a network request
    Future.delayed(Duration(seconds: 2)).then((value) {
      setState(() {
        markers.add(MarkerItem(id: 1, latitude: 31.4673274, longitude: 74.2637687));
        markers.add(MarkerItem(id: 2, latitude: 31.4718461, longitude: 74.3531591));
        controller.reset(index: 0);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Stateful Usage'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              setState(() {
                markers.add(MarkerItem(id: 3, latitude: 31.5325107, longitude: 74.3610325));
                markers.add(MarkerItem(id: 4, latitude: 31.4668809, longitude: 74.31354));
                controller.reset(index: 0);
              });
            },
          )
        ],
      ),
      body: InteractiveMapsMarker(
        items: markers,
        controller: controller,
        center: LatLng(31.4906504, 74.319872),
        itemContent: (context, index) {
          MarkerItem item = markers[index];
          return BottomTile(item: item);
        },
        onLastItem: () {
          print('Last Item');
        },
      ),
    );
  }
}
