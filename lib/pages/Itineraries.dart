import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:lakbayan/pages/edit_itinerary_page.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

const BASE_URL = "https://maps.googleapis.com/maps/api/place/nearbysearch/json";
const API_KEY = "AIzaSyDMxSHLjuBE_QPy6OoJ1EPqpDsBCJ32Rr0";

class Location {
  final String name;
  final String category;
  Location({required this.name, required this.category});
}

class ItinerariesPage extends StatefulWidget {
  @override
  _ItinerariesPageState createState() => _ItinerariesPageState();
}

class _ItinerariesPageState extends State<ItinerariesPage> {
  List<Map<String, dynamic>> _localItineraries = [];

  Future<List<Location>> fetchNearbyLocations(String category) async {
    List<Location> locations = [];
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      final response = await http.get(Uri.parse(
          '$BASE_URL?location=${position.latitude},${position.longitude}&radius=5000&type=$category&key=$API_KEY'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print(data);
        final results = data['results'] as List<dynamic>;
        for (var result in results) {
          final name = result['name'] ?? ''; // Check for null
          locations.add(Location(name: name, category: category));
        }
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to load locations')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'An error occurred. Please check your location permissions.')));
    }
    return locations;
  }

  Future<Widget> _buildMap(List<Map<String, dynamic>> days) async {
    Position position;
    try {
      position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
    } catch (e) {
      return Text('Failed to get current location');
    }

    LatLng currentUserLocation = LatLng(position.latitude, position.longitude);

    // Create markers for each location
    Set<Marker> markers = {};
    List<LatLng> polylineCoordinates = [currentUserLocation];
    int markerId = 1;
    for (var day in days) {
      for (var location in day['locations']) {
        // Assume that the location has latitude and longitude properties
        LatLng latLng = LatLng(location['latitude'], location['longitude']);
        // Example of adding a marker to the markers set
        markers.add(Marker(
          markerId: MarkerId(markerId.toString()),
          position: location.latLng,
          infoWindow: InfoWindow(title: location['name']),
        ));
        polylineCoordinates.add(latLng);
        markerId++;
      }
    }

    // Create a polyline connecting all the locations
    Polyline polyline = Polyline(
      polylineId: PolylineId('route'),
      color: Colors.blue,
      points: polylineCoordinates,
    );

    // Display the map with markers and polyline
    return Stack(
      children: [
        Container(
          height: 400,
          width: 800,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15.0),
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: currentUserLocation,
                zoom: 14.0,
              ),
              markers: {
                Marker(
                    markerId: const MarkerId('currentLocation'),
                    position: LatLng(currentUserLocation.latitude,
                        currentUserLocation.longitude)),
                Marker(
                  markerId: const MarkerId('currentLocation'),
                  // position: LatLng(.latitude,
                  //     .longitude)),
                  /// BUTAAAAAAAAAAAAAAANG DIRIIIIIII -----------------------------------------------------!!!!!!!!!!!!!!!!
                )
              },
              polylines: {polyline},
              myLocationEnabled: true,
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.all(8.0),
            color: Colors.white,
            child: Text(
              "Navigating to: ",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
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

  Future<void> _reloadLocalItineraries() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      String uid = currentUser.uid;
      QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('itineraries')
              .where('status', isEqualTo: 'Ongoing')
              .get();

      _localItineraries = querySnapshot.docs.map<Map<String, dynamic>>((doc) {
        return {
          'docRef': doc.reference,
          ...(doc.data() as Map<String, dynamic>?) ?? {}
        };
      }).toList();
    } else {
      _localItineraries.clear();
    }
  }

  Future<DateTime?> _selectDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    return pickedDate;
  }

  Future<void> _updateDate(Map<String, dynamic> itinerary) async {
    final List<Map<String, dynamic>> days = itinerary['days'];
    final selectedDayIndex = await _selectDay(days);
    if (selectedDayIndex != null) {
      final selectedDate = await _selectDate();
      if (selectedDate != null) {
        setState(() {
          days[selectedDayIndex]['date'] = Timestamp.fromDate(selectedDate);
        });
        print(itinerary);
        await _saveItineraryUpdates(itinerary);
      }
    }
  }

  Future<void> _updateLocation(Map<String, dynamic> itinerary) async {
    final selectedCategory =
        await _selectCategory(); // Ask the user to select a category
    if (selectedCategory != null) {
      final locations = await fetchNearbyLocations(selectedCategory);
      final selectedLocation = await showDialog<Location>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Select a Location'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: locations.map((location) {
                  return ListTile(
                    title: Text(location.name),
                    onTap: () {
                      Navigator.of(context)
                          .pop(location); // Return the selected location
                    },
                  );
                }).toList(),
              ),
            ),
          );
        },
      );

      if (selectedLocation != null) {
        final dayAndLocation = await _selectDayAndLocation(itinerary);
        if (dayAndLocation != null) {
          final dayIndex = dayAndLocation['dayIndex'] as int;
          final locationIndex = dayAndLocation['locationIndex'] as int;

          final List<Map<String, dynamic>> days = itinerary['days'];
          final Map<String, dynamic> day = days[dayIndex];

          if (day['locations'] is List<Map<String, dynamic>>) {
            final List<Map<String, dynamic>> locations = day['locations'];
            locations[locationIndex] = {
              'name': selectedLocation.name,
              'category': selectedLocation.category,
            };
          } else {
            print("Error: 'locations' is not a List<Map<String, dynamic>>");
          }

          await _saveItineraryUpdates(itinerary);
        }
      }
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

  Future<String?> _selectCategory() async {
    String selectedCategory = 'Restaurant'; // Default value
    return await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Select a Category'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text('Restaurant'),
                  onTap: () {
                    Navigator.of(context).pop('Restaurant');
                  },
                ),
                ListTile(
                  title: Text('Museum'),
                  onTap: () {
                    Navigator.of(context).pop('Museum');
                  },
                ),
                ListTile(
                  title: Text('Park'),
                  onTap: () {
                    Navigator.of(context).pop('Park');
                  },
                ),
                ListTile(
                  title: Text('Shopping Mall'),
                  onTap: () {
                    Navigator.of(context).pop('Shopping Mall');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<Location?> _selectLocation(String category) async {
    final locations = await fetchNearbyLocations(category);
    return await showDialog<Location>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Select a Location'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: locations.map((location) {
                return ListTile(
                  title: Text(location.name),
                  onTap: () {
                    Navigator.of(context)
                        .pop(location); // Return the selected location
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Future<Map<String, int>?> _selectDayAndLocation(
      Map<String, dynamic> itinerary) async {
    final days = itinerary['days'] as List<Map<String, dynamic>>;
    return await showDialog<Map<String, int>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Select a Day and Location'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: days.asMap().entries.map((dayEntry) {
                final dayIndex = dayEntry.key;
                final day = dayEntry.value;
                if (day['locations'] is! List<Map<String, dynamic>>) {
                  // Handle the case where 'locations' is not the expected type
                  return Container(); // Return an empty container or any other widget
                }
                final locations =
                    day['locations'] as List<Map<String, dynamic>>;
                return Column(
                  children: locations.asMap().entries.map((locationEntry) {
                    final locationIndex = locationEntry.key;
                    final location = locationEntry.value;
                    return ListTile(
                      title: Text('${day['date']}: ${location['name']}'),
                      onTap: () {
                        Navigator.of(context).pop({
                          'dayIndex': dayIndex,
                          'locationIndex': locationIndex
                        });
                      },
                    );
                  }).toList(),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveItineraryUpdates(Map<String, dynamic> itinerary) async {
    DocumentReference docRef = itinerary['docRef'] as DocumentReference;
    try {
      await docRef.set(itinerary, SetOptions(merge: true));
    } catch (e) {
      print("Error saving itinerary updates: $e");
    }
  }

  Future<void> _deleteItinerary(Map<String, dynamic> itinerary) async {
    DocumentReference docRef = itinerary['docRef'] as DocumentReference;
    await docRef.delete();
    Navigator.of(context).pop();
  }

  Future<void> _unmarkAsDone(Map<String, dynamic> itinerary) async {
    DocumentReference docRef = itinerary['docRef'] as DocumentReference;
    await docRef.update({'status': 'Ongoing'});
    Navigator.of(context).pop();
  }

  Future<int?> _selectDay(List<Map<String, dynamic>> days) async {
    return await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Select a Day'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: days.asMap().entries.map((entry) {
                final index = entry.key;
                final day = entry.value;
                return ListTile(
                  title: Text('${day['date']}'),
                  onTap: () {
                    Navigator.of(context).pop(index);
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Itineraries'),
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
        final itineraries =
            snapshot.data!.docs.map<Map<String, dynamic>>((doc) {
          final data = doc.data() as Map<String, dynamic>? ?? {};
          return {'docRef': doc.reference, ...data};
        }).toList();
        return ListView.builder(
          itemCount: itineraries.length,
          itemBuilder: (context, index) {
            final itinerary = itineraries[index];
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
                      Switch(
                        value: status == "Ongoing",
                        onChanged: (value) {
                          String updatedStatus = value ? "Ongoing" : "Upcoming";
                          DocumentReference docRef =
                              itinerary['docRef'] as DocumentReference;
                          docRef.update({'status': updatedStatus});
                        },
                      ),
                    ],
                  ),
                  children: <Widget>[
                    if (itinerary['days'] is List)
                      ...((itinerary['days'] as List).map((day) {
                        final date = DateFormat('yMMMd')
                            .format((day['date'] as Timestamp).toDate());
                        final locations =
                            (day['locations'] as List).map((location) {
                          return Text((location['name'] as String) +
                              " - " +
                              (location['category'] as String));
                        }).toList();
                        return ListTile(
                          title: Text(date),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: locations,
                          ),
                        );
                      }).toList()),
                    FutureBuilder<Widget>(
                      future: _buildMap(List<Map<String, dynamic>>.from(
                          itinerary['locations']
                                  ?.map((e) => e as Map<String, dynamic>) ??
                              [])),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return CircularProgressIndicator(); // Show a loader while waiting
                        } else if (snapshot.hasError) {
                          return Text('Failed to load map'); // Show error text
                        } else {
                          return snapshot.data ?? Container(); // Show the map
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

void main() => runApp(MaterialApp(home: ItinerariesPage()));
