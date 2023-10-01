import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:lakbayan/pages/overview_itinerary_page.dart';
import 'dart:async'; 
const BASE_URL = "https://maps.googleapis.com/maps/api/place/textsearch/json";

class Location {
  final String name;
  final String category;
  final double latitude;
  final double longitude;

  Location({
    required this.name, 
    required this.category,
    required this.latitude, 
    required this.longitude
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Location &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          category == other.category &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode => name.hashCode ^ category.hashCode ^ latitude.hashCode ^ longitude.hashCode;
}


class ItineraryDay {
  String name;
  DateTime date;
  List<Location> locations = [];

  ItineraryDay({required this.name, required this.date});
}

class CreateItineraryPage extends StatefulWidget {
  const CreateItineraryPage({Key? key}) : super(key: key);

  @override
  _CreateItineraryPageState createState() => _CreateItineraryPageState();
}

class _CreateItineraryPageState extends State<CreateItineraryPage> {
  List<ItineraryDay> days = [ItineraryDay(name: "", date: DateTime.now())];
  final TextEditingController _itineraryNameController = TextEditingController();

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

 Future<List<Location>> searchLocations(double lat, double lng, String searchTerm) async {
  final url = "$BASE_URL?query=$searchTerm&location=$lat,$lng&radius=1500&key=AIzaSyDMxSHLjuBE_QPy6OoJ1EPqpDsBCJ32Rr0";
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
        longitude: locationLng
      );
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
                          DateTime newDate = lastDate.add(Duration(days: 1));
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
                            offset: Offset(0, 3),
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
            builder: (context) => OverviewItinerary(
              days: days,
              itineraryName: _itineraryNameController.text,
            ),
          ));
        },
      ),
    );
  }
}

class ItineraryDayWidget extends StatefulWidget {
  final ItineraryDay day;
  final VoidCallback selectDate;
  final VoidCallback removeDay;
  final Function(ItineraryDay, Location) removeLocation;
  final int totalDays;
  final Future<List<Location>> Function(double, double, String) searchLocations;

  ItineraryDayWidget({
    required this.day,
    required this.selectDate,
    required this.removeDay,
    required this.removeLocation,
    required this.totalDays,
    required this.searchLocations,
  });

  @override
  _ItineraryDayWidgetState createState() => _ItineraryDayWidgetState();
}

class _ItineraryDayWidgetState extends State<ItineraryDayWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: TextEditingController()..text = widget.day.name,
                decoration: const InputDecoration(labelText: "Day Name"),
                onChanged: (value) {
                  widget.day.name = value;
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.date_range),
              onPressed: widget.selectDate,
            ),
            if (widget.totalDays > 1)
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: widget.removeDay,
              ),
          ],
        ),
        LocationSearchBar(
          day: widget.day,
          onLocationSelected: (Location location) {
            setState(() {
              widget.day.locations.add(location);
            });
          },
          searchLocations: widget.searchLocations,
        ),
        // Display the selected locations
        Text('Selected Locations'),
        for (var location in widget.day.locations)
          ListTile(
            title: Text(location.name),
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                setState(() {
                  widget.removeLocation(widget.day, location);
                });
              },
            ),
          ),
      ],
    );
  }
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
