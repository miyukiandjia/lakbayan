import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> migrateSharedItineraries() async {
  try {
   // ignore: avoid_print
   print("migrateSharedItineraries started...");
  final users = FirebaseFirestore.instance.collection('users');
  final sharedItineraries = FirebaseFirestore.instance.collection('sharedItineraries');

  // Fetch all user documents
  final userDocs = await users.get();

  for (final userDoc in userDocs.docs) {
    final uid = userDoc.id;
    final itineraries = users.doc(uid).collection('itineraries');
    // ignore: avoid_print
    print(itineraries);
    
    // Fetch itineraries with shareStatus set to true
    final sharedItineraryDocs = await itineraries.where('shareStatus', isEqualTo: true).get();
    // ignore: avoid_print
    print('shareditineraries:');
    // ignore: avoid_print
    print(sharedItineraryDocs);
    
    for (final sharedItineraryDoc in sharedItineraryDocs.docs) {
      final itineraryData = sharedItineraryDoc.data();
      
      // Check if this itinerary already exists in sharedItineraries collection
      final existingSharedItinerary = await sharedItineraries.doc(sharedItineraryDoc.id).get();
      
      if (!existingSharedItinerary.exists) {
        // If not exists, add this itinerary to sharedItineraries collection
        await sharedItineraries.doc(sharedItineraryDoc.id).set(itineraryData);
      }}}}catch (e){
  // ignore: avoid_print
  print("Error in migrateSharedItineraries: $e");
      }
    }
 