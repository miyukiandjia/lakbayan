import 'package:flutter/material.dart';
import 'package:lakbayan/pages/home_page/nav_bar.dart';
import 'package:lakbayan/pages/home_page/home_page.dart';

class NotifPage extends StatelessWidget {
  const NotifPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "ListView.builder",
      theme: ThemeData(primarySwatch: Colors.pink),
      debugShowCheckedModeBanner: false,
//      home: const ListViewBuilder(),
    );
  }
}

class ListViewBuilder extends StatelessWidget {
//  const ListViewBuilder({Key? key}) : super(key: key);

  // This list should be dynamically updated with real notification data
  final List<Map<String, dynamic>> notifications = [
    {
      'username': 'UserA',
      'action': 'liked your itinerary',
      'time': '5 minutes ago',
      'imageUrl': 'lib/images/user.png'
    },
    // Add more notification items here
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // Navigate back to the HomePage
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
            );
          },
        ),
        toolbarHeight: 100,
        backgroundColor: const Color(0xFFAD547F),
        title: const Text(
          'Notifications',
          style: TextStyle(fontFamily: 'Nunito', fontSize: 36),
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: ListView.builder(
                itemCount: notifications.length,
                shrinkWrap: true,
                itemBuilder: (BuildContext context, int index) {
                  final notification = notifications[index];
                  return Padding(
                      padding: const EdgeInsets.all(16),
                      child: ListTile(
                        leading: Container(
                            child: Image.asset('lib/images/user.png')),
                        trailing: const Text(
                          "5 minutes ago",
                        ),
                        title: Text(
                          notification['username'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(notification['action']),
                      ));
                }),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: customNavBar(context, 2),
          ),
        ],
      ),
    );
  }
}
