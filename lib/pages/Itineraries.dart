import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lakbayan/pages/home_page.dart';
import 'package:lakbayan/search_page.dart';
import 'package:lakbayan/pages/profile_page.dart';

class Itineraries extends StatefulWidget {
  @override
  _ItinerariesState createState() => _ItinerariesState();
}

class _ItinerariesState extends State<Itineraries> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late User loggedInUser;
  int? selectedCardIndex;

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  void getCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        loggedInUser = user;
        print('Logged In User UID: ${loggedInUser.uid}');
      }
    } catch (e) {
      print(e);
    }
  }

  Future<List<DocumentSnapshot>> getUserItineraries() async {
    try {
      CollectionReference itinerariesCollection = _firestore
          .collection('users')
          .doc(loggedInUser.uid)
          .collection('itineraries');
      QuerySnapshot querySnapshot = await itinerariesCollection.get();

      print('Number of itineraries fetched: ${querySnapshot.docs.length}');
      for (DocumentSnapshot doc in querySnapshot.docs) {
        print('Itinerary ID: ${doc.id}, Data: ${doc.data()}');
      }

      return querySnapshot.docs;
    } catch (e) {
      print("Error in getUserItineraries: $e");
      return []; // Return an empty list in case of error
    }
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
                          builder: (context) => const SearchPage()),
                    );
                  } else if (index == 2) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => Itineraries()),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          setState(() {
            selectedCardIndex = null;
          });
        },
        child: FutureBuilder(
          future: getUserItineraries(),
          builder: (context, AsyncSnapshot<List<DocumentSnapshot>> snapshot) {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final itinerary = snapshot.data![index];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedCardIndex =
                          selectedCardIndex == index ? null : index;
                    });
                  },
                  child: ItineraryCard(
                    itinerary: itinerary,
                    showButtons: selectedCardIndex == index,
                    firestore: _firestore,
                    loggedInUser: loggedInUser, // Pass the loggedInUser here
                  ),
                );
              },
            );
          },
        ),
      ),
      bottomNavigationBar: _navBar(context, 2),
    );
  }
}

class ItineraryCard extends StatefulWidget {
  final DocumentSnapshot itinerary;
  final bool showButtons;
  final FirebaseFirestore firestore;
  final User loggedInUser; // Add this

  ItineraryCard({
    required this.itinerary,
    required this.showButtons,
    required this.firestore,
    required this.loggedInUser, // And this
  });

  @override
  _ItineraryCardState createState() => _ItineraryCardState();
}

class _ItineraryCardState extends State<ItineraryCard> {
  List<bool>? checkboxes;

  @override
  void initState() {
    super.initState();
    int locationsCount = 0;
    List days = widget.itinerary['days'] ?? [];
    days.forEach((day) {
      locationsCount += (day['locations'] as List).length;
    });
    checkboxes = List<bool>.generate(locationsCount, (index) => false);
  }

  void saveStatuses() async {
    try {
      List<dynamic> days = widget.itinerary['days'] ?? [];
      int currentCheckboxIndex = 0;

      for (var day in days) {
        for (var location in day['locations']) {
          if (checkboxes![currentCheckboxIndex]) {
            location['status'] = 'Done';
          }
          currentCheckboxIndex++;
        }
      }

      // Update Firestore with the modified itinerary
      await widget.itinerary.reference.update({'days': days});
    } catch (e) {
      print("Error in ItineraryCard's saveStatuses: $e");
    }
  }

  void saveChangesToFirestore() {
    var days = widget.itinerary['days'] ?? [];
    int currentCheckboxIndex = 0;

    for (var day in days) {
      for (var location in day['locations']) {
        if (checkboxes![currentCheckboxIndex]) {
          location['status'] = 'Done';
        }
        currentCheckboxIndex++;
      }
    }

    // Now, push these updated days to Firestore
    // Depending on your Firestore structure, you might push the whole itinerary or just updated days.
    final docRef = widget.firestore
        .collection('users')
        .doc(widget.loggedInUser.uid) // Use widget.loggedInUser here
        .collection('itineraries')
        .doc(widget.itinerary.id);

    docRef.update({'days': days});
  }

  @override
  Widget build(BuildContext context) {
    final days = widget.itinerary['days'] ?? [];
    int currentCheckboxIndex = 0;

    return Card(
      margin: EdgeInsets.all(10.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status: ${widget.itinerary['status']}',
              style: TextStyle(fontSize: 30.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12.0),
            ...days.map((day) {
              return Column(
                children: [
                  Text(
                    'Day Name: ${day['name']}',
                    style:
                        TextStyle(fontSize: 30.0, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10.0),
                  Text(
                    'Date: ${day['date'].toDate()}',
                    style: TextStyle(fontSize: 30.0),
                  ),
                  SizedBox(height: 12.0),
                  ...day['locations'].map<Widget>((location) {
                    Widget locationTile = ListTile(
                      leading: widget.showButtons
                          ? Checkbox(
                              value: checkboxes![currentCheckboxIndex],
                              onChanged: (value) {
                                print(
                                    'Current Checkbox Index: $currentCheckboxIndex');
                                if (value != null) {
                                  setState(() {
                                    checkboxes![currentCheckboxIndex] = value;
                                  });
                                }
                              },
                            )
                          : null,
                      title: Text(
                        'Location Name: ${location['name']} - Status: ${location['status']}',
                        style: TextStyle(fontSize: 30.0),
                      ),
                      subtitle: Text(
                        'Category: ${location['category']}',
                        style: TextStyle(fontSize: 25.0),
                      ),
                    );

                    currentCheckboxIndex++; // Increment the index after processing each location.
                    return locationTile;
                  }).toList(),
                  SizedBox(height: 20.0),
                ],
              );
            }).toList(),
            if (widget.showButtons)
              Row(
                children: [
                  ElevatedButton(
                      onPressed: () {
                        saveChangesToFirestore();
                      },
                      child: Text("Save")),
                  SizedBox(width: 10),
                  ElevatedButton(onPressed: () {}, child: Text("Edit")),
                ],
              )
          ],
        ),
      ),
    );
  }
}
