import 'package:flutter/material.dart';
import 'package:lakbayan/auth.dart';
import 'package:lakbayan/pages/login_register_page.dart';
import 'package:lakbayan/pages/home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lakbayan/pages/completed_itineraries_page.dart';
import 'package:lakbayan/pages/gallery_page.dart';
import 'package:lakbayan/pages/biodata_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> signOut(BuildContext context) async {
    await Auth().signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  Widget _buildUserEmail(String? userEmail) {
    return Text(
      userEmail ?? 'user@example.com', // Display the user's email
      style: const TextStyle(
        fontSize: 60,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildSectionIcons(context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildSectionIcon(
          Icons.check,
          'Completed',
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const CompletedItineraries()),
            );
          },
        ),
        _buildSectionIcon(
          Icons.photo_library,
          'Photos',
          () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const Gallery()),
            );
          },
        ),
        _buildSectionIcon(
          Icons.person,
          'Biodata',
          () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const Biodata()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSectionIcon(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(
            icon,
            size: 60,
            color: Colors.white,
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 25,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _signOutButton(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(20),
      child: ElevatedButton(
        onPressed: () => signOut(context),
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30), // Rounded edges
          ),
          primary: const Color(0xFFF9CDDD), // Button color
          onPrimary: const Color(0xFFAD547F), // Font color
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
        child: const Text('Sign Out',
            style: (TextStyle(
                fontSize: 50,
                color: Color(0xFFAD547F),
                fontWeight: FontWeight.bold))),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get the current user's email from FirebaseAuth
    final currentUser = FirebaseAuth.instance.currentUser;
    //final userEmail = currentUser?.email ?? 'user@example.com';
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        bottomOpacity: 0.0,
        toolbarHeight: 90,
        backgroundColor: const Color(0xFFAD547F),
        leading: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey[300],
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFFAD547F)),
                iconSize: 50,
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => HomePage()),
                  );
                },
              ),
              const SizedBox(width: 20),
              const Text(
                'Profile',
                style: TextStyle(fontSize: 45, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
      body: Container(
        color: const Color(0xFFAD547F),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    // ... Other profile content ...

                    //TEMPORARY RA SA NI BOSSING
                    const CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.camera_alt,
                        size: 40,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildUserEmail(currentUser?.email),
                    const SizedBox(height: 20), // Add spacing

                    // Call the separate function to build section icons
                    _buildSectionIcons(context),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: _signOutButton(context),
            ),
          ],
        ),
      ),
    );
  }
}
