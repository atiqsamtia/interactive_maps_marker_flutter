import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:interactive_maps_marker/interactive_maps_marker.dart';

class SimpleUsage extends StatelessWidget {
  final List<MarkerItem> markers = List()
    ..add(MarkerItem(id: 1, latitude: 31.4673274, longitude: 74.2637687))
    ..add(MarkerItem(id: 2, latitude: 31.4718461, longitude: 74.3531591))
    ..add(MarkerItem(id: 3, latitude: 31.5325107, longitude: 74.3610325))
    ..add(MarkerItem(id: 4, latitude: 31.4668809, longitude: 74.31354));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Simple Usage'),
      ),
      body: InteractiveMapsMarker(
        items: markers,
        center: LatLng(31.4906504, 74.319872),
        itemContent: (context, index) {
          MarkerItem item = markers[index];
          return BottomTile(item: item);
        },
      ),
    );
  }
}

class BottomTile extends StatelessWidget {
  const BottomTile({@required this.item});

  final MarkerItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Row(
        children: <Widget>[
          Container(width: 120.0, color: Colors.red),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text("Store Name", style: Theme.of(context).textTheme.headline5),
                  Text("${item.latitude} , ${item.longitude}", style: Theme.of(context).textTheme.caption),
                  stars(),
                  Expanded(
                    child: Text('Cras et ante metus. Vivamus dignissim augue sit amet nisi volutpat, vitae tincidunt lacus accumsan. '),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Row stars() {
    return Row(
      children: <Widget>[
        Icon(Icons.star, color: Colors.orangeAccent),
        Icon(Icons.star, color: Colors.orangeAccent),
        Icon(Icons.star, color: Colors.orangeAccent),
        Icon(Icons.star_half, color: Colors.orangeAccent),
        Icon(Icons.star_border, color: Colors.orangeAccent),
        SizedBox(width: 3.0),
        Text('3.5', style: TextStyle(color: Colors.orangeAccent, fontSize: 24.0, fontWeight: FontWeight.w600))
      ],
    );
  }
}
