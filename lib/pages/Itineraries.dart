import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ItinerariesPage extends StatefulWidget {
  @override
  _ItinerariesPageState createState() => _ItinerariesPageState();
}

class _ItinerariesPageState extends State<ItinerariesPage> {
  List<Map<String, dynamic>> _localItineraries = [];

  Stream<QuerySnapshot> _getItinerariesByStatus(String status) {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      String uid = currentUser.uid;
      return FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('itineraries')
          .where('status', isEqualTo: status)
          .snapshots();
    } else {
      // Return an empty stream if no user is logged in
      return Stream<QuerySnapshot>.empty();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Your Itineraries"),
          bottom: TabBar(
            tabs: [
              Tab(text: "Current"),
              Tab(text: "Done"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildItineraryListView("Ongoing"),
            _buildItineraryListView("Done"),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> deepCopy(List<dynamic> original) {
    return original.map((map) => Map<String, dynamic>.from(map as Map)).toList();
  }

  bool _isItineraryDone(List<Map<String, dynamic>> days) {
    return days.every((day) {
      final locations = (day['locations'] as List).cast<Map<String, dynamic>>();
      return locations.every((location) => location['status'] == 'Done');
    });
  }

  Widget _buildItineraryListView(String status) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getItinerariesByStatus(status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text("No itineraries available."));
        }

        if (status == "Ongoing" && _localItineraries.isEmpty) {
          _localItineraries = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final dayList = (data['days'] as List).cast<Map<String, dynamic>>();

            if (dayList.every((element) => element is Map<String, dynamic>)) {
              return {
                'docRef': doc.reference,  // Saving reference for updates
                ...data,
                'days': deepCopy(dayList.map((item) => item as Map<String, dynamic>).toList())
              };
            }
            return null;
          }).where((element) => element != null).toList().cast<Map<String, dynamic>>();
        }

        List<Map<String, dynamic>> itinerariesToDisplay = (status == "Ongoing") ? _localItineraries : snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              'docRef': doc.reference,  // Saving reference for updates
              ...data
            };
        }).toList();

        return ListView.builder(
          itemCount: itinerariesToDisplay.length,
          itemBuilder: (context, index) {
            return _buildItineraryCard(itinerariesToDisplay[index], status);
          },
        );
      },
    );
  }

  Widget _buildItineraryCard(Map<String, dynamic> itinerary, String status) {
    final days = itinerary['days'];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Itinerary Name: ${itinerary['itineraryName']}', style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold)),
            for (int i = 0; i < days.length; i++) ...[
              Text('Day ${i + 1}: ${days[i]['name']}', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
              Text('Date: ${DateTime.fromMillisecondsSinceEpoch((days[i]['date'] as Timestamp).seconds * 1000).toLocal().toString().split(' ')[0]}',
                  style: TextStyle(fontSize: 25)),
              if (status == "Ongoing")
                for (var location in days[i]['locations']) ...[
                  CheckboxListTile(
                    title: Text(location['name']),
                    value: location['status'] == 'Done',
                    onChanged: (newValue) {
                      setState(() {
                        location['status'] = newValue! ? 'Done' : 'Ongoing';
                      });
                    },
                  ),
                ], 
              SizedBox(height: 10),
            ],
            if (status == "Ongoing")
              ElevatedButton(
                onPressed: () async {
                  final isDone = _isItineraryDone(days);
                  await itinerary['docRef'].update({
                    'days': days,
                    'status': isDone ? 'Done' : 'Ongoing'
                  });
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Itinerary updated!')));
                },
                child: Text('Save'),
              ),
          ],
        ),
      ),
    );
  }
}
