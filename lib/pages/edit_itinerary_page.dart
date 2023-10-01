import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

const API_KEY = "AIzaSyDMxSHLjuBE_QPy6OoJ1EPqpDsBCJ32Rr0";
const BASE_URL = "https://maps.googleapis.com/maps/api/place/nearbysearch/json";



class Location {
  String name;
  String category;
  double latitude;
  double longitude;

  Location({
    required this.name,
    required this.category,
    required this.latitude,
    required this.longitude
  });
}

class ItineraryDay {
  DateTime date;
  List<Location> locations;
  ItineraryDay({required this.date, required this.locations});
}

class LocationSearchBar extends StatefulWidget {
  final ItineraryDay day;
  final Function(Location) onLocationSelected;

  LocationSearchBar({
    required this.day,
    required this.onLocationSelected,
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

    Position position = await Geolocator.getCurrentPosition();
      double lat = position.latitude;
      double lng = position.longitude;
      final url = "$BASE_URL?location=$lat,$lng&radius=1500&keyword=${_controller.text}&key=$API_KEY";
      final response = await http.get(Uri.parse(url));
      final data = jsonDecode(response.body);
      final results = data['results'] as List<dynamic>;

      setState(() {
        _searchResults = results.map((result) {
          return Location(
            name: result['name'],
            category: '', // Adjust category accordingly
            latitude: result['geometry']['location']['lat'],
            longitude: result['geometry']['location']['lng'],
          );
        }).toList();
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
                  final selectedLocation = _searchResults[index];
                  widget.onLocationSelected(selectedLocation);
                  setState(() {
                    _searchResults.clear();
                    _controller.clear();
                  });
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
      final locations = (day['locations'] as List).map((location) {
        return Location(
          name: location['name'],
          category: location['category'],
          latitude: location['latitude'],
          longitude: location['longitude']
        );
      }).toList();

      return ItineraryDay(date: date, locations: locations);
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

  Future<void> _selectLocationAndUpdate(ItineraryDay day, Location location) async {
    final newCategory = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text('Select Category'),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'restaurant'),
              child: Text('Restaurant'),
            ),
            // Add other categories as needed
          ],
        );
      },
    );

    if (newCategory != null) {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

      final response = await http.get(Uri.parse(
          '$BASE_URL?location=${position.latitude},${position.longitude}&radius=1500&type=$newCategory&key=$API_KEY'));
      final data = jsonDecode(response.body);
      final results = data['results'] as List<dynamic>;

      final newName = await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            title: Text('Select Location'),
            children: results.map((result) {
              return SimpleDialogOption(
                onPressed: () => Navigator.pop(context, result['name']),
                child: Text(result['name']),
              );
            }).toList(),
          );
        },
      );

     if (newName != null) {
  final selectedLocation = results.firstWhere((result) => result['name'] == newName);
  double lat = selectedLocation['geometry']['location']['lat'];
  double lng = selectedLocation['geometry']['location']['lng'];

  setState(() {
    location.name = newName;
    location.category = newCategory;
    location.latitude = lat;
    location.longitude = lng;
  });
}

    }
  }

  Future<void> _updateItinerary() async {
    DocumentReference docRef = widget.itinerary['docRef'] as DocumentReference;
    List<Map<String, dynamic>> updatedDays = days.map((day) {
      return {
        'date': Timestamp.fromDate(day.date),
        'locations': day.locations.map((location) {
          return {
  'name': location.name,
  'category': location.category,
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
    days.add(ItineraryDay(date: newDate, locations: [Location(name: 'Location', category: 'Category', latitude: 0.0, longitude: 0.0)]));
  });
}

  void _deleteDay(int index) {
    setState(() {
      days.removeAt(index);
    });
  }


void _addLocation(ItineraryDay day) {
  setState(() {
    day.locations.add(Location(name: 'Location', category: 'Category', latitude: 0.0, longitude: 0.0));
  });
}

  void _deleteLocation(ItineraryDay day, int index) {
    setState(() {
      day.locations.removeAt(index);
    });
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
                        title: Text('Day ${dayIndex + 1}'),
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
                          subtitle: Text(location.category),
                          trailing: day.locations.length > 1 // Only show delete button if more than one location
                              ? IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () => _deleteLocation(day, day.locations.indexOf(location)),
                                )
                              : null,
                          onTap: () => _selectLocationAndUpdate(day, location),
                        );
                      }).toList(),
                      LocationSearchBar(
                        day: day,
                        onLocationSelected: (Location location) {
                          setState(() {
                            day.locations.add(location);
                          });
                        },
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