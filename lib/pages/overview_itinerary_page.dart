import 'package:flutter/material.dart';

class OverviewItinerary extends StatelessWidget {
  const OverviewItinerary({super.key});

  @override
  Widget build(BuildContext context) {
    // Implement your Create Itinerary screen UI here
    return Scaffold(
      appBar: AppBar(
        title: const Text('Itinerary Overview'),
      ),
      body: const Center(
        child: Text(
          'This is the Itinerary Overview screen',
          style: TextStyle(fontSize: 30),
        ),
      ),
    );
  }
}
