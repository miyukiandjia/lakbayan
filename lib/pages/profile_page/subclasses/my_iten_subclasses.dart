//   import 'dart:convert';
// import 'dart:ui';

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_polyline_points/flutter_polyline_points.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:http/http.dart' as http;
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:google_maps_webservice/directions.dart' as gmaps;
// import 'package:lakbayan/constants.dart';
// import 'package:lakbayan/pages/home_page/itinerary/edit_itinerary_page.dart';
// import 'package:lakbayan/pages/profile_page/my_itineraries_page.dart';
// import 'package:lakbayan/pages/profile_page/subclasses/enhanced_annealing.dart';

// final List<Color> colorsSequence = [Colors.blue, Colors.green, Colors.red];
//   // Map<String, double> distanceCache = {};

//   Future<List<Location>> fetchNearbyLocations(String category) async {
//     List<Location> locations = [];
//     try {
//       Position position = await Geolocator.getCurrentPosition(
//           desiredAccuracy: LocationAccuracy.high);
//       final response = await http.get(Uri.parse(
//           '$BASE_URL?location=${position.latitude},${position.longitude}&radius=5000&type=$category&key=$API_KEY'));

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         final results = data['results'] as List<dynamic>;
//         for (var result in results) {
//           final name = result['name'] ?? '';
//           final latitude = result['geometry']['location']['lat'];
//           final longitude = result['geometry']['location']['lng'];
//           locations.add(Location(
//               name: name,
//               category: category,
//               latitude: latitude,
//               longitude: longitude));
//         }
//       } else {
//         // ignore: use_build_context_synchronously
//         ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Failed to load locations')));
//       }
//     } catch (e) {
//       // ignore: use_build_context_synchronously
//       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
//           content: Text(
//               'An error occurred. Please check your location permissions.')));
//     }
//     return locations;
//   }

//   Stream<QuerySnapshot> _getItinerariesByStatus(String status) {
//     User? currentUser = FirebaseAuth.instance.currentUser;
//     if (currentUser != null) {
//       String uid = currentUser.uid;
//       return FirebaseFirestore.instance
//           .collection('users')
//           .doc(uid)
//           .collection('itineraries')
//           .where('status', isEqualTo: status)
//           .snapshots();
//     } else {
//       ScaffoldMessenger.of(context)
//           .showSnackBar(const SnackBar(content: Text('User not logged in')));
//       return const Stream<QuerySnapshot>.empty();
//     }
//   }

//   void _showEditDialog(Map<String, dynamic> itinerary, String status) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text('Edit Itinerary'),
//           content: const Text('Do you want to edit this itinerary?'),
//           actions: <Widget>[
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop(); // Close the dialog
//               },
//               child: const Text('Cancel'),
//             ),
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop(); // Close the dialog
//                 // Navigate to the EditItineraryPage if the user confirms
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) =>
//                         EditItineraryPage(itinerary: itinerary),
//                   ),
//                 );
//               },
//               child: const Text('Edit'),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   Future<void> _deleteItinerary(Map<String, dynamic> itinerary) async {
//     DocumentReference docRef = itinerary['docRef'] as DocumentReference;
//     await docRef.delete();
//     // ignore: use_build_context_synchronously
//     Navigator.of(context).pop(); // Close the delete confirmation dialog

//     // Navigate back to the ItinerariesPage
//     // ignore: use_build_context_synchronously
//     Navigator.of(context).pushAndRemoveUntil(
//       MaterialPageRoute(builder: (context) => const ItinerariesPage()),
//       (Route<dynamic> route) => false,
//     );
//   }

//   Future<Map<String, dynamic>> _calculateRoute(
//       List<LatLng> polylineCoordinates) async {
//     EnhancedSimulatedAnnealing annealingOptimizer =
//         EnhancedSimulatedAnnealing();
//     List<Location> locations = polylineCoordinates
//         .map((coord) => Location(
//             name: 'Unknown',
//             category: 'Unknown',
//             latitude: coord.latitude,
//             longitude: coord.longitude))
//         .toList();

//     List<Location> optimizedLocations = await annealingOptimizer
//         .simulatedAnnealingOptimization(locations, useReheat: true);

//     List<LatLng> optimizedCoordinates = optimizedLocations
//         .map((loc) => LatLng(loc.latitude, loc.longitude))
//         .toList();
//     List<Polyline> polylines = [];
//     List<Color> usedColors = [];

//     for (int i = 0; i < optimizedCoordinates.length - 1; i++) {
//       LatLng from = optimizedCoordinates[i];
//       LatLng to = optimizedCoordinates[i + 1];

//       gmaps.DirectionsResponse response = await directions.directions(
//         gmaps.Location(lat: from.latitude, lng: from.longitude),
//         gmaps.Location(lat: to.latitude, lng: to.longitude),
//         travelMode: gmaps.TravelMode.driving,
//       );

//       if (response.status == 'OK') {
//         PolylinePoints polylinePoints = PolylinePoints();
//         var points = polylinePoints
//             .decodePolyline(response.routes[0].overviewPolyline.points);
//         List<LatLng> segmentPoints = points
//             .map((point) => LatLng(point.latitude, point.longitude))
//             .toList();

//         Color polylineColor = colorsSequence[i % colorsSequence.length];
//         usedColors.add(polylineColor);

//         Polyline polyline = Polyline(
//           polylineId: PolylineId('route_$i'),
//           color: polylineColor,
//           points: segmentPoints,
//           width: 5,
//         );

//         polylines.add(polyline);
//       } else {
//         // ignore: avoid_print
//         print("Error");
//       }
//     }

//     return {
//       "polylines": polylines,
//       "colors": usedColors,
//     };
//   }

//   double getHueFromColor(Color color) {
//     HSLColor hslColor = HSLColor.fromColor(color);
//     return hslColor.hue;
//   }

//   Set<Marker> _generateMarkers(List<LatLng> coordinates, List<Color> colors) {
//     Set<Marker> markers = {};

//     for (int i = 0; i < coordinates.length; i++) {
//       final coordinate = coordinates[i];

//       markers.add(
//         Marker(
//           markerId: MarkerId('location_$i'),
//           position: coordinate,
//           icon:
//               BitmapDescriptor.defaultMarkerWithHue(getHueFromColor(colors[i])),
//         ),
//       );
//     }

//     return markers;
//   }