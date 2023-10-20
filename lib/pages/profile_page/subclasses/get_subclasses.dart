import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class Location {
  final String name;
  final String category;
  final double latitude;
  final double longitude;

  Location(
      {required this.name,
      required this.category,
      required this.latitude,
      required this.longitude});

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
  int get hashCode =>
      name.hashCode ^
      category.hashCode ^
      latitude.hashCode ^
      longitude.hashCode;
}

class ItineraryDay {
  String name;
  DateTime date;
  List<Location> locations;

  ItineraryDay(
      {required this.name, required this.date, this.locations = const []});
}

class ItineraryDayWidget extends StatefulWidget {
  final ItineraryDay day;
  final VoidCallback selectDate;
  final VoidCallback removeDay;
  final Function(ItineraryDay, Location) removeLocation;
  final int totalDays;
  final Future<List<Location>> Function(double, double, String) searchLocations;

  const ItineraryDayWidget({
    super.key,
    required this.day,
    required this.selectDate,
    required this.removeDay,
    required this.removeLocation,
    required this.totalDays,
    required this.searchLocations,
  });

  @override
  // ignore: library_private_types_in_public_api
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
        const Text('Selected Locations'),
        for (var location in widget.day.locations)
          ListTile(
            title: Text(location.name),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
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

  const LocationSearchBar({
    super.key,
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
    List<Location> locations =
        await widget.searchLocations(lat, lng, _controller.text);
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
        SizedBox(
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
