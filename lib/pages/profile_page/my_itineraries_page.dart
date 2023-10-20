import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:lakbayan/pages/home_page/itinerary/edit_itinerary_page.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lakbayan/pages/profile_page/profile_page.dart';
import 'package:google_maps_webservice/directions.dart' as gmaps;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'dart:math';
import 'package:lakbayan/constants.dart';
import 'package:lakbayan/pages/profile_page/subclasses/my_itin_subclasses.dart';

final directions = gmaps.GoogleMapsDirections(apiKey: API_KEY);

class ItinerariesPage extends StatefulWidget {
  const ItinerariesPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ItinerariesPageState createState() => _ItinerariesPageState();
}

class _ItinerariesPageState extends State<ItinerariesPage> {
  final List<Color> colorsSequence = [Colors.blue, Colors.green, Colors.red];
  Map<String, double> distanceCache = {};

  Future<List<Location>> fetchNearbyLocations(String category) async {
    List<Location> locations = [];
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      final response = await http.get(Uri.parse(
          '$BASE_URL?location=${position.latitude},${position.longitude}&radius=5000&type=$category&key=$API_KEY'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] as List<dynamic>;
        for (var result in results) {
          final name = result['name'] ?? '';
          final latitude = result['geometry']['location']['lat'];
          final longitude = result['geometry']['location']['lng'];
          locations.add(Location(
              name: name,
              category: category,
              latitude: latitude,
              longitude: longitude));
        }
      } else {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to load locations')));
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'An error occurred. Please check your location permissions.')));
    }
    return locations;
  }

  double euclideanDistance(Location a, Location b) {
    return sqrt(
        pow(a.latitude - b.latitude, 2) + pow(a.longitude - b.longitude, 2));
  }

  Future<double> totalDistance(List<Location> locations) async {
    double distance = 0.0;
    for (int i = 0; i < locations.length - 1; i++) {
      String cacheKey =
          "${locations[i].latitude},${locations[i].longitude}-${locations[i + 1].latitude},${locations[i + 1].longitude}";
      if (distanceCache.containsKey(cacheKey)) {
        distance += distanceCache[cacheKey]!;
      } else {
        gmaps.DirectionsResponse response = await directions.directions(
          gmaps.Location(
              lat: locations[i].latitude, lng: locations[i].longitude),
          gmaps.Location(
              lat: locations[i + 1].latitude, lng: locations[i + 1].longitude),
          travelMode: gmaps.TravelMode.driving,
        );
        if (response.status == 'OK' && response.routes.isNotEmpty) {
          double routeDistance =
              (response.routes[0].legs[0].distance.value).toDouble();
          distance += routeDistance;
          distanceCache[cacheKey] = routeDistance;
        }
      }
    }
    return distance;
  }

  List<Location> getNeighbor(List<Location> locations) {
    List<Location> newLocations = List.from(locations);
    int a = (newLocations.length * Random().nextDouble()).toInt();
    int b = (newLocations.length * Random().nextDouble()).toInt();
    while (b == a) {
      b = (newLocations.length * Random().nextDouble()).toInt();
    }
    Location temp = newLocations[a];
    newLocations[a] = newLocations[b];
    newLocations[b] = temp;
    return newLocations;
  }

  List<Location> perturbRoute(List<Location> currentRoute) {
    List<Location> newRoute = List.from(currentRoute);
    Random rand = Random();

    int index1 = rand.nextInt(newRoute.length);
    int index2 = rand.nextInt(newRoute.length);
    while (index1 == index2) {
      index2 = rand.nextInt(newRoute.length);
    }

    Location temp = newRoute[index1];
    newRoute[index1] = newRoute[index2];
    newRoute[index2] = temp;

    return newRoute;
  }

  Future<double> calculateRouteCost(List<Location> route) async {
    double cost = 0.0;
    for (int i = 0; i < route.length - 1; i++) {
      cost += euclideanDistance(route[i], route[i + 1]);
    }
    return cost;
  }

  Future<List<Location>> simulatedAnnealingOptimization(
      List<Location> initialRoute,
      {bool useReheat = false}) async {
    // ignore: avoid_print
    print("Starting simulated annealing optimization...");

    List<Location> currentRoute = List.from(initialRoute);
    List<Location> bestRoute = List.from(initialRoute);

    double currentCost = await calculateRouteCost(currentRoute);
    double bestCost = currentCost;

    double temperature = 1.0;
    double coolingRate = 0.995;

    Random rand = Random();

    int iteration = 0;
    int maxIterations = 10; // Setting the maximum iterations to 50

    while (temperature > 0.01 && iteration < maxIterations) {
      List<Location> newRoute = perturbRoute(List.from(currentRoute));
      double newCost = await calculateRouteCost(newRoute);

      if (newCost < currentCost ||
          rand.nextDouble() < exp((currentCost - newCost) / temperature)) {
        currentRoute = newRoute;
        currentCost = newCost;

        if (currentCost < bestCost) {
          bestRoute = currentRoute;
          bestCost = currentCost;
        }
      }

      temperature *= coolingRate;

      // Reheat logic, which is used only if useReheat is set to true
      if (useReheat && temperature < 0.01) {
        temperature = 0.3; // Reheat to 30% of the initial temperature
      }

      iteration++;
    }

    // ignore: avoid_print
    print(
        "Finished optimization after $iteration iterations with cost: $currentCost");
    return bestRoute;
  }

  Future<List<Location>> generateOptimizedRoute(
      List<Location> initialRoute) async {
    return await simulatedAnnealingOptimization(initialRoute);
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
          .showSnackBar(const SnackBar(content: Text('User not logged in')));
      return const Stream<QuerySnapshot>.empty();
    }
  }

  void _showEditDialog(Map<String, dynamic> itinerary, String status) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Itinerary'),
          content: const Text('Do you want to edit this itinerary?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
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
              child: const Text('Edit'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteItinerary(Map<String, dynamic> itinerary) async {
    DocumentReference docRef = itinerary['docRef'] as DocumentReference;
    await docRef.delete();
    // ignore: use_build_context_synchronously
    Navigator.of(context).pop(); // Close the delete confirmation dialog

    // Navigate back to the ItinerariesPage
    // ignore: use_build_context_synchronously
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const ItinerariesPage()),
      (Route<dynamic> route) => false,
    );
  }

  Future<Map<String, dynamic>> _calculateRoute(
      List<LatLng> polylineCoordinates) async {
    List<Location> locations = polylineCoordinates
        .map((coord) => Location(
            name: 'Unknown',
            category: 'Unknown',
            latitude: coord.latitude,
            longitude: coord.longitude))
        .toList();

    List<Location> optimizedLocations =
        await simulatedAnnealingOptimization(locations, useReheat: true);

    List<LatLng> optimizedCoordinates = optimizedLocations
        .map((loc) => LatLng(loc.latitude, loc.longitude))
        .toList();
    List<Polyline> polylines = [];
    List<Color> usedColors = [];

    for (int i = 0; i < optimizedCoordinates.length - 1; i++) {
      LatLng from = optimizedCoordinates[i];
      LatLng to = optimizedCoordinates[i + 1];

      gmaps.DirectionsResponse response = await directions.directions(
        gmaps.Location(lat: from.latitude, lng: from.longitude),
        gmaps.Location(lat: to.latitude, lng: to.longitude),
        travelMode: gmaps.TravelMode.driving,
      );

      if (response.status == 'OK') {
        PolylinePoints polylinePoints = PolylinePoints();
        var points = polylinePoints
            .decodePolyline(response.routes[0].overviewPolyline.points);
        List<LatLng> segmentPoints = points
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();

        Color polylineColor = colorsSequence[i % colorsSequence.length];
        usedColors.add(polylineColor);

        Polyline polyline = Polyline(
          polylineId: PolylineId('route_$i'),
          color: polylineColor,
          points: segmentPoints,
          width: 5,
        );

        polylines.add(polyline);
      } else {
        // ignore: avoid_print
        print("Error");
      }
    }

    return {
      "polylines": polylines,
      "colors": usedColors,
    };
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
          icon:
              BitmapDescriptor.defaultMarkerWithHue(getHueFromColor(colors[i])),
        ),
      );
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Itineraries'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Navigate back to ProfilePage
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const ProfilePage()),
            );
          },
        ),
      ),
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: <Widget>[
            Container(
              constraints: const BoxConstraints(maxHeight: 150.0),
              child: const Material(
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
    return FutureBuilder<Position>(
        future: fetchUserLocation(),
        builder:
            (BuildContext context, AsyncSnapshot<Position> positionSnapshot) {
          if (positionSnapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator(); // Loading indicator while fetching user's location
          }

          if (positionSnapshot.hasError) {
            return const Text('Failed to get user location'); // Handle errors
          }

          final userPosition = positionSnapshot.data;
          return StreamBuilder<QuerySnapshot>(
            stream: _getItinerariesByStatus(status),
            builder:
                (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.hasError) {
                return const Text('Something went wrong');
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }
              if (snapshot.data == null) {
                return const Text('No data found');
              }

              final itineraries =
                  snapshot.data!.docs.map<Map<String, dynamic>>((doc) {
                final data = doc.data() as Map<String, dynamic>? ?? {};
                return {'docRef': doc.reference, ...data};
              }).toList();

              return ListView.builder(
                itemCount: itineraries.length,
                itemBuilder: (context, index) {
                  final itinerary = itineraries[index];
                  List<Widget> maps = [];

                  if (itinerary['days'] != null) {
                    List<Map<String, dynamic>> days =
                        List<Map<String, dynamic>>.from(itinerary['days']);
                    for (var day in days) {
                      List<LatLng> polylineCoordinates = [];
                      if (day['locations'] != null) {
                        for (var location in day['locations']) {
                          if (location['latitude'] != null &&
                              location['longitude'] != null) {
                            LatLng latLng = LatLng(
                                location['latitude'] as double,
                                location['longitude'] as double);
                            polylineCoordinates.add(latLng);
                          }
                        }
                      }
                      if (userPosition != null &&
                          polylineCoordinates.isNotEmpty) {
                        LatLng userLatLng = LatLng(
                            userPosition.latitude, userPosition.longitude);
                        polylineCoordinates.insert(0, userLatLng);

                        maps.add(FutureBuilder(
                          future: _calculateRoute(polylineCoordinates),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            } else if (snapshot.hasError) {
                              return const Text('Error calculating route');
                            } else {
                              Map<String, dynamic> data =
                                  snapshot.data as Map<String, dynamic>;
                              List<Polyline> polylines =
                                  data['polylines'] as List<Polyline>;
                              List<Color> usedColors =
                                  data['colors'] as List<Color>;

                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0),
                                child: Container(
                                  height: 400,
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 16.0),
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
                                    borderRadius: BorderRadius.circular(15.0),
                                    child: GoogleMap(
                                      initialCameraPosition: CameraPosition(
                                        target: polylineCoordinates.first,
                                        zoom: 18.0,
                                      ),
                                      polylines: Set.from(polylines),
                                      myLocationEnabled: true,
                                      markers: _generateMarkers(
                                          polylineCoordinates.sublist(1),
                                          usedColors),
                                      gestureRecognizers: <Factory<
                                          OneSequenceGestureRecognizer>>{
                                        Factory<OneSequenceGestureRecognizer>(
                                          () => EagerGestureRecognizer(),
                                        ),
                                      },
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
                      margin: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 5,
                            blurRadius: 7,
                            offset: const Offset(0, 3),
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
                                    style: const TextStyle(fontSize: 30),
                                  ),
                                ),
                                const Text("Share"),
                                Switch(
                                  value: itinerary['shareStatus'] ??
                                      false, // default to private if shareStatus is null
                                  onChanged: (value) {
                                    DocumentReference docRef =
                                        itinerary['docRef']
                                            as DocumentReference;
                                    docRef.update({'shareStatus': value});
                                  },
                                ),
                                const Text("Active"),
                                Switch(
                                  value: status == "Ongoing",
                                  onChanged: (value) {
                                    String updatedStatus =
                                        value ? "Ongoing" : "Upcoming";
                                    DocumentReference docRef =
                                        itinerary['docRef']
                                            as DocumentReference;
                                    docRef.update({'status': updatedStatus});
                                  },
                                ),
                                const Text("Done"),
                                Switch(
                                  value: status == "Done",
                                  onChanged: (value) {
                                    String updatedStatus =
                                        value ? "Done" : "Ongoing";
                                    DocumentReference docRef =
                                        itinerary['docRef']
                                            as DocumentReference;
                                    docRef.update({'status': updatedStatus});
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: const Text('Delete Itinerary'),
                                          content: const Text(
                                              'Are you sure you want to delete this itinerary?'),
                                          actions: <Widget>[
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context)
                                                    .pop(); // Close the dialog
                                              },
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context)
                                                    .pop(); // Close the dialog
                                                _deleteItinerary(itinerary);
                                              },
                                              child: const Text('Delete'),
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
                                  final date = DateFormat('yMMMd').format(
                                      (day['date'] as Timestamp).toDate());
                                  final locations = (day['locations'] as List)
                                      .asMap()
                                      .entries
                                      .map((entry) {
                                    int idx = entry.key;
                                    var location = entry.value;
                                    // Use the mod operator to cycle through the colorsSequence list
                                    Color currentColor = colorsSequence[
                                        idx % colorsSequence.length];
                                    return Row(
                                      children: [
                                        Icon(Icons.circle,
                                            color: currentColor,
                                            size: 20.0), // Bullet icon
                                        const SizedBox(
                                            width:
                                                5.0), // A small space between the bullet and text
                                        Expanded(
                                            child: Text(
                                          (location['name'] as String),
                                          style: const TextStyle(
                                              fontSize:
                                                  25.0), // Adjust the font size here
                                        ))
                                      ],
                                    );
                                  }).toList();

                                  return ListTile(
                                    title: Text(
                                      '$dayName - $date',
                                      style: const TextStyle(
                                          fontSize:
                                              30.0), // Adjust the font size here
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: locations,
                                    ),
                                  );
                                }).toList()),
                              ...maps,
                            ]),
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
    // ignore: avoid_print
    print('Failed to get user location: $e');
    rethrow; // Propagate the error to the FutureBuilder
  }
}

void main() => runApp(const MaterialApp(home: ItinerariesPage()));
