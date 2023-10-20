import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

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

  const LocationSearchBar({super.key, 
    required this.day,
    required this.onLocationSelected,
    required this.searchLocations,
  });

  @override
  // ignore: library_private_types_in_public_api
  _LocationSearchBarState createState() => _LocationSearchBarState();
}

class _LocationSearchBarState extends State<LocationSearchBar> {
  final TextEditingController _controller = TextEditingController();
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
          decoration: const InputDecoration(
            labelText: 'Search Location',
          ),
          onChanged: (String text) {
            if (_debounce?.isActive ?? false) _debounce?.cancel();
            _debounce = Timer(const Duration(milliseconds: 500), () {
              _search();
            });
          },
        ),
        // ignore: sized_box_for_whitespace
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
