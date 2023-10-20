import 'package:flutter/material.dart';

class ItineraryCard extends StatelessWidget {
  final Map<String, dynamic> itinerary;

  const ItineraryCard({super.key, required this.itinerary});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      child: Container(
        padding: const EdgeInsets.all(20), // Add padding for content
        decoration: BoxDecoration(
          color: const Color(0xFFAD547F), // Set container color
          borderRadius: BorderRadius.circular(15), // Add rounded corners
        ),
        child: Column(
          children: [
            SizedBox(
              width: 200,
              height: 200,
              child: Image.network(
                itinerary['image'],
                fit: BoxFit.cover,
                loadingBuilder: (BuildContext context, Widget child,
                    ImageChunkEvent? loadingProgress) {
                  if (loadingProgress == null) {
                    return child;
                  } else {
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                (loadingProgress.expectedTotalBytes ?? 1)
                            : null,
                      ),
                    );
                  }
                },
                errorBuilder: (BuildContext context, Object error,
                    StackTrace? stackTrace) {
                  return Center(
                    child: Image.network(
                      'https://i.pinimg.com/originals/f1/0f/f7/f10ff70a7155e5ab666bcdd1b45b726d.jpg',
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10), // Add some space
            Text(
              itinerary['name'],
              style: const TextStyle(
                fontSize: 35,
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w500,
                color: Colors.white, // Set text color
              ),
            ),
            const SizedBox(height: 10), // Add some space
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.star,
                  color: Colors.yellow, // Set star color
                  size: 30,
                ),
                Text(
                  '${itinerary['gReviews']}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.white, // Set text color
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10), // Add some space
            Text(
              '${itinerary['distance']} km away', // Assuming distance is in kilometers
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.white, // Set text color
              ),
            ),
          ],
        ),
      ),
    );
  }
}
