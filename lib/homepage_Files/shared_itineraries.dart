import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_webservice/directions.dart' as gmaps;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SharedItineraryCard extends StatefulWidget {
  final Map<String, dynamic> itinerary;
  final DocumentSnapshot userData;

  SharedItineraryCard({required this.itinerary, required this.userData});

  @override
  _SharedItineraryCardState createState() => _SharedItineraryCardState();
}

class _SharedItineraryCardState extends State<SharedItineraryCard> {
  bool isLiked = false; // Track if the current user has liked the itinerary
  bool isSaved = false; // Track if the current user has saved the itinerary
  bool showMap = false;

  @override
  void initState() {
    super.initState();
     print("User data in SharedItineraryCard: ${FirebaseAuth.instance.currentUser?.uid}");
    checkIfLiked(); // Check if the current user has liked the itinerary initially
    checkIfSaved();
    ensureUserDataFields();
  }
  void checkIfSaved() async {
  final itineraryId = widget.itinerary['id']; 
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  DocumentSnapshot saveDoc = await FirebaseFirestore.instance
      .collection('sharedItineraries')
      .doc(itineraryId)
      .collection('saves')
      .doc(currentUserId)
      .get();

  setState(() {
    isSaved = saveDoc.exists;
  });
}

  Future<void> ensureUserDataFields() async {
    final userId = widget.userData.id;
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);

    DocumentSnapshot userDoc = await userRef.get();

    Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

    Map<String, dynamic> updates = {};

    if (!userData.containsKey('prof_pic_url') || userData['prof_pic_url'] == "") {
      // If the 'prof_pic_url' field doesn't exist or is empty, set a default value
      updates['prof_pic_url'] = 'https://i.pinimg.com/originals/f1/0f/f7/f10ff70a7155e5ab666bcdd1b45b726d.jpg';
    }
    if (!userData.containsKey('username') || userData['username'] == "") {
      // If the 'username' field doesn't exist or is empty, set a default value
      updates['username'] = 'Unknown User';
    }

    // Add other fields if you need...

    if (updates.isNotEmpty) {
      await userRef.update(updates);
    }
  }

  Future<LatLng> _getUserLocation() async {
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    return LatLng(position.latitude, position.longitude);
  }

  void checkIfLiked() async {
    final itineraryId = widget.itinerary['id']; 
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    DocumentSnapshot likeDoc = await FirebaseFirestore.instance
        .collection('sharedItineraries')
        .doc(itineraryId)
        .collection('likes')
        .doc(currentUserId)
        .get();

    setState(() {
      isLiked = likeDoc.exists;
    });
  }

void toggleLike() async {
  print("Toggling like for user: ${widget.userData.id}");
  final itineraryId = widget.itinerary['id']; 
  final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  
  if (isLiked) {
    await FirebaseFirestore.instance
        .collection('sharedItineraries')
        .doc(itineraryId)
        .collection('likes')
        .doc(currentUserId) 
        .delete();

    await FirebaseFirestore.instance
        .collection('sharedItineraries')
        .doc(itineraryId)
        .set({'likes': FieldValue.increment(-1)}, SetOptions(merge: true));
  } else {
    await FirebaseFirestore.instance
        .collection('sharedItineraries')
        .doc(itineraryId)
        .collection('likes')
        .doc(currentUserId) 
        .set({'likedAt': FieldValue.serverTimestamp()});

    await FirebaseFirestore.instance
        .collection('sharedItineraries')
        .doc(itineraryId)
        .set({'likes': FieldValue.increment(1)}, SetOptions(merge: true));
  }
  setState(() {
    isLiked = !isLiked;
  });
}

void toggleSave() async {
  final itineraryId = widget.itinerary['id']; 
  final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  if (isSaved) {
    await FirebaseFirestore.instance
        .collection('sharedItineraries')
        .doc(itineraryId)
        .collection('saves')
        .doc(currentUserId) 
        .delete();

    await FirebaseFirestore.instance
        .collection('sharedItineraries')
        .doc(itineraryId)
        .set({'saves': FieldValue.increment(-1)}, SetOptions(merge: true));
  } else {
    await FirebaseFirestore.instance
        .collection('sharedItineraries')
        .doc(itineraryId)
        .collection('saves')
        .doc(currentUserId) 
        .set({'savedAt': FieldValue.serverTimestamp()});

    await FirebaseFirestore.instance
        .collection('sharedItineraries')
        .doc(itineraryId)
        .set({'saves': FieldValue.increment(1)}, SetOptions(merge: true));
  }
  setState(() {
    isSaved = !isSaved;
  });
}

  void showCommentsDialog() async {
    TextEditingController commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Comments'),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // StreamBuilder to display the list of comments
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(widget.userData.id)
                    .collection('sharedItineraries')
                    .doc(widget.itinerary['id'])
                    .collection('comments')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return CircularProgressIndicator();
                  }
                  final comments = snapshot.data!.docs;
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final comment = comments[index].data() as Map<String, dynamic>;
                      return ListTile(
                        title: Text(comment['username']),
                        subtitle: Text(comment['text']),
                        onLongPress: () {
                          showMenu(
                            context: context,
                            position: RelativeRect.fill,
                            items: [
                              PopupMenuItem(
                                value: 'edit',
                                child: Text('Edit'),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ],
                          ).then((value) async {
                            if (value != null) {
                              final commentId = comments[index].id;
                              if (value == 'edit') {
                                // Show a dialog to edit the comment
                                final TextEditingController editController =
                                    TextEditingController(text: comment['text']);
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text('Edit Comment'),
                                    content: TextField(
                                      controller: editController,
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop(); // Close the dialog
                                        },
                                        child: Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          // Update the comment in Firestore
                                          await FirebaseFirestore.instance
                                              .collection('users')
                                              .doc(widget.userData.id)
                                              .collection('sharedItineraries')
                                              .doc(widget.itinerary['id'])
                                              .collection('comments')
                                              .doc(commentId)
                                              .update({'text': editController.text});
                                          Navigator.of(context).pop(); // Close the dialog
                                        },
                                        child: Text('Save'),
                                      ),
                                    ],
                                  ),
                                );
                              } else if (value == 'delete') {
                                // Confirm and delete the comment
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text('Confirm Delete'),
                                      content: Text('Are you sure you want to delete this comment?'),
                                      actions: <Widget>[
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop(); // Close the dialog
                                          },
                                          child: Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            // Delete the comment from Firestore
                                            await FirebaseFirestore.instance
                                                .collection('users')
                                                .doc(widget.userData.id)
                                                .collection('sharedItineraries')
                                                .doc(widget.itinerary['id'])
                                                .collection('comments')
                                                .doc(commentId)
                                                .delete();
                                            Navigator.of(context).pop(); // Close the dialog
                                          },
                                          child: Text('Delete'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              }
                            }
                          });
                        },
                      );
                    },
                  );
                },
              ),
              // TextField to add a new comment
              TextFormField(
                controller: commentController,
                decoration: InputDecoration(
                  labelText: 'Write a comment...',
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              // Get the text from the controller
              final commentText = commentController.text.trim();

              // Check if the comment text is not empty
              if (commentText.isNotEmpty) {
                // Add the comment to Firestore
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(widget.userData.id)
                    .collection('sharedItineraries')
                    .doc(widget.itinerary['id'])
                    .collection('comments')
                    .add({
                      'userId': widget.userData.id,
                      'username': widget.userData['username'],
                      'text': commentText,
                      'timestamp': FieldValue.serverTimestamp(),
                    });

                // Clear the controller
                commentController.clear();
              }
            },
            child: Text('Post Comment'),
          ),
        ],
      ),
    );
  }

  Future<List<LatLng>> _getDirections(LatLng start, LatLng destination) async {
    const String apiKey = "AIzaSyDMxSHLjuBE_QPy6OoJ1EPqpDsBCJ32Rr0";  // Replace with your Google Maps API Key
    final directions = gmaps.GoogleMapsDirections(apiKey: apiKey);
    
    gmaps.DirectionsResponse response = await directions.directions(
      gmaps.Location(lat: start.latitude, lng: start.longitude),
      gmaps.Location(lat: destination.latitude, lng: destination.longitude),
      travelMode: gmaps.TravelMode.driving,
    );

    if (response.status == 'OK') {
      PolylinePoints polylinePoints = PolylinePoints();
      var points = polylinePoints.decodePolyline(response.routes[0].overviewPolyline.points);
      return points.map((point) => LatLng(point.latitude, point.longitude)).toList();
    }
    
    return [];
  }

  Widget _buildMap(List<dynamic> days) {
    if (!showMap) {
      return Container();
    }
    return FutureBuilder<LatLng>(
      future: _getUserLocation(),
      builder: (BuildContext context, AsyncSnapshot<LatLng> snapshot) {
        if (!snapshot.hasData) {
          return CircularProgressIndicator();  // Show loading indicator until user location is fetched
        }

        LatLng userLocation = snapshot.data!;
        List<LatLng> polylineCoordinates = [userLocation];  // Start with the user's location
        
        for (var day in days) {
          if (day['locations'] != null) {
            for (var location in day['locations']) {
              if (location['latitude'] != null && location['longitude'] != null) {
                LatLng latLng = LatLng(location['latitude'], location['longitude']);
                polylineCoordinates.add(latLng);
              }
            }
          }
        }
        
        return FutureBuilder<List<LatLng>>(
          future: _getDirections(userLocation, polylineCoordinates.last),
          builder: (context, routeSnapshot) {
            if (!routeSnapshot.hasData) {
              return CircularProgressIndicator();  // Show loading indicator until route is fetched
            }
            
            List<LatLng> routeCoordinates = routeSnapshot.data!;
            
            Polyline polyline = Polyline(
              polylineId: PolylineId('route'),
              color: Colors.blue,
              points: routeCoordinates,
              width: 5,
            );

            return Container(
              height: 400,
              width: double.infinity,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: userLocation,
                  zoom: 12.0,
                ),
                polylines: {polyline},
                gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>[
                  Factory<OneSequenceGestureRecognizer>(
                    () => EagerGestureRecognizer(),
                  ),
                ].toSet(),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String profileImageUrl = widget.userData['prof_pic_url'] ?? "";
    if (profileImageUrl.isEmpty) {
      profileImageUrl = "https://i.pinimg.com/originals/f1/0f/f7/f10ff70a7155e5ab666bcdd1b45b726d.jpg";
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(profileImageUrl),
                  radius: 25,
                ),
                const SizedBox(width: 10),
                Text(
                  widget.userData['username'] ?? 'Unknown User',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Itinerary Name: ${widget.itinerary['itineraryName']}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...List.generate(widget.itinerary['days'].length, (index) {
              final day = widget.itinerary['days'][index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Day ${index + 1}: ${day['name']}'),
                  ...List.generate(day['locations'].length, (locIndex) {
                    final location = day['locations'][locIndex];
                    return Text('Location: ${location['name']}');
                  }),
                ],
              );
            }),
            
            if (widget.itinerary['days'] is List) _buildMap(widget.itinerary['days']),
            const SizedBox(height: 10),
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? Colors.red : null,
                  ),
                  onPressed: toggleLike,
                ),
                StreamBuilder<DocumentSnapshot>(
    stream: FirebaseFirestore.instance
        .collection('sharedItineraries')
        .doc(widget.itinerary['id'])
        .snapshots(),
    builder: (context, snapshot) {
        if (!snapshot.hasData) {
            return CircularProgressIndicator();  // Loading indicator
        }
        final itineraryData = snapshot.data!.data() as Map<String, dynamic>;
        return Text(itineraryData['likes']?.toString() ?? '0');
    },
),
                IconButton(
  icon: Icon(
    isSaved ? Icons.star : Icons.star_border,
    color: isSaved ? Colors.yellow : null,
  ),
  onPressed: toggleSave,
),
StreamBuilder<DocumentSnapshot>(
  stream: FirebaseFirestore.instance
      .collection('sharedItineraries')
      .doc(widget.itinerary['id'])
      .snapshots(),
  builder: (context, snapshot) {
      if (!snapshot.hasData) {
          return CircularProgressIndicator();  // Loading indicator
      }
      final itineraryData = snapshot.data!.data() as Map<String, dynamic>;
      return Text(itineraryData['saves']?.toString() ?? '0');
  },
),
                IconButton(
                  icon: Icon(Icons.comment),
                  onPressed: showCommentsDialog,
                ),
                
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      showMap = !showMap;
                    });
                  },
                  child: Text(showMap ? "Hide Map" : "View in Maps"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
