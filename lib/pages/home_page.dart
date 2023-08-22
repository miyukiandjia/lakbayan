import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lakbayan/auth.dart';
import 'package:lakbayan/pages/itinerary_screen.dart';
import 'package:lakbayan/pages/search_page.dart';

class HomePage extends StatelessWidget {
  HomePage({Key? key}) : super(key: key);

  final User? user = Auth().currentUser;

  Future<void> signOut() async {
    await Auth().signOut();
  }

  String _getGreeting() {
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

    return greeting;
  }

  Widget _userUid() {
    return Text(user?.email ?? 'User email');
  }

  Widget _createItinerary(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ItineraryScreen()),
        );
      },
      child: const Text('+ Create Itinerary'),
    );
  }

  Widget _davaoImage() {
    return Image.asset(
      'lib/images/Davao_City_Logo.png',
      width: 80,
      height: 80,
    );
  }

  Widget _signOutButton() {
    return ElevatedButton(
      onPressed: signOut,
      child: const Text('Sign Out'),
    );
  }

  Widget _navBar(BuildContext context, int currentIndex) {
    return BottomNavigationBar(
      currentIndex: currentIndex, // Pass the current index of the selected icon
      iconSize: 90,
      onTap: (index) {
        if (index == 0) {
          // Navigate to the home page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomePage()),
          );
        } else if (index == 1) {
          // Navigate to the search page
          // Add similar code for other icons as needed
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const SearchPage()),
          );
        }
      },
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search),
          label: 'Search',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications),
          label: 'Notifications',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
      selectedLabelStyle: const TextStyle(
          color: Color(0xFFAD547F)), // Set label color when selected
      unselectedLabelStyle: const TextStyle(
          color:
              Color.fromARGB(255, 2, 2, 2)), // Set label color when unselected
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBar(
          backgroundColor: Colors.white,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getGreeting(),
                    style: const TextStyle(color: Colors.black),
                  ),
                  _userUid(),
                ],
              ),
              _createItinerary(context),
            ],
          ),
          iconTheme: const IconThemeData(color: Colors.black),
          titleTextStyle: const TextStyle(color: Colors.black),
        ),
      ),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _navBar(context, 0),
            _signOutButton(),
          ],
        ),
      ),
    );
  }
}
