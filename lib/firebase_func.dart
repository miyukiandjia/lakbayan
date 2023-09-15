import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

final currentUser = FirebaseAuth.instance.currentUser;
final firestore = FirebaseFirestore.instance;

void saveBioToFirebase(String bio) async {
  try {
    await firestore.collection('users').doc(currentUser!.uid).set({
      'bio': bio,
    }, SetOptions(merge: true));

    print('Bio saved successfully!');
  } catch (error) {
    print('Error saving bio: $error');
  }
}

Future<String?> getBioFromFirebase() async {
  try {
    DocumentSnapshot<Map<String, dynamic>> userDoc =
        await firestore.collection('users').doc(currentUser!.uid).get();

    return userDoc.data()?['bio'];
  } catch (error) {
    print('Error fetching bio: $error');
    return null;
  }
}
