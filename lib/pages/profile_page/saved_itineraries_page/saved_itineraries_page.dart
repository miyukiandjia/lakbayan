import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lakbayan/pages/profile_page/saved_itineraries_page/get_itinerary.dart';

class SavedItineraries extends StatefulWidget {
  const SavedItineraries({Key? key}) : super(key: key);

  @override
  _SavedItinerariesState createState() => _SavedItinerariesState();
}

class _SavedItinerariesState extends State<SavedItineraries> {
  Future<List<Map<String, dynamic>>> getSavedItineraries(String userId) async {
    final sharedItinerariesRef = FirebaseFirestore.instance.collection('sharedItineraries');
    final sharedItineraries = await sharedItinerariesRef.get();
    
    List<Map<String, dynamic>> savedItineraries = [];

    for (final itinerary in sharedItineraries.docs) {
      final saveDoc = await itinerary.reference.collection('saves').doc(userId).get();
      if (saveDoc.exists) {
        final userData = await FirebaseFirestore.instance.collection('users').doc(itinerary['userId']).get();
        savedItineraries.add({
          'itinerary': itinerary,
          'user': userData,
        });
      }
    }

    return savedItineraries;
  }

  Future<void> _unsaveItinerary(DocumentSnapshot itineraryDoc, String userId) async {
    // 1. Remove the save
    await itineraryDoc.reference.collection('saves').doc(userId).delete();

    // 2. Decrement the saves count
    await itineraryDoc.reference.update({
      'saves': FieldValue.increment(-1)
    });
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final currentUserId = currentUser?.uid;

    if (currentUserId == null) {
      return Scaffold(
        body: Center(child: Text('Not logged in!')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Saved Itineraries'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: getSavedItineraries(currentUserId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator()); // Loading indicator
          }

          final itinerariesWithUser = snapshot.data!;
          if (itinerariesWithUser.isEmpty) {
            return Center(child: Text('No saved itineraries.'));
          }

          return ListView.builder(
            itemCount: itinerariesWithUser.length,
            itemBuilder: (context, index) {
              final itineraryData = itinerariesWithUser[index]['itinerary'].data() as Map<String, dynamic>;
              final userData = itinerariesWithUser[index]['user'].data() as Map<String, dynamic>;
              final days = (itineraryData['days'] as List).map((day) => day as Map<String, dynamic>).toList();

              return Card(
                margin: EdgeInsets.all(10),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Itinerary Name: ${itineraryData['itineraryName']}',
                            style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              await _unsaveItinerary(itinerariesWithUser[index]['itinerary'], currentUserId);
                              // Refresh the UI
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                      Text(
                        'By: ${userData['username']}',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      ...days.map((day) {
                        final locations = (day['locations'] as List).map((loc) => loc as Map<String, dynamic>).toList();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Day Name: ${day['name']}',style: TextStyle(fontSize: 25, fontWeight: FontWeight.w500),),
                            
                            ...locations.map((loc) {
                              return Text('Location: ${loc['name']}',style: TextStyle(fontSize: 25),);
                            }).toList(),
                          ],
                        );
                      }).toList(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => GetItineraryPage(itinerary: itineraryData),
                                ),
                              );
                            },
                            child: Text('Get Itinerary'),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
