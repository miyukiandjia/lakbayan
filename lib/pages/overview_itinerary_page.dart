import 'package:flutter/material.dart';
import 'package:lakbayan/pages/create_itinerary_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lakbayan/pages/Itineraries.dart';

class OverviewItinerary extends StatelessWidget {
  final List<ItineraryDay> days;
  final String itineraryName;  // <-- Already added, keep this

  const OverviewItinerary({
    required this.days, 
    required this.itineraryName,  // Make sure to pass this when navigating to this page
    Key? key
  }) : super(key: key);

   @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Itinerary Overview'),
      ),
      body: ListView(
        children: [
          // Display the Itinerary Name at the top
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Itinerary: $itineraryName', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
          ),
          ...List.generate(days.length, (index) {  // Using List.generate for better clarity
            ItineraryDay day = days[index];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Day ${index + 1}', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
                    Text('Date: ${day.date.toLocal().toString().split(' ')[0]}', style: const TextStyle(fontSize: 30)),
                    Text('Day Name: ${day.name}', style: const TextStyle(fontSize: 30)),
                    const Text('Locations:', style: TextStyle(fontSize: 30)),
                    for (var location in day.locations)
                      if (location != null)
                        Text(location.name, style: const TextStyle(fontSize: 30)),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.save),
        onPressed: () async {
          User? currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser == null) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User not authenticated!')));
            return;
          }

          String uid = currentUser.uid;
          CollectionReference users = FirebaseFirestore.instance.collection('users');

          List<Map<String, dynamic>> daysList = days.map((day) {
            return {
              'name': day.name,
              'date': day.date,
              'locations': day.locations
                  .where((loc) => loc != null)
                  .map((loc) => {
                    'name': loc!.name,
                    'category': loc.category,
                    'status': 'Upcoming',
                  })
                  .toList(),
            };
          }).toList();

          var itineraryMap = {
            'userId': uid,
            'status': 'Upcoming',
            'itineraryName': itineraryName,  // Save the itinerary name
            'days': daysList
          };

          await users.doc(uid).collection('itineraries').add(itineraryMap);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved to Firebase!')));

          // Navigate to the ItinerariesPage
          Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (context) => ItinerariesPage()
          ));
        },
      ),
    );
  }
}