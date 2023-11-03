import 'package:flutter/material.dart';
import 'package:lakbayan/pages/home_page/nav_bar.dart';

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
      appBar: AppBar(title: const Text("LAKBAYAN NOTIFICATIONS")),
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
                        leading: SizedBox(
                            child: Image.asset(notification['imageUrl'])),
                        trailing: Text(
                          notification['time'],
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
