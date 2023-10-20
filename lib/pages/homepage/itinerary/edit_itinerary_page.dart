import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:lakbayan/constants.dart';
import 'package:lakbayan/pages/homepage/itinerary/subclasses/edit_subclasses.dart';

class EditItineraryPage extends StatefulWidget {
  final Map<String, dynamic> itinerary;

  const EditItineraryPage({super.key, required this.itinerary});

  @override
  // ignore: library_private_types_in_public_api
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

    // ignore: use_build_context_synchronously
    Navigator.pop(context);
  }

  void _addDay() {
    setState(() {
      DateTime lastDate = days.isNotEmpty ? days.last.date : DateTime.now();
      DateTime newDate = lastDate.add(const Duration(days: 1));
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
        title: const Text('Edit Itinerary'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: itineraryNameController,
                decoration: const InputDecoration(labelText: 'Itinerary Name'),
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
                          decoration: const InputDecoration(labelText: 'Day Name'),
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
                                icon: const Icon(Icons.delete),
                                onPressed: () => _deleteDay(dayIndex),
                              ),
                            IconButton(
                              icon: const Icon(Icons.calendar_today),
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
                                  icon: const Icon(Icons.delete),
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
                child: const Text('Add Day'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _updateItinerary,
        child: const Icon(Icons.save),
      ),
    );
  }
}
