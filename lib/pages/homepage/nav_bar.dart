import 'package:flutter/material.dart';
import 'package:lakbayan/pages/homepage/home_page.dart';
import 'package:lakbayan/pages/search_page.dart';
import 'package:lakbayan/pages/notif_page.dart';
import 'package:lakbayan/pages/profile_page/profile_page.dart';

Widget customNavBar(BuildContext context, int currentIndex) {
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
          topLeft: Radius.circular(70),
          topRight: Radius.circular(70),
          bottomLeft: Radius.circular(70),
          bottomRight: Radius.circular(70)),
      child: Theme(
        data: Theme.of(context).copyWith(
          canvasColor: const Color(0xFFAD547F), // Setting the color here
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          iconSize: 80,
          onTap: (index) {
            if (index == 0) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
              );
            } else if (index == 1) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => NavigationPage()),
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
