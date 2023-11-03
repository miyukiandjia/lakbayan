import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lakbayan/pages/authentication_page/auth.dart';
import 'package:lakbayan/pages/home_page/itinerary/create_itinerary_page.dart';
import 'package:lakbayan/pages/authentication_page/login_register_page.dart';
import 'package:lakbayan/pages/home_page/lakbayan_feed/create_post.dart';
import 'package:lakbayan/pages/home_page/nav_bar.dart';
import 'package:lakbayan/pages/home_page/pop_destination/pop_des_content.dart';
import 'package:lakbayan/pages/home_page/pop_destination/pop_des_container.dart';
import 'package:lakbayan/pages/home_page/lakbayan_feed/combined_feed.dart';
import 'package:lakbayan/pages/home_page/itinerary/migrate_shared_itineraries.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';


class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final User? user = Auth().currentUser;
  String? username;
  late CreatePost post;

  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  late AndroidInitializationSettings initializationSettingsAndroid;
  late DarwinInitializationSettings initializationSettingsIOS;
  late InitializationSettings initSetttings;

  @override
  void initState() {
    super.initState();
    post = CreatePost(user: user, username: username, context: context);
    _checkAuthentication();
    migrateSharedItineraries();
    _setupMessaging();

    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    initializationSettingsIOS = DarwinInitializationSettings();
    initSetttings = InitializationSettings(android: initializationSettingsAndroid, iOS: initializationSettingsIOS);

    flutterLocalNotificationsPlugin.initialize(initSetttings);
  
  }

    Future onSelectNotification(String? payload) async {
    if (payload != null && payload.isNotEmpty) {
      // Handle the payload
      print('notification payload: $payload');
      // You can navigate to the desired page here
    }
  }

  _checkAuthentication() async {
  final user = Auth().currentUser;
  print("Current user ID: ${user?.uid}");

  if (user == null) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  } else {
    // Fetch the username from Firestore
    final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final docSnapshot = await userDocRef.get();
    setState(() {
      username = docSnapshot.data()?['username'];
      post = CreatePost(user: user, username: username, context: context);
    });

    // Retrieve and update FCM token
    String? token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await userDocRef.update({'fcmToken': token});
      print("FCM Token updated: $token");
    }
  }
}

  void _setupMessaging() async {
    // Request permissions for notifications
    NotificationSettings settings = await FirebaseMessaging.instance.requestPermission();
    print('User granted permission: ${settings.authorizationStatus}');

    // Handle foreground messages
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  print("Got a message whilst in the foreground!");
  print("Message data: ${message.data}");

  if (message.notification != null) {
    print("Message also contained a notification: ${message.notification}");

    // Show the notification using flutter_local_notifications
var androidPlatformChannelSpecifics = AndroidNotificationDetails(
  'your_channel_id', 
  'your_channel_name', 
  importance: Importance.max,
  priority: Priority.high,
);

// For iOS, you should use DarwinNotificationDetails instead of DarwinInitializationSettings
var iOSPlatformChannelSpecifics = DarwinNotificationDetails(
  // You can specify iOS-specific notification details here
);

var platformChannelSpecifics = NotificationDetails(
  android: androidPlatformChannelSpecifics, 
  iOS: iOSPlatformChannelSpecifics
);

flutterLocalNotificationsPlugin.show(
  0, 
  message.notification?.title, 
  message.notification?.body, 
  platformChannelSpecifics,
  payload: 'item x',
);
  }
});


    // Handle messages when the app is opened from a terminated state
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Message clicked!');
      // Here you can navigate to the specific screen related to the notification
    });

    // Update the FCM token in Firestore
    final user = Auth().currentUser;
    if (user != null) {
      final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await userDocRef.update({'fcmToken': token});
        print("FCM Token updated: $token");
      }
    }
  }


  Widget _userInfo(BuildContext context) {
    var now = DateTime.now();
    var timeOfDay = now.hour;
    String greeting;

    if (timeOfDay >= 0 && timeOfDay < 12) {
      greeting = 'Good morning,';
    } else if (timeOfDay >= 12 && timeOfDay < 17) {
      greeting = 'Good afternoon,';
    } else {
      greeting = 'Good evening,';
    }

    String nameToShow = username ??
        'User'; // Show 'User' as default if username is not available

    double fontSize = MediaQuery.of(context).size.width * 0.03;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: TextStyle(fontSize: fontSize, fontFamily: 'Nunito'),
          ),
          Text(
            nameToShow,
            style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                fontFamily: 'Nunito'),
          ),
        ],
      ),
    );
  }

  Widget _createItinerary(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: OutlinedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const CreateItineraryPage()),
          );
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
        ),
        child: const Text(
          '+ Create Itinerary',
          style: TextStyle(
            fontSize: 30,
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w600,
            color: Color.fromARGB(255, 58, 70, 70),
          ),
        ),
      ),
    );
  }

  Widget _davaoImage(BuildContext context) {
    double imageSize = MediaQuery.of(context).size.width * 0.30;

    return SizedBox(
      width: imageSize,
      height: imageSize,
      child: FittedBox(
        fit: BoxFit.cover,
        child: Image.asset('lib/images/lakbayan-home-page.png'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0.0,
        bottomOpacity: 0.0,
        toolbarHeight: 150,
        backgroundColor: Colors.white,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _userInfo(context),
            _createItinerary(context),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(color: Colors.black),
      ),
      body: Stack(
        children: <Widget>[
          ListView(
            children: <Widget>[
              Center(child: _davaoImage(context)),
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    'Popular Destinations',
                    style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 50,
                        fontWeight: FontWeight.w600,
                        color: Color.fromARGB(255, 58, 70, 70)),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(30),
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: fetchNearbyDestinations(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return Text(
                        'Error: ${snapshot.error}',
                        style: const TextStyle(fontSize: 50),
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Text('No popular destinations available.');
                    } else {
                      final destinations = snapshot.data!;
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: destinations.map((destination) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 20),
                              child: ItineraryCard(itinerary: destination),
                            );
                          }).toList(),
                        ),
                      );
                    }
                  },
                ),
              ),
              //LAKBAYAN CONTAINER
              Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      colors: [
                        Color(0xFFAD547F),
                        Color.fromARGB(255, 244, 143, 177)
                      ],
                    ),
                    // color: const Color(
                    //     0xFFAD547F), // Set the background color of the container
                    borderRadius:
                        BorderRadius.circular(8.0), // Set rounded corners
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Lakbayan Feed',
                        style: TextStyle(
                          fontSize: 50, // Adjust the font size as needed
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Nunito',
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(
                          height: 20.0), // Adjust the spacing as needed
                      post.section(),
                      const SizedBox(
                        height: 20,
                      ),
                      lakbayanFeed(context),
                    ],
                  )),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: customNavBar(context, 0),
          ),
        ],
      ),
    );
  }
}
