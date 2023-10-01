import 'package:flutter/material.dart';

class ItineraryCard extends StatelessWidget {
  final Map<String, dynamic> itinerary;
  final String username;

  ItineraryCard({required this.itinerary, required this.username});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Itinerary Name: ${itinerary['itineraryName']}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text('By: $username'),
            ...List.generate(itinerary['days'].length, (index) {
              final day = itinerary['days'][index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Day ${index + 1}: ${day['name']}'),
                  // Loop through and display locations for each day
                  ...List.generate(day['locations'].length, (locIndex) {
                    final location = day['locations'][locIndex];
                    return Text('Location: ${location['name']}');
                  }),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
