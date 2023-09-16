import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lakbayan/auth.dart';
import 'package:lakbayan/pages/home_page.dart';
import 'package:lakbayan/pages/login_register_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lakbayan/pages/Itineraries.dart';
import 'package:lakbayan/pages/gallery_page.dart';
import 'package:lakbayan/pages/saved_itineraries_page.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  TextEditingController _bioController = TextEditingController();
  bool _isEditingBio = false;

  Future<void> signOut(BuildContext context) async {
    await Auth().signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  Future<String?> uploadImageToFirebase(File? imageFile) async {
    if (imageFile == null) return null;

    final user = FirebaseAuth.instance.currentUser;
    final storageRef = FirebaseStorage.instance.ref().child('profile_pics/${user!.uid}.jpg');
    
    final uploadTask = storageRef.putFile(imageFile);
    final taskSnapshot = await uploadTask.whenComplete(() => {});
    
    final imageUrl = await taskSnapshot.ref.getDownloadURL();

    // Now, save the image URL in Firestore
    FirebaseFirestore.instance.collection('users').doc(user.uid).update({'profile_pic_url': imageUrl});

    return imageUrl;
  }

  Future<void> _uploadImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      setState(() {
      });
      await uploadImageToFirebase(imageFile);
    }
  }

  Widget _buildImageSection() {
    final currentUser = FirebaseAuth.instance.currentUser;
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(currentUser?.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasData) {
          String? profilePicUrl;
          var dataMap = snapshot.data!.data() as Map<String, dynamic>?;
          if (snapshot.data!.exists && dataMap?.containsKey('profile_pic_url') == true) {
            profilePicUrl = dataMap?['profile_pic_url'] as String?;
          }
          if (profilePicUrl != null) {
            return Image.network(profilePicUrl, width: 100, height: 100);
          }
        }
        return GestureDetector(
          onTap: _uploadImage,
          child: const CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.camera_alt,
              size: 40,
              color: Colors.grey,
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserEmail(String? userEmail) {
    return Text(
      userEmail ?? 'user@example.com',
      style: const TextStyle(
        fontSize: 60,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );
  }

   Future<String?> getBioFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();

    if (doc.exists && doc.data()!.containsKey('bio')) {
      return doc.data()?['bio'] as String?;
    }
    return null;
  }


   void saveBioToFirestore(String bio) {
    final user = FirebaseAuth.instance.currentUser;
    FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .set({'bio': bio});
  }

   void _uploadBio(String bio) {
    setState(() {
      _bioController.text = bio;
    });

    // Save the bio to Firestore
    saveBioToFirestore(bio);
  }

    Widget _buildBioSection() {
    if (_isEditingBio) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextFormField(
            controller: _bioController,
            style: const TextStyle(fontSize: 45),
            decoration: const InputDecoration(
              labelText: "Edit Bio",
              hintText: "User's bio comes here...",
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () {
                  String newBio = _bioController.text;
                  _uploadBio(newBio);
                  setState(() {
                    _isEditingBio = false;
                  });
                },
                icon: const Icon(
                  Icons.save,
                  size: 35,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _bioController.text.isEmpty
                ? "User's bio comes here..."
                : _bioController.text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 45,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _isEditingBio = true;
                  });
                },
                icon: const Icon(
                  Icons.edit,
                  size: 35,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      );
    }
  }

    Widget _buildSectionIcons(context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildSectionIcon(
          Icons.add_chart_rounded,
          'My Itineraries',
          () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ItinerariesPage()),
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
          Icons.star,
          'Saved Itineraries',
          () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const savedItineraries()),
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
            borderRadius: BorderRadius.circular(30),
          ),
          primary: const Color(0xFFF9CDDD),
          onPrimary: const Color(0xFFAD547F),
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
  void initState() {
    super.initState();
    // Load bio from Firestore when the profile page initializes
    getBioFromFirestore().then((bio) {
      setState(() {
        _bioController.text = bio ?? '';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
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
                    _buildImageSection(), // Image upload section

                    _buildUserEmail(currentUser?.email),
                    const SizedBox(height: 20),

                    _buildBioSection(), // Bio section

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