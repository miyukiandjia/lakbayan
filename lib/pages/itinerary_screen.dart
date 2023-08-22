import 'package:flutter/material.dart';

class ItineraryScreen extends StatelessWidget {
  const ItineraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Implement your Create Itinerary screen UI here
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Itinerary'),
      ),
      body: const Center(
        child: Text('This is the Create Itinerary screen'),
      ),
    );
  }
}
