import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:interactive_maps_marker/interactive_maps_marker.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Interactive Map Marker List',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  final List<MarkerItem> markers = List()
    ..add(MarkerItem(id: 1, latitude: 36.762887, longitude: 3.062048))
    ..add(MarkerItem(id: 2, latitude: 36.792887, longitude: 3.032048))
    ..add(MarkerItem(id: 3, latitude: 36.712887, longitude: 3.142048))
    ..add(MarkerItem(id: 4, latitude: 36.952887, longitude: 3.082048));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Interactive Map Marker List'),
      ),
      body: InteractiveMapsMarker(
        items: markers,
        center: LatLng(36.737232, 3.086472),
        itemBuilder: (context, index) {
          MarkerItem item = markers[index];
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
                        Row(
                          children: <Widget>[
                            Icon(Icons.star, color: Colors.orangeAccent),
                            Icon(Icons.star, color: Colors.orangeAccent),
                            Icon(Icons.star, color: Colors.orangeAccent),
                            Icon(Icons.star_half, color: Colors.orangeAccent),
                            Icon(Icons.star_border, color: Colors.orangeAccent),
                            SizedBox(width: 3.0),
                            Text('3.5', style: TextStyle(color: Colors.orangeAccent, fontSize: 24.0, fontWeight: FontWeight.w600))
                          ],
                        ),
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
        },
      ),
    );
  }
}
