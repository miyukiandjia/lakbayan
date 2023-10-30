import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lakbayan/pages/home_page/itinerary/subclasses/create_subclasses.dart';
import 'package:lakbayan/pages/profile_page/my_itineraries_page.dart';

class OverviewItinerary extends StatelessWidget {
  final List<ItineraryDay> days;
  final String itineraryName; // <-- Already added, keep this

  const OverviewItinerary(
      {required this.days,
      required this.itineraryName, // Make sure to pass this when navigating to this page
      Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 100,
        title: const Text(
          'Itinerary Overview',
          style: TextStyle(fontFamily: 'Nunito', fontSize: 36),
        ),
        backgroundColor: const Color(0xFFAD547F),
      ),
      body: ListView(
        children: [
          // Display the Itinerary Name at the top
          Padding(
            padding: const EdgeInsets.all(50),
            child: Text('Itinerary name: $itineraryName',
                style:
                    const TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
          ),
          ...List.generate(days.length, (index) {
            // Using List.generate for better clarity
            ItineraryDay day = days[index];

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(50),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Day ${index + 1}',
                        style: const TextStyle(
                            fontSize: 40, fontWeight: FontWeight.bold)),
                    const SizedBox(
                      height: 10,
                    ),
                    Text('Date: ${day.date.toLocal().toString().split(' ')[0]}',
                        style: const TextStyle(fontSize: 30)),
                    Text('Day Name: ${day.name}',
                        style: const TextStyle(fontSize: 30)),
                    const Text('Locations:', style: TextStyle(fontSize: 30)),
                    for (var location in day.locations)
                      // ignore: unnecessary_null_comparison
                      if (location != null)
                        Text(location.name,
                            style: const TextStyle(fontSize: 30)),
                    const SizedBox(
                      height: 20,
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFAD547F),
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

          List<Map<String, dynamic>> daysList = days.map((day) {
            return {
              'name': day.name,
              'date': day.date,
              'locations': day.locations
                  // ignore: unnecessary_null_comparison
                  .where((loc) => loc != null)
                  .map((loc) => {
                        'name': loc.name,
                        'category': loc.category,
                        'status': 'Upcoming',
                        'latitude': loc.latitude, // Save the latitude
                        'longitude': loc.longitude, // Save the longitude
                      })
                  .toList(),
            };
          }).toList();

          var newItineraryRef = users.doc(uid).collection('itineraries').doc();

          var itineraryMap = {
            'id': newItineraryRef.id,
            'userId': uid,
            'status': 'Upcoming',
            'shareStatus': false,
            'likes': 0,
            'saves': 0,
            'timestamp': FieldValue.serverTimestamp(),
            'itineraryName': itineraryName, // Save the itinerary name
            'days': daysList
          };

          await newItineraryRef.set(itineraryMap);
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Saved to Firebase!')));

          // Navigate to the ItinerariesPage
          // ignore: use_build_context_synchronously
          Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => ItinerariesPage()));
        },
        child: const Icon(Icons.save),
      ),
    );
  }
}
