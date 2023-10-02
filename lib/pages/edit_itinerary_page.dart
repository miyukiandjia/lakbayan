import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';


const API_KEY = "AIzaSyDMxSHLjuBE_QPy6OoJ1EPqpDsBCJ32Rr0";
const BASE_URL = "https://maps.googleapis.com/maps/api/place/textsearch/json";

class Location {
  String name;
  double latitude;
  double longitude;

  Location({
    required this.name,
    required this.latitude,
    required this.longitude
  });
}

class ItineraryDay {
  String name; // Name of the day
  DateTime date;
  List<Location> locations;
  TextEditingController nameController;

  ItineraryDay({
    required this.name,
    required this.date,
    required this.locations,
  }) : nameController = TextEditingController(text: name);
}




class LocationSearchBar extends StatefulWidget {
  final ItineraryDay day;
  final Function(Location) onLocationSelected;
  final Future<List<Location>> Function(double, double, String) searchLocations;

  LocationSearchBar({
    required this.day,
    required this.onLocationSelected,
    required this.searchLocations,
  });

  @override
  _LocationSearchBarState createState() => _LocationSearchBarState();
}

class _LocationSearchBarState extends State<LocationSearchBar> {
  TextEditingController _controller = TextEditingController();
  List<Location> _searchResults = [];
  Timer? _debounce;

  void _search() async {
    if (_controller.text.isEmpty) {
      setState(() {
        _searchResults.clear();
      });
      return;
    }

    Position? position = await Geolocator.getCurrentPosition();
    double lat = position.latitude;
    double lng = position.longitude;
    List<Location> locations = await widget.searchLocations(lat, lng, _controller.text);
    setState(() {
      _searchResults = locations;
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

   @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            labelText: 'Search Location',
          ),
          onChanged: (String text) {
            if (_debounce?.isActive ?? false) _debounce?.cancel();
            _debounce = Timer(const Duration(milliseconds: 500), () {
              _search();
            });
          },
        ),
        Container(
          height: 200.0,
          child: ListView.builder(
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  String selectedLocationName = _searchResults[index].name;
                  widget.onLocationSelected(_searchResults[index]);
                  // Clear the search results and text field
                  setState(() {
                    _searchResults.clear();
                    _controller.clear();
                  });
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('$selectedLocationName selected'),
                  ));
                },
                child: ListTile(
                  title: Text(_searchResults[index].name),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}


class EditItineraryPage extends StatefulWidget {
  final Map<String, dynamic> itinerary;

  EditItineraryPage({required this.itinerary});

  @override
  _EditItineraryPageState createState() => _EditItineraryPageState();
}

class _EditItineraryPageState extends State<EditItineraryPage> {
  late String itineraryName;
  late TextEditingController itineraryNameController;
  late List<ItineraryDay> days;

 @override
  void initState() {
    super.initState();
    itineraryName = widget.itinerary['itineraryName'] ?? 'Unknown';
    itineraryNameController = TextEditingController(text: itineraryName);
    days = (widget.itinerary['days'] as List).map((day) {
  final date = (day['date'] as Timestamp).toDate();
  final dayName = day['name'] ?? 'Unknown'; // Default to 'Unknown' if name is null
  final locations = (day['locations'] as List).map((location) {
    return Location(
      name: location['name'],
      latitude: location['latitude'],
      longitude: location['longitude'],
    );
  }).toList();

  return ItineraryDay(name: dayName, date: date, locations: locations);
}).toList();
  }

  Future<void> _selectDate(BuildContext context, ItineraryDay day) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: day.date,
      firstDate: DateTime(2000, 1),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null && pickedDate != day.date) {
      setState(() {
        day.date = pickedDate;
      });
    }
  }

  Future<void> _updateItinerary() async {
    DocumentReference docRef = widget.itinerary['docRef'] as DocumentReference;
    List<Map<String, dynamic>> updatedDays = days.map((day) {
      return {
        'name': day.name,
        'date': Timestamp.fromDate(day.date),
        'locations': day.locations.map((location) {
          return {
            'name': location.name,
            'latitude': location.latitude,
            'longitude': location.longitude,
          };
        }).toList(),
      };
    }).toList();

    await docRef.update({
      'itineraryName': itineraryName,
      'days': updatedDays,
    });

    Navigator.pop(context);
  }

  void _addDay() {
    setState(() {
      DateTime lastDate = days.isNotEmpty ? days.last.date : DateTime.now();
      DateTime newDate = lastDate.add(Duration(days: 1));
      days.add(ItineraryDay(name: 'New Day', date: newDate, locations: [])); // Default name 'New Day'
    });
  }

  void _deleteDay(int index) {
    setState(() {
      days.removeAt(index);
    });
  }

  void _deleteLocation(ItineraryDay day, int index) {
    setState(() {
      day.locations.removeAt(index);
    });
  }

  Future<List<Location>> searchLocations(double lat, double lng, String searchTerm) async {
  final url = "$BASE_URL?query=$searchTerm&location=$lat,$lng&radius=1500&key=$API_KEY";
  final response = await http.get(Uri.parse(url));
  if (response.statusCode == 200) {
    Map<String, dynamic> jsonResponse = json.decode(response.body);
    return (jsonResponse['results'] as List).map((result) {
      final locationLat = result['geometry']['location']['lat'] as double;
      final locationLng = result['geometry']['location']['lng'] as double;
      return Location(
        name: result['name'], 
        latitude: locationLat, 
        longitude: locationLng
      );
    }).toList();
  } else {
    throw Exception("Failed to load locations");
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Itinerary'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: itineraryNameController,
                decoration: InputDecoration(labelText: 'Itinerary Name'),
                onChanged: (value) {
                  setState(() {
                    itineraryName = value;
                  });
                },
              ),
              ...days.asMap().entries.map((entry) {
                final dayIndex = entry.key;
                final day = entry.value;
                return Card(
                  child: Column(
                    children: [
                      ListTile(
                        title: TextField(
                          controller: day.nameController,
    decoration: InputDecoration(labelText: 'Day Name'),
    onChanged: (value) {
      setState(() {
        day.name = value;
      });
                          },
                        ),
                        subtitle: Text(day.date.toLocal().toString().split(' ')[0]),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (days.length > 1) // Only show delete button if more than one day
                              IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () => _deleteDay(dayIndex),
                              ),
                            IconButton(
                              icon: Icon(Icons.calendar_today),
                              onPressed: () => _selectDate(context, day),
                            ),
                          ],
                        ),
                      ),
                        ...day.locations.map((location) {
                        return ListTile(
                          title: Text(location.name),
                          trailing: day.locations.length > 1 // Only show delete button if more than one location
                              ? IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () => _deleteLocation(day, day.locations.indexOf(location)),
                                )
                              : null,
                        );
                      }).toList(),
                      LocationSearchBar(
                        day: day,
                        onLocationSelected: (Location location) {
                          setState(() {
                            day.locations.add(location);
                          });
                        },
                        searchLocations: searchLocations,
                      ),
                    ],
                  ),
                );
              }).toList(),
              TextButton(
                onPressed: _addDay,
                child: Text('Add Day'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _updateItinerary,
        child: Icon(Icons.save),
      ),
    );
  }
}
