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
          // Get the current user's UID
          User? currentUser = FirebaseAuth.instance.currentUser;

          // Check if a user is authenticated
          if (currentUser == null) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('User not authenticated!')));
            return;
          }

          // Use the UID to save data
          String uid = currentUser.uid;

          // Get a reference to the Firestore collection
          CollectionReference users =
              FirebaseFirestore.instance.collection('users');

          for (var day in days) {
            // Convert your day object into a map that Firestore can understand
            var dayMap = {
              'userId': uid,
              'name': day.name,
              'date': day.date,
              'locations': day.locations
                  .where((loc) => loc != null)
                  .map((loc) => {'name': loc!.name, 'category': loc.category})
                  .toList(),
            };

            // Add day to the Firestore collection under the specific user
            await users.doc(uid).collection('itineraries').add(dayMap);
          }

          // Optionally, show a message or do other actions after saving
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Saved to Firebase!')));
        },
      ),
    );
  }
}
