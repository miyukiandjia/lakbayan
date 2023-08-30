import 'package:flutter/material.dart';
import 'package:lakbayan/pages/overview_itinerary_page.dart';

class ItineraryScreen extends StatelessWidget {
  const ItineraryScreen({super.key});

  Widget _saveButton(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(20),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const OverviewItinerary(),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30), // Rounded edges
          ),
          primary: const Color(0xFFAD547F), // Button color
          onPrimary: Colors.white, // Font color
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
        child: const Text('Save',
            style: TextStyle(
                fontSize: 50,
                color: Color(0xFFAD547F),
                fontWeight: FontWeight.bold)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Implement your Create Itinerary screen UI here
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create Itinerary',
          style: TextStyle(fontSize: 30),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // const Text(
            //   'This is the Create Itinerary screen',
            //   style: TextStyle(fontSize: 100),
            // ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  _saveButton(context), // Add the SaveButton widget here,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
