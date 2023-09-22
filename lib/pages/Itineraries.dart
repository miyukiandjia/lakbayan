import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

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

  Future<List<Location>> fetchFirestoreData() async {
    List<Location> destinations = [];

    QuerySnapshot<Map<String, dynamic>> querySnapshot =
        await FirebaseFirestore.instance.collection('datasets').get();

    for (var doc in querySnapshot.docs) {
      var data = doc.data();
      var name = data['place'] ?? 'Unknown Place';
      var category = data['category'] ?? 'Unknown Category';
      destinations.add(Location(name: name, category: category));
    }

    return destinations;
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
      return Stream<QuerySnapshot>.empty();
    }
  }

  void _showEditDialog(Map<String, dynamic> itinerary, String status) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Itinerary'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: status == "Done"
                  ? [
                      ElevatedButton(
                        onPressed: () async {
                          await _deleteItinerary(itinerary);
                        },
                        child: Text('Delete Itinerary'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          await _unmarkAsDone(itinerary);
                        },
                        child: Text('Unmark as Done'),
                      ),
                    ]
                  : [
                       ElevatedButton(
                      onPressed: () async {
                        final selectedData = await _selectDayAndLocation(itinerary);
                        if (selectedData != null) {
                          final selectedLocation = await _changeLocation();
                          if (selectedLocation != null) {
                            // Logic to update selected day and location
                            setState(() {
                              itinerary['days'][selectedData['dayIndex']]['locations'][selectedData['locationIndex']] = {
                                'name': selectedLocation.name,
                                'category': selectedLocation.category,
                                'status': 'Ongoing',
                              };
                            });
                          }
                        }
                      },
                      child: Text('Change Location'),
                    ),
                      ElevatedButton(
                        onPressed: () async {
                          final selectedDate = await _changeDate();
                          if (selectedDate != null) {
                            // Logic to update date
                          }
                        },
                        child: Text('Change Date'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          _addDay(itinerary);
                        },
                        child: Text('Add Day'),
                      ),
                    ],
            ),
          ),
        );
      },
    );
  }
Future<void> _reloadLocalItineraries() async {
  User? currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser != null) {
    String uid = currentUser.uid;
    QuerySnapshot<Map<String, dynamic>> querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('itineraries')
        .where('status', isEqualTo: 'Ongoing')
        .get();

    _localItineraries = querySnapshot.docs.map<Map<String, dynamic>>((doc) {
      return {
        'docRef': doc.reference,
        ...doc.data() as Map<String, dynamic>
      };
    }).toList();
  } else {
    _localItineraries.clear();
  }
}
Future<Map<String, dynamic>?> _selectDayAndLocation(Map<String, dynamic> itinerary) async {
  Map<String, dynamic>? selectedData;
  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
  title: Text('Select Day and Location'),
  content: Container(
    // Constrain the height of the AlertDialog
    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
    child: SingleChildScrollView(
      child: ListView.builder(
        // Setting shrinkWrap to true as the ListView is inside a SingleChildScrollView
        shrinkWrap: true,
        itemCount: itinerary['days'].length,
        itemBuilder: (context, index) {
          final day = itinerary['days'][index];
          return ExpansionTile(
            title: Text('Day ${index + 1}'),
            children: List<Widget>.generate(day['locations'].length, (locationIndex) {
              final location = day['locations'][locationIndex];
              return ListTile(
                title: Text(location['name']),
                onTap: () {
                  Navigator.of(context).pop({
                    'dayIndex': index,
                    'locationIndex': locationIndex,
                  });
                },
              );
            }),
          );
        },
      ),
    ),
  ),
);

    },
  ).then((value) {
    selectedData = value;
  });
  return selectedData;
}

 Future<List<Location>> fetchNearbyLocations() async {
    List<Location> locations = [];
    
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    
    final response = await http.get(Uri.parse(
      '$BASE_URL?location=${position.latitude},${position.longitude}&radius=5000&key=$API_KEY',
    ));
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final results = data['results'] as List<dynamic>;
      for (var result in results) {
        final name = result['name'];
        final category = result['types'][0];
        locations.add(Location(name: name, category: category));
      }
    } else {
      print('Failed to load locations');
    }
    
    return locations;
  }
  
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Your Itineraries"),
          bottom: TabBar(
            tabs: [
              Tab(text: "Current"),
              Tab(text: "Done"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildItineraryListView("Ongoing"),
            _buildItineraryListView("Done"),
          ],
        ),
      ),
    );
  }

  Widget _buildItineraryListView(String status) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getItinerariesByStatus(status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text("No itineraries available."));
        }

        if (status == "Ongoing" && _localItineraries.isEmpty) {
          _localItineraries = snapshot.data!.docs.map<Map<String, dynamic>>((doc) {
            return {
              'docRef': doc.reference,
              ...doc.data() as Map<String, dynamic>
            };
          }).toList();
        }

        List<Map<String, dynamic>> itinerariesToDisplay =
            (status == "Ongoing") ? _localItineraries : snapshot.data!.docs.map<Map<String, dynamic>>((doc) {
              return {
                'docRef': doc.reference,
                ...doc.data() as Map<String, dynamic>
              };
            }).toList();

        return ListView.builder(
          itemCount: itinerariesToDisplay.length,
          itemBuilder: (context, index) {
            return _buildItineraryCard(itinerariesToDisplay[index], status);
          },
        );
      },
    );
  }

  Widget _buildItineraryCard(Map<String, dynamic> itinerary, String status) {
  final days = List<Map<String, dynamic>>.from(itinerary['days'] ?? []);
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Itinerary Name: ${itinerary['itineraryName']}',
                  style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold)),
              IconButton(
                icon: Icon(Icons.edit),
                onPressed: () => _showEditDialog(itinerary, status),
              )
            ],
          ),
          for (int i = 0; i < days.length; i++) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Day ${i + 1}: ${days[i]['name']}',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
              ],
            ),
           ..._buildLocationsList(days[i]['locations'], status),
// New function to display locations
            Text(
                'Date: ${DateTime.fromMillisecondsSinceEpoch((days[i]['date'] as Timestamp).seconds * 1000).toLocal().toString().split(' ')[0]}',
                style: TextStyle(fontSize: 25)),
          ],
          if (status == "Ongoing")
            ElevatedButton(
              onPressed: () async {
                _updateDayStatusBasedOnLocations(days);
                await _saveItineraryUpdates(itinerary);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Itinerary updated!')));
              },
              child: Text('Save'),
            ),
        ],
      ),
    ),
  );
}

List<Widget> _buildLocationsList(List<dynamic>? locations, String status) {  // <-- Add status parameter
  if (locations == null) return [];

  return List<Map<String, dynamic>>.from(locations).map((location) {
    return Padding(
      padding: const EdgeInsets.only(left: 20.0, top: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(location['name'], style: TextStyle(fontSize: 25)),
          Text(location['category'], style: TextStyle(fontSize: 20)),
          if (status == "Ongoing")  // <-- Only show Switch if the status is "Ongoing"
            Switch(
              value: location['status'] == "Done",
              onChanged: (bool value) {
                setState(() {
                  location['status'] = value ? "Done" : "Ongoing";
                });
              },
            ),
        ],
      ),
    );
  }).toList();
}




 void _updateDayStatusBasedOnLocations(List<Map<String, dynamic>> days) {
  for (var day in days) {
    bool allLocationsDone = List<Map<String, dynamic>>.from(day['locations']).every((location) => location['status'] == "Done");
    day['status'] = allLocationsDone ? "Done" : "Ongoing";
  }
}

Future<void> _saveItineraryUpdates(Map<String, dynamic> itinerary) async {
  int index = _localItineraries.indexOf(itinerary);
  if (index != -1) {
    bool allDaysDone = _localItineraries[index]['days'].every((day) => day['status'] == "Done");
    await itinerary['docRef'].update({
      'days': _localItineraries[index]['days'],
      'status': allDaysDone ? "Done" : "Ongoing"
    });
    await _reloadLocalItineraries();  // Reload the local cache
    setState(() {});
  }
}

 Future<void> _unmarkAsDone(Map<String, dynamic> itinerary) async {
    List<Map<String, dynamic>> updatedDays = List<Map<String, dynamic>>.from(itinerary['days']).map((day) {
        day['status'] = 'Ongoing';
        List<Map<String, dynamic>> locations = List<Map<String, dynamic>>.from(day['locations']);
        for (var location in locations) {
            location['status'] = 'Ongoing';  // Resetting each location's status
        }
        day['locations'] = locations;
        return day;
    }).toList();

    await itinerary['docRef'].update({
        'status': 'Ongoing',
        'days': updatedDays
    });

    Navigator.of(context).pop(); 
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Itinerary marked as Ongoing!')));
    await _reloadLocalItineraries();  // Reload the local cache
    setState(() {});
}


Future<void> _deleteItinerary(Map<String, dynamic> itinerary) async {
  await itinerary['docRef'].delete();
  Navigator.of(context).pop(); 
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Itinerary deleted!')));
  await _reloadLocalItineraries();  // Reload the local cache
  setState(() {});
}


 Future<Location?> _changeLocation() async {
  final locations = await fetchNearbyLocations(); // Fetch locations using Google Places API
  Location? selectedLocation;
  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Select a location'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return DropdownButton<Location>(
              value: selectedLocation, // Set the value to the currently selected location
              items: locations.map((Location location) {
                return DropdownMenuItem<Location>(
                  value: location,
                  child: Text('${location.name} - ${location.category}'),
                );
              }).toList(),
              onChanged: (Location? newValue) {
                setState(() {
                  selectedLocation = newValue; // Update the selected location within the dialog
                });
              },
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('OK'),
          ),
        ],
      );
    },
  );
  return selectedLocation;
}


  Future<DateTime?> _changeDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000, 1),
      lastDate: DateTime(2101),
    );
    return pickedDate;
  }

  void _addDay(Map<String, dynamic> itinerary) {
    var newDay = {
      'name': 'New Day',
      'date': DateTime.now(),
      'locations': [],
    };
    itinerary['days'].add(newDay);
  }
}
