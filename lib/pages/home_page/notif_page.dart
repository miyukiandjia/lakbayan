import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // For date formatting

// Assuming you already have the following import for your custom navigation bar
import 'package:lakbayan/pages/home_page/nav_bar.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Map<String, dynamic>>> getUserNotifications() {
    String userId = _auth.currentUser!.uid;
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notificationsLog')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          List<Map<String, dynamic>> notifications = [];
          for (var doc in snapshot.docs) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            DateTime date = (data['timestamp'] as Timestamp).toDate();
            String formattedDate = DateFormat('dd MMM yyyy hh:mm a').format(date);
            
            // Assuming 'fromUserId' contains the ID of the user who triggered the notification
            DocumentSnapshot userSnapshot = await _firestore.collection('users').doc(data['fromUserId']).get();
            Map<String, dynamic> userData = userSnapshot.data() as Map<String, dynamic>;
            
            notifications.add({
              'username': userData['username'] ?? 'Unknown User', // Fallback to 'Unknown User' if username is not found
              'action': data['type'] == 'itinerary_like' ? 'liked your itinerary' : 'liked your post',
              'time': formattedDate,
              'imageUrl': userData['profile_pic_url'] ?? 'lib/images/user.png', // Fallback to a default image if profile_pic_url is not found
            });
          }
          return notifications;
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        // Other AppBar properties...
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: getUserNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No notifications found.'));
          }
          final notifications = snapshot.data!;
          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(notification['imageUrl']),
                ),
                title: Text(notification['username']),
                subtitle: Text(notification['action']),
                trailing: Text(notification['time']),
              );
            },
          );
        },
      ),
      bottomNavigationBar: customNavBar(context, 2),
    );
  }
}
