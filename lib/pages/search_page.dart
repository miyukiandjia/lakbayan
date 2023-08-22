import 'package:flutter/material.dart';
import 'package:lakbayan/pages/home_page.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  Widget buttonni(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      },
      child: const Text('HomePage'),
    );
  }

  Widget _navBar(BuildContext context, int currentIndex) {
    return BottomNavigationBar(
      backgroundColor:
          const Color(0xFFAD547F), // Set background color to AD547F
      selectedItemColor: const Color(0x0000),
      unselectedItemColor:
          const Color(0xFFAD547F), // Set unselected icon color to F9CDDD
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
          color: Color.fromARGB(
              255, 255, 255, 255)), // Set label color when selected
      unselectedLabelStyle: const TextStyle(
          color: Color.fromARGB(
              255, 13, 13, 13)), // Set label color when unselected
    );
  }

  @override
  Widget build(BuildContext context) {
    // Implement your Create Itinerary screen UI here
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
                'Search Page ni'), // Remove "child: <Widget>[" as it's not needed
            _navBar(context,
                1), // Assuming buttonni is a function that returns a widget
          ],
        ),
      ),
    );
  }
}
