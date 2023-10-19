import 'package:rxdart/rxdart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lakbayan/postCard.dart';
import 'package:lakbayan/homepage_Files/shared_itineraries.dart';

Widget lakbayanFeed(BuildContext context) {
  return StreamBuilder<List<dynamic>>(
    stream: Rx.combineLatest2<QuerySnapshot, QuerySnapshot, List<dynamic>>(
      FirebaseFirestore.instance
          .collection('posts')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      FirebaseFirestore.instance.collectionGroup('itineraries')
          .where('shareStatus', isEqualTo: true)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      (QuerySnapshot postsSnapshot, QuerySnapshot itinerariesSnapshot) {
        print('Posts data: ${postsSnapshot.docs}');
        print('Itineraries data: ${itinerariesSnapshot.docs}');

        return [
          ...postsSnapshot.docs.map((doc) => {'type': 'post', 'data': doc}),
          ...itinerariesSnapshot.docs.map((doc) => {'type': 'itinerary', 'data': doc})
        ]..sort((a, b) => b['data']['timestamp'].compareTo(a['data']['timestamp']));
      },
    ),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return CircularProgressIndicator();
      } else if (snapshot.hasError) {
        return Text('Error: ${snapshot.error}');
      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
        return Text('No posts or itineraries available.');
      } else {
        final items = snapshot.data!;
        return ListView.builder(
          itemCount: items.length,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final item = items[index];
            if (item['type'] == 'post') {
              final post = item['data'];
              final userId = post['userId'];

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .get(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  } else if (userSnapshot.hasError) {
                    return Text('Error: ${userSnapshot.error}');
                  } else if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                    return Text('User does not exist.');
                  } else {
                    return PostCard(
                      post: post,
                      userData: userSnapshot.data!,
                      userId: FirebaseAuth.instance.currentUser?.uid ?? 'No User ID fetched.',
                    );
                  }
                },
              );
            } else {
              final itinerary = item['data'];
                final userIdShared = itinerary['userId'];
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(userIdShared)
                    .get(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  } else if (userSnapshot.hasError) {
                    return Text('Error: ${userSnapshot.error}');
                  } else if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                    return Text('User does not exist.');
                  } else {
                    return SharedItineraryCard(
                      itinerary: itinerary.data() as Map<String, dynamic>,
                      userData: userSnapshot.data!,
                    );
                  }
                },
              );
            }
          },
        );
      }
    },
  );
}
