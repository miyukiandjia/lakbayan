import 'dart:convert';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:lakbayan/pages/home_page/pop_destination/current_loc.dart';
import 'package:lakbayan/constants.dart';

Future<List<Map<String, dynamic>>> fetchNearbyDestinations() async {
  Position? position = await getCurrentLocation();
  if (position == null) {
    // ignore: avoid_print
    print("Location fetch fails, Davao coordinates are currently used.");
    position = Position(
        latitude: 7.1907,
        longitude: 125.4553,
        timestamp: DateTime.now(),
        accuracy: 0.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy:
            0.0); // Default to Davao coordinates if location fetch fails.
  }

  List<geo.Placemark> placemarks =
      await geo.placemarkFromCoordinates(position.latitude, position.longitude);
  if (placemarks.isEmpty) {
    return [];
  }

  String? cityName = placemarks[0].locality;
  if (cityName == null) {
    return [];
  }

  List<geo.Location> locations = await geo.locationFromAddress(cityName);
  if (locations.isEmpty) {
    return [];
  }

  double lat = locations[0].latitude;
  double lng = locations[0].longitude;

  final url =
      "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$lat,$lng&radius=10000&type=tourist_attraction&key=$API_KEY";
  final response = await http.get(Uri.parse(url));

  if (response.statusCode == 200) {
    var jsonResponse = json.decode(response.body);
    List<Map<String, dynamic>> destinations = [];

    for (var result in jsonResponse['results']) {
      double distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          result['geometry']['location']['lat'],
          result['geometry']['location']['lng']);
      distance = distance / 1000;

      destinations.add({
        'name': result['name'] ?? 'Unknown Place',
        'category': result['types'][0] ?? 'Unknown Category',
        'gReviews': result['user_ratings_total'] ?? 0.0,
        'image':
            "https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=${result['photos']?[0]['photo_reference']}&key=$API_KEY",
        'distance': distance.toStringAsFixed(2),
      });
    }

    destinations
        .sort((a, b) => (b['gReviews'] as num).compareTo(a['gReviews']));
    return destinations;
  } else {
    throw Exception("Failed to load destinations");
  }
}
