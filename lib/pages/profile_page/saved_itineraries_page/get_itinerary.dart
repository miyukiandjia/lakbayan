import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:lakbayan/pages/profile_page/subclasses/get_subclasses.dart';
import 'package:lakbayan/pages/profile_page/saved_itineraries_page/overview_get_itinerary_page.dart';
import 'dart:async';
import 'package:lakbayan/constants.dart';
export '../../home_page/itinerary/create_itinerary_page.dart';

class GetItineraryPage extends StatefulWidget {
  final Map<String, dynamic> itinerary;

  const GetItineraryPage({super.key, required this.itinerary});

  @override
  // ignore: library_private_types_in_public_api
  _GetItineraryPageState createState() => _GetItineraryPageState();
}

class _GetItineraryPageState extends State<GetItineraryPage> {
  List<ItineraryDay> days = [];
  final TextEditingController _itineraryNameController =
      TextEditingController();

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

  Future<List<Location>> searchLocations(
      double lat, double lng, String searchTerm) async {
    final url =
        "$BASE_URL?query=$searchTerm&location=$lat,$lng&radius=1500&key=AIzaSyDLgheGs44zc3Qe7LbPxZC-g7TObcZsS34";
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      Map<String, dynamic> jsonResponse = json.decode(response.body);
      return (jsonResponse['results'] as List).map((result) {
        final locationLat = result['geometry']['location']['lat'] as double;
        final locationLng = result['geometry']['location']['lng'] as double;
        return Location(
            name: result['name'],
            category: '',
            latitude: locationLat,
            longitude: locationLng);
      }).toList();
    } else {
      throw Exception("Failed to load locations");
    }
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

  void removeDay(int index) {
    setState(() {
      days.removeAt(index);
    });
  }

  void removeLocation(ItineraryDay day, Location location) {
    setState(() {
      day.locations.remove(location);
    });
  }

  @override
  void initState() {
    super.initState();
    // Load the saved locations from the passed itinerary into days list
    days = (widget.itinerary['days'] as List).map((day) {
      final locations = (day['locations'] as List).map((location) {
        return Location(
          name: location['name'],
          category: location['category'],
          latitude: location['latitude'],
          longitude: location['longitude'],
        );
      }).toList();

      return ItineraryDay(name: "", date: DateTime.now(), locations: locations);
    }).toList();
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
                          DateTime lastDate = days.last.date;
                          DateTime newDate =
                              lastDate.add(const Duration(days: 1));
                          days.add(ItineraryDay(name: "", date: newDate));
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
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ItineraryDayWidget(
                        day: days[index],
                        selectDate: () => _selectDate(context, days[index]),
                        removeDay: () => removeDay(index),
                        removeLocation: removeLocation,
                        totalDays: days.length,
                        searchLocations: searchLocations,
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
            builder: (context) => OverviewSharedPage(
              days: days,
              itineraryName: _itineraryNameController.text,
            ),
          ));
        },
      ),
    );
  }
}
