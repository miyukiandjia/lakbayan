import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lakbayan/auth.dart';
import 'package:lakbayan/pages/create_itinerary_page.dart';
import 'package:lakbayan/pages/notif_page.dart';
import 'package:lakbayan/pages/profile_page.dart';
import 'package:lakbayan/pages/navigation_page.dart';

// ignore: must_be_immutable
class HomePage extends StatelessWidget {
  HomePage({Key? key}) : super(key: key);

  final User? user = Auth().currentUser;

  // Sample itinerary data structure
  List<Map<String, dynamic>> itineraries = [
    {
      'user': 'John Doe',
      'location': 'Beach Resort',
      'image': 'lib/images/2.jpg'
    },
    {
      'user': 'Jane Smith',
      'location': 'Mountain Trek',
      'image': 'lib/images/3.jpg'
    },
    {
      'user': 'Jane Smith',
      'location': 'Mountain Trek',
      'image': 'lib/images/3.jpg'
    },
    {
      'user': 'Jane Smith',
      'location': 'Mountain Trek',
      'image': 'lib/images/3.jpg'
    },
    {
      'user': 'Jane Smith',
      'location': 'Mountain Trek',
      'image': 'lib/images/3.jpg'
    },
    {
      'user': 'Jane Smith',
      'location': 'Mountain Trek',
      'image': 'lib/images/3.jpg'
    },
    {
      'user': 'Jane Smith',
      'location': 'Mountain Trek',
      'image': 'lib/images/3.jpg'
    },
    {
      'user': 'Jane Smith',
      'location': 'Mountain Trek',
      'image': 'lib/images/3.jpg'
    },
    // ... Add more sample itineraries
  ];

  Future<void> signOut() async {
    await Auth().signOut();
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

    String email = user?.email ?? 'User email';
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
          email,
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
      child: Column(
        children: [
          Image.asset(itinerary['image'],
              width: double.infinity, height: 200, fit: BoxFit.cover),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(itinerary['user'] + ' at ' + itinerary['location']),
          ),
        ],
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
                      MaterialPageRoute(
                          builder: (context) => const NotifPage()),
                    );
                  } else if (index == 3) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ProfilePage()),
                    );
                  }
                },
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
            )));
  }

  Widget _davaoImage(BuildContext context) {
    double imageSize = MediaQuery.of(context).size.width * 0.30;

    return SizedBox(
      width: imageSize,
      height: imageSize,
      child: FittedBox(
        fit: BoxFit
            .cover, // This will ensure that the image covers the container.
        child: Image.asset('lib/images/dvo_logo.png'),
      ),
    );
  }

  List<Map<String, dynamic>> destinations = [
    {'name': 'Destination 1', 'image': 'lib/images/2.jpg'},
    {'name': 'Destination 2', 'image': 'lib/images/2.jpg'},
    {'name': 'Destination 3', 'image': 'lib/images/3.jpg'},
    {'name': 'Destination 4', 'image': 'lib/images/4.jpg'},
    {'name': 'Destination 5', 'image': 'lib/images/2.jpg'},
    {'name': 'Destination 6', 'image': 'lib/images/2.jpg'},
    {'name': 'Destination 7', 'image': 'lib/images/3.jpg'},
    {'name': 'Destination 8', 'image': 'lib/images/4.jpg'},
    // ... Add more destinations
  ];

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
          // This is your main content
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
                Container(
                  height: 400,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: destinations.map((destination) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 20),
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: Image.asset(
                                destination['image'],
                                width: 300,
                                height: 300,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              destination['name'],
                              style: const TextStyle(
                                  fontFamily: 'Nunito', fontSize: 30),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),
                for (var itinerary in itineraries) _itineraryCard(itinerary),
                Column(
                  children: <Widget>[
                    Card(
                      child: Container(
                        height: 350.0,
                        color: Colors.white,
                        child: Column(
                          children: <Widget>[
                            Text(
                              'News Feed',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 50,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const ListTile(
                              leading: CircleAvatar(),
                              title: Text(
                                "Patricia Anne Marie Go",
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 22,
                                  color: Colors.black,
                                ),
                              ),
                              subtitle: Text(
                                "Tue Oct 01 2019 12:50:14",
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                color: Colors.blue,
                                width: 650.0,
                                child: Column(
                                  children: <Widget>[
                                    Text("Itinerary goes here."),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 14.0,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    Icon(Icons.thumb_up),
                                    SizedBox(
                                      width: 8.0,
                                    ),
                                    Text("Like"),
                                  ],
                                ),
                                Row(
                                  children: <Widget>[
                                    Icon(Icons.comment),
                                    SizedBox(
                                      width: 8.0,
                                    ),
                                    Text("Comments"),
                                  ],
                                ),
                                Row(
                                  children: <Widget>[
                                    Icon(Icons.share),
                                    SizedBox(
                                      width: 8.0,
                                    ),
                                    Text("Share"),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
          // This will place your navBar at the bottom of the screen

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
