import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';  // <- Import Firestore
import 'package:geocoding/geocoding.dart' as geo;
import 'package:lakbayan/auth.dart';
import 'package:lakbayan/pages/create_itinerary_page.dart';
import 'package:lakbayan/pages/login_register_page.dart';
import 'package:lakbayan/pages/notif_page.dart';
import 'package:lakbayan/pages/profile_page.dart';
import 'package:lakbayan/pages/navigation_page.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class HomePage extends StatefulWidget {
  HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final User? user = Auth().currentUser;
  String? username;  // <- Add the username field

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  _checkAuthentication() async {
    final user = Auth().currentUser;

    if (user == null) {
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginPage()),
        );
    } else {
        // Fetch the username from Firestore
        final docSnapshot = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        setState(() {
            username = docSnapshot.data()?['username'];
        });
    }
  }

   Future<List<Map<String, dynamic>>> fetchNearbyDestinations() async {
    const API_KEY = 'AIzaSyDMxSHLjuBE_QPy6OoJ1EPqpDsBCJ32Rr0'; 
    Position? position = await getCurrentLocation();
    if (position == null) {
        position = Position(
        latitude: 7.1907, 
        longitude: 125.4553, 
        timestamp: DateTime.now(),
        accuracy: 0.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0
      );  // Default to Davao coordinates if location fetch fails.

    }

  List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(position.latitude, position.longitude);
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

    final url = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$lat,$lng&radius=10000&type=tourist_attraction&key=$API_KEY";
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      var jsonResponse = json.decode(response.body);
      List<Map<String, dynamic>> destinations = [];

      for (var result in jsonResponse['results']) {
      double distance = Geolocator.distanceBetween(position.latitude, position.longitude, result['geometry']['location']['lat'], result['geometry']['location']['lng']);
        distance = distance / 1000;

        destinations.add({
          'name': result['name'] ?? 'Unknown Place',
          'category': result['types'][0] ?? 'Unknown Category',
          'gReviews': result['user_ratings_total'] ?? 0.0,
          'image': "https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=${result['photos']?[0]['photo_reference']}&key=$API_KEY",
          'distance': distance.toStringAsFixed(2),
        });
      }

      destinations.sort((a, b) => (b['gReviews'] as num).compareTo(a['gReviews']));
      return destinations;
    } else {
      throw Exception("Failed to load destinations");
    }
  }

  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Location services are disabled.');
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      print('Location permissions are permanently denied, we cannot request permissions.');
      return null;
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) {
        print('Location permissions are denied (actual value: $permission).');
        return null;
      }
    }

    return await Geolocator.getCurrentPosition();
  }

  Widget _userInfo(BuildContext context) {
    var now = DateTime.now();
    var timeOfDay = now.hour;
    String greeting;

    if (timeOfDay >= 0 && timeOfDay < 12) {
        greeting = 'Good morning,';
    } else if (timeOfDay >= 12 && timeOfDay < 17) {
        greeting = 'Good afternoon,';
    } else {
        greeting = 'Good evening,';
    }

    String nameToShow = username ?? 'User';  // Show 'User' as default if username is not available

    double fontSize = MediaQuery.of(context).size.width * 0.03;

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Text(
                greeting,
                style: TextStyle(
                    fontSize: fontSize,
                ),
            ),
            Text(
                nameToShow,
                style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                ),
            ),
        ],
    );
  }

  Widget _createItinerary(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CreateItineraryPage()),
        );
      },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: const Text(
        '+ Create Itinerary',
        style: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _itineraryCard(Map<String, dynamic> itinerary) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      child: Container(
        padding: const EdgeInsets.all(20), // Add padding for content
        decoration: BoxDecoration(
          color: Colors.pink, // Set container color
          borderRadius: BorderRadius.circular(15), // Add rounded corners
        ),
        child: Column(
          children: [
            Container(
              width: 200,
              height: 200,
              child: Image.network(
                itinerary['image'],
                fit: BoxFit.cover,
                loadingBuilder: (BuildContext context, Widget child,
                    ImageChunkEvent? loadingProgress) {
                  if (loadingProgress == null) {
                    return child;
                  } else {
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                (loadingProgress.expectedTotalBytes ?? 1)
                            : null,
                      ),
                    );
                  }
                },
                errorBuilder: (BuildContext context, Object error,
                    StackTrace? stackTrace) {
                  return Center(
                    child: Text('Error loading image'),
                  );
                },
              ),
            ),
            const SizedBox(height: 10), // Add some space
            Text(
              itinerary['name'],
              style: TextStyle(
                fontSize: 35,
                fontWeight: FontWeight.bold,
                color: Colors.white, // Set text color
              ),
            ),
            const SizedBox(height: 10), // Add some space
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.star,
                  color: Colors.yellow, // Set star color
                  size: 30,
                ),
                Text(
                  '${itinerary['gReviews']}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // Set text color
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10), // Add some space
            Text(
              '${itinerary['distance']} km', // Assuming distance is in kilometers
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white, // Set text color
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navBar(BuildContext context, int currentIndex) {
    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black38, spreadRadius: 0, blurRadius: 10),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(40),
            topRight: Radius.circular(40),
            bottomLeft: Radius.circular(40),
            bottomRight: Radius.circular(40)),
        child: Theme(
          data: Theme.of(context).copyWith(
            canvasColor: const Color(0xFFAD547F), // Setting the color here
          ),
          child: BottomNavigationBar(
            currentIndex: currentIndex,
            iconSize: 90,
            onTap: (index) {
              if (index == 0) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => HomePage()),
                );
              } else if (index == 1) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const NavigationPage()),
                );
              } else if (index == 2) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const NotifPage()),
                );
              } else if (index == 3) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                );
              }
            },
            type: BottomNavigationBarType.fixed,
            items: <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: currentIndex == 0
                    ? const CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 50,
                        child: Icon(Icons.home, size: 50))
                    : const Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: currentIndex == 1
                    ? const CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 50,
                        child: Icon(Icons.search, size: 50))
                    : const Icon(Icons.search),
                label: 'Search',
              ),
              BottomNavigationBarItem(
                icon: currentIndex == 2
                    ? const CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 50,
                        child: Icon(Icons.notifications, size: 50))
                    : const Icon(Icons.notifications),
                label: 'Notifications',
              ),
              BottomNavigationBarItem(
                icon: currentIndex == 3
                    ? const CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 50,
                        child: Icon(Icons.person, size: 50))
                    : const Icon(Icons.person),
                label: 'Profile',
              ),
            ],
            selectedLabelStyle: const TextStyle(color: Color(0xFFAD547F)),
            unselectedLabelStyle:
                const TextStyle(color: Color.fromARGB(255, 2, 2, 2)),
          ),
        ),
      ),
    );
  }

  Widget _davaoImage(BuildContext context) {
    double imageSize = MediaQuery.of(context).size.width * 0.30;

    return SizedBox(
      width: imageSize,
      height: imageSize,
      child: FittedBox(
        fit: BoxFit.cover,
        child: Image.asset('lib/images/dvo_logo.png'),
      ),
    );
  }

    @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0.0,
        bottomOpacity: 0.0,
        toolbarHeight: 90,
        backgroundColor: Colors.white,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _userInfo(context),
            _createItinerary(context),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(color: Colors.black),
      ),
      body: Stack(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: ListView(
              children: <Widget>[
                Center(child: _davaoImage(context)),
                const SizedBox(height: 20),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Popular Destinations',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 50,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: fetchNearbyDestinations(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return Text(
                        'Error: ${snapshot.error}',
                        style: TextStyle(fontSize: 50),
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Text('No popular destinations available.');
                    } else {
                      final destinations = snapshot.data!;
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: destinations.map((destination) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 20),
                              child: _itineraryCard(destination),
                            );
                          }).toList(),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _navBar(context, 0),
          ),
        ],
      ),
    );
  }
}
