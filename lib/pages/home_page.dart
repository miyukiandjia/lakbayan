import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lakbayan/auth.dart';
import 'package:lakbayan/pages/create_itinerary_page.dart';
import 'package:lakbayan/pages/notif_page.dart';
import 'package:lakbayan/pages/profile_page.dart';
import 'package:lakbayan/pages/navigation_page.dart';

class HomePage extends StatelessWidget {
  HomePage({Key? key}) : super(key: key);

  final User? user = Auth().currentUser;

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
              loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                if (loadingProgress == null) {
                  return child;
                } else {
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes ?? 1)
                          : null,
                    ),
                  );
                }
              },
              errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
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
                  MaterialPageRoute(
                      builder: (context) => const ProfilePage()),
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

  Future<List<Map<String, dynamic>>> fetchFirestoreData() async {
    List<Map<String, dynamic>> destinations = [];

    QuerySnapshot<Map<String, dynamic>> querySnapshot =
        await FirebaseFirestore.instance.collection('datasets').get();

    for (var doc in querySnapshot.docs) {
      var data = doc.data();
      var name = data['place'] ?? 'Unknown Place';
      var category = data['category'] ?? 'Unknown Category';
      var gReviews = (data['gReviews'] != null) ? num.parse(data['gReviews'].toString()) : 0.0;
      var image = data['imgSrc'] ?? 'https://marketplace.canva.com/EAFWiQLDfT8/1/0/900w/canva-galaxy-phone-wallpaper--M6gJBJenQM.jpg';

      destinations.add({
        'name': name,
        'category': category,
        'gReviews': gReviews,
        'image': image,
      });
    }

    destinations.sort((a, b) => (b['gReviews'] as num).compareTo(a['gReviews'] as num));

    return destinations;
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
                future: fetchFirestoreData(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}', style: TextStyle(fontSize: 50),);
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
