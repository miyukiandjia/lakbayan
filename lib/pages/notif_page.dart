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
        // home : new ListViewBuilder(),  NO Need To Use Unnecessary New Keyword
        home: const ListViewBuilder());
  }
}

class ListViewBuilder extends StatelessWidget {
  const ListViewBuilder({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("LAKBAYAN NOTIFICATIONS")),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: ListView.builder(
                itemCount: 10,
                shrinkWrap: true,
                itemBuilder: (BuildContext context, int index) {
                  return Padding(
                      padding: EdgeInsets.all(16),
                      child: ListTile(
                        leading:
                            SizedBox(child: Image.asset('lib/images/user.png')),
                        trailing: const Text(
                          "5 minutes ago",
                        ),
                        title: Text(
                          "Username",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text("liked a recent Itinerary."),
                      ));
                }),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: customNavBar(context,
                2), // I'm assuming 2 is the index for the "Notif" page.
          ),
        ],
      ),
    );
  }
}
