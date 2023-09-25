import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lakbayan/pages/overview_itinerary_page.dart';
import 'package:http/http.dart' as http;
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
  List<Location?> locations = [];
  List<Location> fetchedLocationsRestaurants = [];
  List<Location> fetchedLocationsParks = [];

  ItineraryDay({required this.name, required this.date});
}

class CreateItineraryPage extends StatefulWidget {
  const CreateItineraryPage({super.key});

  @override
  _CreateItineraryPageState createState() => _CreateItineraryPageState();
}

class _CreateItineraryPageState extends State<CreateItineraryPage> {
  List<Location> allLocations = [];
  List<ItineraryDay> days = [ItineraryDay(name: "", date: DateTime.now())];
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

  Future<void> addLocation(ItineraryDay day) async {
    selectedCategory = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => SimpleDialog(
        title: const Text('Select Category'),
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

        newFetchedLocations
            .removeWhere((location) => day.locations.contains(location));

        if (newFetchedLocations.isNotEmpty) {
          // Show a dropdown dialog for the user to select a location
          Location? selectedLocation = await showDialog<Location>(
            context: context,
            builder: (BuildContext context) => SimpleDialog(
              title: const Text('Select Location'),
              children: newFetchedLocations.map((Location location) {
                return SimpleDialogOption(
                    onPressed: () {
                      Navigator.pop(context, location);
                    },
                    child: Row(children: [
                      Text(location.name),
                    ]));
              }).toList(),
            ),
          );

          if (selectedLocation != null) {
            setState(() {
              day.locations.add(selectedLocation);
            });
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('No more locations available in this category')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Itinerary'),
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
                          days.add(
                              ItineraryDay(name: "", date: DateTime.now()));
                        });
                      },
                    );
                  } else {
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      padding: const EdgeInsets.all(8.0),
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
                      child: ItineraryDayWidget(
                        day: days[index],
                        addLocation: () => addLocation(days[index]),
                        selectDate: () => _selectDate(context, days[index]),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.forward),
        onPressed: () {
          if (_itineraryNameController.text.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter itinerary name!')));
            return;
          }
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => OverviewItinerary(
              days: days,
              itineraryName: _itineraryNameController.text,
            ),
          ));
        },
      ),
    );
  }

  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return Future.error('Location permissions are denied');
      }
    }

    return await Geolocator.getCurrentPosition();
  }
}

class ItineraryDayWidget extends StatelessWidget {
  final ItineraryDay day;
  final VoidCallback addLocation;
  final VoidCallback selectDate;

  ItineraryDayWidget(
      {required this.day, required this.addLocation, required this.selectDate});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: TextEditingController()..text = day.name,
                decoration: const InputDecoration(labelText: "Day Name"),
                onChanged: (value) {
                  day.name = value;
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.date_range),
              onPressed: selectDate,
            ),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: selectDate,
              //PLS CHANGE ONPRESSED------------------------!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
              //BTW WALA PAKO KA ADD SA CONDITION NA IF 1 PALANG MAG HIDE ANG ICON
            ),
          ],
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: day.locations.length + 1,
          itemBuilder: (context, index) {
            if (index == day.locations.length) {
              return IconButton(
                icon: const Icon(Icons.add_location),
                onPressed: addLocation,
              );
            } else {
              return LocationWidget(
                location: day.locations[index]!,
                // Pass the correct functions for removing or editing locations here
              );
            }
          },
        ),
      ],
    );
  }
}

class LocationWidget extends StatelessWidget {
  final Location location;

  LocationWidget({required this.location});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(location.name),
      // Implement other properties and functionalities for LocationWidget
    );
  }
}
