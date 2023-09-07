import 'package:flutter/material.dart';
import 'package:lakbayan/pages/create_itinerary_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OverviewItinerary extends StatelessWidget {
  final List<ItineraryDay> days;

  const OverviewItinerary({required this.days, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Itinerary Overview'),
      ),
      body: ListView.builder(
        itemCount: days.length,
        itemBuilder: (context, index) {
          ItineraryDay day = days[index];
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Day ${index + 1}',
                      style: const TextStyle(
                          fontSize: 40,
                          fontWeight:
                              FontWeight.bold)), // Increase the font size
                  Text('Date: ${day.date.toLocal().toString().split(' ')[0]}',
                      style: const TextStyle(fontSize: 30)),
                  Text('Itinerary Name: ${day.name}',
                      style: const TextStyle(fontSize: 30)),
                  const Text('Locations:', style: TextStyle(fontSize: 30)),
                  for (var location in day.locations)
                    if (location != null)
                      Text(location.name, style: const TextStyle(fontSize: 30)),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.save),
        onPressed: () async {
          User? currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser == null) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('User not authenticated!')));
            return;
          }
          String uid = currentUser.uid;
          CollectionReference users =
              FirebaseFirestore.instance.collection('users');

          // Convert all days to dayMaps
          List<Map<String, dynamic>> daysList = days.map((day) {
            return {
              'name': day.name,
              'date': day.date,
              'locations': day.locations
                  .where((loc) => loc != null)
                  .map((loc) => {
                        'name': loc!.name,
                        'category': loc.category,
                        'status': 'Ongoing',
                      })
                  .toList(),
            };
          }).toList();

          // Create a single itinerary map
          var itineraryMap = {
            'userId': uid,
            'status': 'Ongoing',
            'days': daysList
          };

          // Add the itineraryMap to Firestore
          await users.doc(uid).collection('itineraries').add(itineraryMap);

          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Saved to Firebase!')));
        },
      ),
    );
  }
}
