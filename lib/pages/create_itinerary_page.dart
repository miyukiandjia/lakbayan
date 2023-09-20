import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lakbayan/pages/overview_itinerary_page.dart';
import 'package:http/http.dart' as http;
import 'package:lakbayan/current_Loc.dart';
import 'package:geolocator/geolocator.dart';

const BASE_URL = "https://maps.googleapis.com/maps/api/place/nearbysearch/json";

class Location {
  final String name;
  final String category;

  Location({required this.name, required this.category});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Location &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          category == other.category;

  @override
  int get hashCode => name.hashCode ^ category.hashCode;
}

class ItineraryDay {
  String name;
  DateTime date;
  List<Location?> locations;
  List<Location> fetchedLocationsRestaurants = [];
  List<Location> fetchedLocationsParks = [];
  //... you can add more for other categories

  ItineraryDay(
      {required this.name, required this.date, required this.locations});
}

class CreateItineraryPage extends StatefulWidget {
  const CreateItineraryPage({super.key});

  @override
  _CreateItineraryPageState createState() => _CreateItineraryPageState();
}

class _CreateItineraryPageState extends State<CreateItineraryPage> {
  List<Location> allLocations = [];
  List<ItineraryDay> days = [
    ItineraryDay(name: "", date: DateTime.now(), locations: [null])
  ];
  final TextEditingController _itineraryNameController =
      TextEditingController();

  String? selectedCategory;

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

  Future<List<Location>> fetchNearbyPlaces(
      double lat, double lng, String category) async {
    final url =
        "$BASE_URL?location=$lat,$lng&radius=1500&type=$category&key=AIzaSyDMxSHLjuBE_QPy6OoJ1EPqpDsBCJ32Rr0";
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      Map<String, dynamic> jsonResponse = json.decode(response.body);
      return (jsonResponse['results'] as List).map((result) {
        return Location(name: result['name'], category: category);
      }).toList();
    } else {
      throw Exception("Failed to load nearby places");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Itinerary', style: TextStyle(fontSize: 50)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: TextField(
                controller: _itineraryNameController,
                decoration: const InputDecoration(labelText: "Itinerary Name"),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: days.length + 1,
                itemBuilder: (context, index) {
                  if (index == days.length) {
                    return IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        setState(() {
                          days.add(ItineraryDay(
                              name: "",
                              date: DateTime.now(),
                              locations: [null]));
                        });
                      },
                    );
                  }
                  return _buildDayCard(days[index], index);
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.check),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OverviewItinerary(
              days: days,
              itineraryName: _itineraryNameController.text,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDayCard(ItineraryDay day, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            if (index > 0)
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () {
                    setState(() {
                      days.removeAt(index);
                    });
                  },
                ),
              ),
            Text('Day ${index + 1}',
                style:
                    const TextStyle(fontSize: 50, fontWeight: FontWeight.bold)),
            TextField(
              decoration: const InputDecoration(labelText: "Day Name"),
              onChanged: (value) {
                day.name = value;
              },
            ),
            ElevatedButton(
              onPressed: () => _selectDate(context, day),
              child: Text("${day.date.toLocal()}".split(' ')[0],
                  style: const TextStyle(fontSize: 18)),
            ),
            ElevatedButton(
              onPressed: () async {
                selectedCategory = await showDialog<String>(
                  context: context,
                  builder: (BuildContext context) => SimpleDialog(
                    title: const Text('Good Day, What are your plans?'),
                    children: <Widget>[
                      SimpleDialogOption(
                        onPressed: () {
                          Navigator.pop(context, 'restaurant');
                        },
                        child: const Text('Restaurants'),
                      ),
                      SimpleDialogOption(
                        onPressed: () {
                          Navigator.pop(context, 'park');
                        },
                        child: const Text('Parks'),
                      ),
                    ],
                  ),
                );
                if (selectedCategory != null) {
                  Position? position = await getCurrentLocation();
                  if (position != null) {
                    double lat = position.latitude;
                    double lng = position.longitude;
                    List<Location> newFetchedLocations =
                        await fetchNearbyPlaces(lat, lng, selectedCategory!);

                    setState(() {
                      if (selectedCategory == 'restaurant') {
                        day.fetchedLocationsRestaurants = newFetchedLocations;
                      } else if (selectedCategory == 'park') {
                        day.fetchedLocationsParks = newFetchedLocations;
                      }
                      // ... add more conditions for other categories

                      if (newFetchedLocations.isNotEmpty) {
                        day.locations.add(newFetchedLocations[0]);
                      }
                    });
                  }
                }
              },
              child: Text(
                selectedCategory ?? "Good Day, What are your plans?",
                style: const TextStyle(fontSize: 18),
              ),
            ),
            for (var i = 0; i < day.locations.length; i++)
              LocationDropdown(
                locations: day.locations[i] != null &&
                        day.locations[i]!.category == 'restaurant'
                    ? day.fetchedLocationsRestaurants
                    : day
                        .fetchedLocationsParks, // Change this logic based on your categories
                selectedLocation: day.locations[i],
                onChanged: (Location? newValue) {
                  setState(() {
                    day.locations[i] = newValue;
                  });
                },
                showRemoveButton: i > 0,
                onRemove: () {
                  setState(() {
                    day.locations.removeAt(i);
                  });
                },
              ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () async {
                selectedCategory = await showDialog<String>(
                  context: context,
                  builder: (BuildContext context) => SimpleDialog(
                    title: const Text('Not tired yet? Tara Lakbay!'),
                    children: <Widget>[
                      SimpleDialogOption(
                        onPressed: () {
                          Navigator.pop(context, 'restaurant');
                        },
                        child: const Text('Restaurants'),
                      ),
                      SimpleDialogOption(
                        onPressed: () {
                          Navigator.pop(context, 'park');
                        },
                        child: const Text('Parks'),
                      ),
                    ],
                  ),
                );
                if (selectedCategory != null) {
                  Position? position = await getCurrentLocation();
                  if (position != null) {
                    double lat = position.latitude;
                    double lng = position.longitude;
                    List<Location> newFetchedLocations =
                        await fetchNearbyPlaces(lat, lng, selectedCategory!);

                    // Remove duplicates
                    newFetchedLocations = newFetchedLocations.toSet().toList();

                    setState(() {
                      if (selectedCategory == 'restaurant') {
                        day.fetchedLocationsRestaurants = newFetchedLocations;

                        // Check if the location is not already in the day.locations before adding
                        if (newFetchedLocations.isNotEmpty &&
                            !day.locations.contains(newFetchedLocations[0])) {
                          day.locations.add(newFetchedLocations[0]);
                        }
                      } else if (selectedCategory == 'park') {
                        day.fetchedLocationsParks = newFetchedLocations;

                        // Check if the location is not already in the day.locations before adding
                        if (newFetchedLocations.isNotEmpty &&
                            !day.locations.contains(newFetchedLocations[0])) {
                          day.locations.add(newFetchedLocations[0]);
                        }
                      }
                      // ... You can add more conditions for other categories
                    });
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class LocationDropdown extends StatelessWidget {
  final List<Location> locations;
  final Location? selectedLocation;
  final ValueChanged<Location?> onChanged;
  final bool showRemoveButton;
  final VoidCallback onRemove;

  const LocationDropdown({
    super.key,
    required this.locations,
    required this.selectedLocation,
    required this.onChanged,
    required this.showRemoveButton,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    bool shouldShowDropdown = locations.isNotEmpty;
    return Visibility(
      visible: shouldShowDropdown,
      child: DropdownButton<Location>(
        value: selectedLocation,
        elevation: 16,
        underline: Container(
          height: 2,
        ),
        onChanged: onChanged,
        items: [
          if (locations != null) //WALA LAGI KO KASABOT ANI NA CONDITION
            ...locations.map<DropdownMenuItem<Location>>((Location location) {
              return DropdownMenuItem<Location>(
                value: location,
                child: Text(
                  '${location.name} - ${location.category}',
                ),
              );
            }).toList(),
        ],
      ),
    );
  }
}
