import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:lakbayan/pages/edit_itinerary_page.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lakbayan/pages/profile_page.dart';
import 'package:google_maps_webservice/directions.dart' as gmaps;
import 'package:flutter_polyline_points/flutter_polyline_points.dart'; 



final directions = gmaps.GoogleMapsDirections(apiKey: "AIzaSyDMxSHLjuBE_QPy6OoJ1EPqpDsBCJ32Rr0");
const BASE_URL = "https://maps.googleapis.com/maps/api/place/nearbysearch/json";
const API_KEY = "AIzaSyDMxSHLjuBE_QPy6OoJ1EPqpDsBCJ32Rr0";

class Location {
  final String name;
  final String category;
  final double latitude; // Add latitude field
  final double longitude; // Add longitude field
  
  Location({
    required this.name,
    required this.category,
    required this.latitude, // Initialize latitude
    required this.longitude, // Initialize longitude
  });
}


class ItinerariesPage extends StatefulWidget {
  @override
  _ItinerariesPageState createState() => _ItinerariesPageState();
}

class _ItinerariesPageState extends State<ItinerariesPage> {
  List<Map<String, dynamic>> _localItineraries = [];
   final List<Color> colorsSequence = [Colors.blue, Colors.green, Colors.red];
   bool _enableGyroscope = false;


  Future<List<Location>> fetchNearbyLocations(String category) async {
  List<Location> locations = [];
  try {
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    final response = await http.get(Uri.parse('$BASE_URL?location=${position.latitude},${position.longitude}&radius=5000&type=$category&key=$API_KEY'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final results = data['results'] as List<dynamic>;
      for (var result in results) {
        final name = result['name'] ?? '';
        final latitude = result['geometry']['location']['lat'];
        final longitude = result['geometry']['location']['lng'];
        locations.add(Location(name: name, category: category, latitude: latitude, longitude: longitude));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load locations')));
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('An error occurred. Please check your location permissions.')));
  }
  return locations;
}


  Stream<QuerySnapshot> _getItinerariesByStatus(String status) {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      String uid = currentUser.uid;
      return FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('itineraries')
          .where('status', isEqualTo: status)
          .snapshots();
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('User not logged in')));
      return Stream<QuerySnapshot>.empty();
    }
  }

  

  void _showEditDialog(Map<String, dynamic> itinerary, String status) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Itinerary'),
          content: Text('Do you want to edit this itinerary?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                // Navigate to the EditItineraryPage if the user confirms
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        EditItineraryPage(itinerary: itinerary),
                  ),
                );
              },
              child: Text('Edit'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteItinerary(Map<String, dynamic> itinerary) async {
    DocumentReference docRef = itinerary['docRef'] as DocumentReference;
    await docRef.delete();
    Navigator.of(context).pop(); // Close the delete confirmation dialog

    // Navigate back to the ItinerariesPage
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => ItinerariesPage()),
      (Route<dynamic> route) => false,
    );
  }

  Future<void> _unmarkAsDone(Map<String, dynamic> itinerary) async {
    DocumentReference docRef = itinerary['docRef'] as DocumentReference;
    await docRef.update({'status': 'Ongoing'});
    Navigator.of(context).pop();
  }

Future<List<Polyline>> _calculateRoute(List<LatLng> polylineCoordinates) async {
  List<Polyline> polylines = [];
  // Define the sequence of colors
  List<Color> colorsSequence = [Colors.blue, Colors.green, Colors.red];

  for (int i = 0; i < polylineCoordinates.length - 1; i++) {
    LatLng from = polylineCoordinates[i];
    LatLng to = polylineCoordinates[i + 1];

    gmaps.DirectionsResponse response = await directions.directions(
      gmaps.Location(lat: from.latitude, lng: from.longitude),
      gmaps.Location(lat: to.latitude, lng: to.longitude),
      travelMode: gmaps.TravelMode.driving,
    );

    if (response.status == 'OK') {
      PolylinePoints polylinePoints = PolylinePoints();
      var points = polylinePoints.decodePolyline(response.routes[0].overviewPolyline.points);
      List<LatLng> segmentPoints = points.map((point) => LatLng(point.latitude, point.longitude)).toList();

      // Assign the polyline color based on the current index
      Color polylineColor = colorsSequence[i % colorsSequence.length];

      Polyline polyline = Polyline(
        polylineId: PolylineId('route_$i'),
        color: polylineColor,
        points: segmentPoints,
        width: 5,
      );

      polylines.add(polyline);
    }
  }
  return polylines;
}

double getHueFromColor(Color color) {
  HSLColor hslColor = HSLColor.fromColor(color);
  return hslColor.hue;
}


Set<Marker> _generateMarkers(List<LatLng> coordinates, List<Color> colors) {
  Set<Marker> markers = {};

  for (int i = 0; i < coordinates.length; i++) {
    final coordinate = coordinates[i];

    markers.add(
      Marker(
        markerId: MarkerId('location_$i'),
        position: coordinate,
        icon: BitmapDescriptor.defaultMarkerWithHue(getHueFromColor(colors[i])),
      ),
    );
  }

  return markers;
}




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Itineraries'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            // Navigate back to ProfilePage
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => ProfilePage()),
            );
          },
        ),
      ),
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: <Widget>[
            Container(
              constraints: BoxConstraints(maxHeight: 150.0),
              child: Material(
                color: Colors.pink,
                child: TabBar(
                  indicatorColor: Colors.blue,
                  tabs: [
                    Tab(icon: Icon(Icons.directions_car), text: "Upcoming"),
                    Tab(icon: Icon(Icons.directions_transit), text: "Ongoing"),
                    Tab(icon: Icon(Icons.directions_bike), text: "Done"),
                  ],
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildItinerariesList("Upcoming"),
                  _buildItinerariesList("Ongoing"),
                  _buildItinerariesList("Done"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


Widget _buildItinerariesList(String status) {
  Set<String> _gyroscopeEnabledItineraries = {};
  return FutureBuilder<Position>(
    future: fetchUserLocation(),
    builder: (BuildContext context, AsyncSnapshot<Position> positionSnapshot) {
      if (positionSnapshot.connectionState == ConnectionState.waiting) {
        return CircularProgressIndicator(); // Loading indicator while fetching user's location
      }

      if (positionSnapshot.hasError) {
        return Text('Failed to get user location'); // Handle errors
      }

      final userPosition = positionSnapshot.data;
 return StreamBuilder<QuerySnapshot>(
  stream: _getItinerariesByStatus(status),
  builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
    if (snapshot.hasError) {
      return Text('Something went wrong');
    }
    if (snapshot.connectionState == ConnectionState.waiting) {
      return CircularProgressIndicator();
    }
    if (snapshot.data == null) {
      return Text('No data found');
    }

    final itineraries = snapshot.data!.docs.map<Map<String, dynamic>>((doc) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      return {'docRef': doc.reference, ...data};
    }).toList();

      return ListView.builder(
        itemCount: itineraries.length,
        itemBuilder: (context, index) {
          final itinerary = itineraries[index];
          List<Widget> maps = [];

          if (itinerary['days'] != null) {
            List<Map<String, dynamic>> days = List<Map<String, dynamic>>.from(itinerary['days']);
            for (var day in days) {
              List<LatLng> polylineCoordinates = [];
              if (day['locations'] != null) {
                for (var location in day['locations']) {
                  if (location['latitude'] != null && location['longitude'] != null) {
                    LatLng latLng = LatLng(location['latitude'] as double, location['longitude'] as double);
                    polylineCoordinates.add(latLng);
                  }
                }
              }
               if (userPosition != null && polylineCoordinates.isNotEmpty) {
              LatLng userLatLng = LatLng(userPosition.latitude, userPosition.longitude);
              polylineCoordinates.insert(0, userLatLng);
              
              maps.add(FutureBuilder(
  future: _calculateRoute(polylineCoordinates),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return CircularProgressIndicator();
    } else if (snapshot.hasError) {
      return Text('Error calculating route');
    } else {
      List<Polyline> polylines = snapshot.data as List<Polyline>;

      return Padding(
  padding: EdgeInsets.symmetric(horizontal: 16.0), // Add horizontal padding
  child: Container(
    height: 400,
    width: double.infinity,
    margin: EdgeInsets.only(bottom: 16.0),  // Add space below the map
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(15.0),
      boxShadow: [
        BoxShadow(
          color: Colors.pink.withOpacity(0.3),
          spreadRadius: 5,
          blurRadius: 7,
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(15.0), // Round the edges
      child: GoogleMap(
  initialCameraPosition: CameraPosition(
    target: polylineCoordinates.first,
    zoom: 18.0,
  ),
  polylines: Set.from(polylines),
  myLocationEnabled: true,
  markers: _generateMarkers(polylineCoordinates.sublist(1), colorsSequence), // exclude user loc
  gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>[
    Factory<OneSequenceGestureRecognizer>(
      () => EagerGestureRecognizer(),
    ),
  ].toSet(),
),


    ),
  ),
);
    }
  },
));
                    }
                  }
                }


          return Container(
            margin: EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 5,
                  blurRadius: 7,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: InkWell(
              onTap: () {
                _showEditDialog(itinerary, status);
              },
            child: ExpansionTile(
                  title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        itinerary['itineraryName'] ?? 'Unknown',
                        style: TextStyle(fontSize: 30),
                      ),
                    ),
                     Text("Share"),
                    Switch(
                      value: itinerary['shareStatus'] ?? false, // default to private if shareStatus is null
                      onChanged: (value) {
                        DocumentReference docRef =
                            itinerary['docRef'] as DocumentReference;
                        docRef.update({'shareStatus': value});
                      },
                    ),
                     Text("Active"),
                      Switch(
  value: status == "Ongoing",
  onChanged: (value) {
    String updatedStatus = value ? "Ongoing" : "Upcoming";
    DocumentReference docRef =
        itinerary['docRef'] as DocumentReference;
    docRef.update({'status': updatedStatus});
  },
),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text('Delete Itinerary'),
                                content: Text(
                                    'Are you sure you want to delete this itinerary?'),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context)
                                          .pop(); // Close the dialog
                                    },
                                    child: Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context)
                                          .pop(); // Close the dialog
                                      _deleteItinerary(itinerary);
                                    },
                                    child: Text('Delete'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                  children: <Widget>[
                    if (itinerary['days'] is List)
                      ...((itinerary['days'] as List).map((day) {
                        final dayName = day['name'] ?? 'Unknown'; 
                        final date = DateFormat('yMMMd')
                            .format((day['date'] as Timestamp).toDate());
                        final locations = (day['locations'] as List).asMap().entries.map((entry) {
  int idx = entry.key;
  var location = entry.value;
  // Use the mod operator to cycle through the colorsSequence list
  Color currentColor = colorsSequence[idx % colorsSequence.length];
   return Row(
    children: [
      Icon(Icons.circle, color: currentColor, size: 20.0), // Bullet icon
      SizedBox(width: 5.0), // A small space between the bullet and text
      Expanded(child: Text(
        (location['name'] as String),
        style: TextStyle(fontSize: 25.0),  // Adjust the font size here
      ))
    ],
  );
}).toList();

                        return ListTile(
    title: Text(
        '$dayName - $date',
        style: TextStyle(fontSize: 30.0),  // Adjust the font size here
    ),
    subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: locations,
    ),
);

                      }).toList()), ...maps,]
                      
            ),
          ));
        },
      );
    },
  );
});
}
}

Future<Position> fetchUserLocation() async {
  try {
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  } catch (e) {
    // Handle errors here
    print('Failed to get user location: $e');
    throw e; // Propagate the error to the FutureBuilder
  }
}

void main() => runApp(MaterialApp(home: ItinerariesPage()));