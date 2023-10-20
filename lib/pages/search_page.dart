import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_webservice/directions.dart' as gmaps;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:lakbayan/pages/home_page/home_page.dart';
import 'package:lakbayan/constants.dart';

final directions = gmaps.GoogleMapsDirections(apiKey: API_KEY);

class Location {
  final String name;
  final double latitude;
  final double longitude;
  final String category;
  final double rating;

  Location({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.category,
    required this.rating,
  });
}

class SelectedLocationDetails {
  final String name;
  final double
      distance; // You can compute this using the Haversine formula or get it from the API response.
  final String category; // Placeholder for now
  final double reviews; // Placeholder for now

  SelectedLocationDetails({
    required this.name,
    required this.distance,
    required this.category,
    required this.reviews,
  });
}

class NavigationPage extends StatefulWidget {
  @override
  _NavigationPageState createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  Future<Position>? _futurePosition;
  Map<String, double> distanceCache = {};
  GoogleMapController? mapController;
  TextEditingController _controller = TextEditingController();
  List<Location> _searchResults = [];
  Timer? _debounce;
  Set<Polyline> _polylines = {};
  LatLng? _selectedLocation;
  SelectedLocationDetails? _selectedLocationDetails;

  @override
  void initState() {
    super.initState();
    _futurePosition = fetchUserLocation();
  }

  Future<Position> fetchUserLocation() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Failed to get user location: $e');
      throw e;
    }
  }

  Future<List<Location>> searchLocations(
      double lat, double lng, String searchTerm) async {
    final url =
        "$BASE_URL?query=$searchTerm&location=$lat,$lng&radius=1500&key=AIzaSyAXRlk4WJ4sqmtMArNRHBwIK1bmj7fYZao";
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      Map<String, dynamic> jsonResponse = json.decode(response.body);
      return (jsonResponse['results'] as List).map((result) {
        final locationLat = result['geometry']['location']['lat'] as double;
        final locationLng = result['geometry']['location']['lng'] as double;
        String primaryCategory = 'Unknown'; // Default value
        if (result['types'] is List && result['types'].length > 0) {
          primaryCategory = result['types'][0];
        }
        double rating =
            (result['rating'] != null) ? result['rating'].toDouble() : 0.0;
        return Location(
          name: result['name'],
          latitude: locationLat,
          longitude: locationLng,
          category: primaryCategory,
          rating: rating,
        );
      }).toList();
    } else {
      throw Exception("Failed to load locations");
    }
  }

  void _search() async {
    if (_controller.text.isEmpty) {
      setState(() {
        _searchResults.clear();
      });
      return;
    }

    if (_futurePosition != null) {
      Position position = await _futurePosition!;
      List<Location> locations = await searchLocations(
          position.latitude, position.longitude, _controller.text);
      setState(() {
        _searchResults = locations;
      });
    }
  }

  Future<void> _calculateRoute(LatLng destination) async {
    if (_futurePosition != null) {
      Position position = await _futurePosition!;
      await _updateCameraBounds(
          LatLng(position.latitude, position.longitude), destination);
      LatLng origin = LatLng(position.latitude, position.longitude);

      gmaps.DirectionsResponse response = await directions.directions(
        gmaps.Location(lat: origin.latitude, lng: origin.longitude),
        gmaps.Location(lat: destination.latitude, lng: destination.longitude),
        travelMode: gmaps.TravelMode.driving,
      );

      if (response.status == 'OK') {
        PolylinePoints polylinePoints = PolylinePoints();
        var points = polylinePoints
            .decodePolyline(response.routes[0].overviewPolyline.points);
        List<LatLng> polylineCoordinates = points
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();

        Polyline polyline = Polyline(
          polylineId: PolylineId('route_1'),
          color: Colors.pink,
          points: polylineCoordinates,
          width: 5,
        );

        setState(() {
          _polylines.clear();
          _polylines.add(polyline);
        });
      } else {
        print("Error");
      }
    }
  }

  Future<void> _updateCameraBounds(LatLng origin, LatLng destination) async {
    if (mapController != null) {
      LatLngBounds bounds;

      if (origin.latitude > destination.latitude &&
          origin.longitude > destination.longitude) {
        bounds = LatLngBounds(southwest: destination, northeast: origin);
      } else if (origin.longitude > destination.longitude) {
        bounds = LatLngBounds(
          southwest: LatLng(origin.latitude, destination.longitude),
          northeast: LatLng(destination.latitude, origin.longitude),
        );
      } else if (origin.latitude > destination.latitude) {
        bounds = LatLngBounds(
          southwest: LatLng(destination.latitude, origin.longitude),
          northeast: LatLng(origin.latitude, destination.longitude),
        );
      } else {
        bounds = LatLngBounds(southwest: origin, northeast: destination);
      }

      CameraUpdate cameraUpdate =
          CameraUpdate.newLatLngBounds(bounds, 50); // 50 is padding
      await mapController!.animateCamera(cameraUpdate);
    }
  }

  Future<double> calculateDistance(LatLng start, LatLng destination) async {
    double distanceInMeters = 0.0;

    gmaps.DirectionsResponse response = await directions.directions(
      gmaps.Location(lat: start.latitude, lng: start.longitude),
      gmaps.Location(lat: destination.latitude, lng: destination.longitude),
      travelMode: gmaps.TravelMode.driving,
    );

    if (response.status == 'OK' && response.routes.isNotEmpty) {
      distanceInMeters =
          (response.routes[0].legs[0].distance.value as num).toDouble();
    }

    return distanceInMeters / 1000; // Convert meters to kilometers
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FutureBuilder<Position>(
            future: _futurePosition,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done &&
                  snapshot.hasData) {
                return GoogleMap(
                  onMapCreated: (controller) {
                    mapController = controller;
                    if (snapshot.data != null) {
                      mapController?.moveCamera(CameraUpdate.newLatLng(LatLng(
                          snapshot.data!.latitude, snapshot.data!.longitude)));
                    }
                  },
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                        snapshot.data!.latitude, snapshot.data!.longitude),
                    zoom: 15.0,
                  ),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  polylines: _polylines,
                );
              } else {
                // Placeholder widget until the current position is fetched
                return Center(child: CircularProgressIndicator());
              }
            },
          ),
          Positioned(
            top: 50.0,
            left: 20.0,
            right: 20.0,
            child: Column(
              children: [
                Row(
                  children: [
                    // Add the back button
                    IconButton(
                      icon: Icon(Icons.arrow_back),
                      onPressed: () {
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => HomePage()));
                      },
                    ),

                    // Add some horizontal spacing
                    SizedBox(width: 10),

                    // The search bar
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          labelText: 'Search Location',
                          fillColor: Colors.white,
                          filled: true,
                        ),
                        onChanged: (String text) {
                          if (_debounce?.isActive ?? false) _debounce?.cancel();
                          _debounce =
                              Timer(const Duration(milliseconds: 500), _search);
                        },
                      ),
                    ),
                  ],
                ),
                Container(
                  height: 200.0,
                  child: ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) => GestureDetector(
                      onTap: () async {
                        String selectedLocationName =
                            _searchResults[index].name;
                        LatLng selectedLatLng = LatLng(
                            _searchResults[index].latitude,
                            _searchResults[index].longitude);
                        String locationCategory =
                            _searchResults[index].category;
                        double locationRating = _searchResults[index].rating;

                        FocusScope.of(context).requestFocus(new FocusNode());

                        if (mapController != null) {
                          mapController!.moveCamera(
                            CameraUpdate.newLatLng(selectedLatLng),
                          );
                        }

                        await _calculateRoute(selectedLatLng);

                        // Calculate distance between current position and selected location
                        double distanceKm = 0.0;
                        if (_futurePosition != null) {
                          Position position = await _futurePosition!;
                          distanceKm = await calculateDistance(
                              LatLng(position.latitude, position.longitude),
                              selectedLatLng);
                        }

                        setState(() {
                          _selectedLocation = selectedLatLng;
                          _searchResults.clear();
                          _controller.clear();
                          _selectedLocationDetails = SelectedLocationDetails(
                            name: selectedLocationName,
                            distance: distanceKm,
                            category: locationCategory,
                            reviews: locationRating,
                          );
                        });

                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('$selectedLocationName selected'),
                        ));
                      },
                      child: ListTile(
                        title: Text(_searchResults[index].name),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_selectedLocationDetails != null)
            Positioned(
              bottom: 20.0,
              left: 20.0,
              right: 20.0,
              child: Card(
                elevation: 8.0,
                child: Container(
                  height: 400.0, // Set the height of the card as desired
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text('Name: ${_selectedLocationDetails!.name}',
                            style: TextStyle(
                                fontSize:
                                    20.0)), // Set the font size as desired
                        Text(
                            'Distance: ${_selectedLocationDetails!.distance} km',
                            style: TextStyle(fontSize: 20.0)),
                        Text('Category: ${_selectedLocationDetails!.category}',
                            style: TextStyle(fontSize: 20.0)),
                        Text('Reviews: ⭐️ ${_selectedLocationDetails!.reviews}',
                            style: TextStyle(fontSize: 20.0)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
