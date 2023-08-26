import 'package:flutter/material.dart';
import 'package:lakbayan/pages/home_page.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  Widget _navBar(BuildContext context, int currentIndex) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: FractionallySizedBox(
        widthFactor:
            0.9, // Adjust this value between 0 and 1 to set the desired width
        child: Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(30)),
            boxShadow: [
              BoxShadow(
                color: Colors.black38,
                spreadRadius: 0,
                blurRadius: 10,
              ),
            ],
          ),
          margin: const EdgeInsets.only(
              bottom: 80), // Adjust this value to change the bottom spacing
          child: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(30)),
            child: Theme(
              data: Theme.of(context).copyWith(
                canvasColor: const Color(0xFFAD547F),
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
                          builder: (context) => const SearchPage()),
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
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Implement your Create Itinerary screen UI here
    return Scaffold(
      body: Container(
        height: double.infinity,
        width: double.infinity,
        padding: const EdgeInsets.all(20),
      ),
      bottomNavigationBar: _navBar(context, 1),
    );
  }
}
