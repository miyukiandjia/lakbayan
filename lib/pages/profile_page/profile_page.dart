// optimization resumes here ji! 10/20 11:47 pm

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lakbayan/pages/authentication_page/auth.dart';
import 'package:lakbayan/pages/profile_page/my_itineraries_page.dart';
import 'package:lakbayan/pages/profile_page/gallery_page.dart';
import 'package:lakbayan/pages/home_page/home_page.dart';
import 'package:lakbayan/pages/authentication_page/login_register_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:lakbayan/pages/profile_page/saved_itineraries_page/saved_itineraries_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  TextEditingController _bioController = TextEditingController();
  bool _isEditingBio = false;
  String? username; // To hold the username

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
    final storageRef =
        FirebaseStorage.instance.ref().child('profile_pics/${user!.uid}.jpg');

    final uploadTask = storageRef.putFile(imageFile);
    final taskSnapshot = await uploadTask.whenComplete(() => {});

    final imageUrl = await taskSnapshot.ref.getDownloadURL();

    final userDoc =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    userDoc.get().then((docSnapshot) {
      if (docSnapshot.exists) {
        userDoc.update({'profile_pic_url': imageUrl}).then((_) {
          setState(() {});
        });
      } else {
        userDoc.set({
          'profile_pic_url': imageUrl,
        }).then((_) {
          setState(() {});
        });
      }
    });
    return imageUrl;
  }

  Future<void> _uploadImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      setState(() {});
      await uploadImageToFirebase(imageFile);
    }
  }

  Widget _buildImageSection() {
    final currentUser = FirebaseAuth.instance.currentUser;
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        String? profilePicUrl;
        if (snapshot.hasData) {
          var dataMap = snapshot.data!.data() as Map<String, dynamic>?;
          if (snapshot.data!.exists &&
              dataMap?.containsKey('profile_pic_url') == true) {
            profilePicUrl = dataMap?['profile_pic_url'] as String?;
          }
        }

        return GestureDetector(
          onTap: () async {
            await showModalBottomSheet(
              context: context,
              builder: (context) => _buildImageOptions(context, profilePicUrl),
              backgroundColor: Colors.transparent,
            );
            setState(() {});
          },
          child: profilePicUrl != null
              ? Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                          blurRadius: 15, color: Colors.black.withOpacity(0.3))
                    ],
                    shape: BoxShape.circle,
                    image: DecorationImage(
                        image: NetworkImage(profilePicUrl), fit: BoxFit.cover),
                  ),
                )
              : const CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.camera_alt, size: 40, color: Colors.grey),
                ),
        );
      },
    );
  }

  Widget _buildImageOptions(BuildContext context, String? profilePicUrl) {
    bool hasProfilePicture = profilePicUrl != null && profilePicUrl.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9CDDD),
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (hasProfilePicture) ...[
            ListTile(
              leading: Icon(Icons.remove_red_eye),
              title: Text('View'),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => Dialog(
                    child: Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(profilePicUrl!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.delete),
              title: Text('Delete'),
              onTap: () async {
                final user = FirebaseAuth.instance.currentUser;
                final storageRef = FirebaseStorage.instance
                    .ref()
                    .child('profile_pics/${user!.uid}.jpg');
                await storageRef.delete();
                FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .update({'profile_pic_url': FieldValue.delete()});
                Navigator.pop(context);
              },
            ),
          ],
          ListTile(
            leading: Icon(Icons.upload_file),
            title: Text('Upload'),
            onTap: () {
              Navigator.pop(context);
              _uploadImage();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUserEmail(String? email) {
    return Text(
      username ?? 'Loading...', // Default text while loading username
      style: const TextStyle(
        fontSize: 60,
        color: Color.fromARGB(255, 58, 70, 70),
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
        .update({'bio': bio});
  }

  void _uploadBio(String bio) {
    setState(() {
      _bioController.text = bio;
    });

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
                  color: Color.fromARGB(255, 58, 70, 70),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _bioController.text.isEmpty
                    ? "User's bio comes here..."
                    : _bioController.text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 45,
                  color: Color.fromARGB(255, 58, 70, 70),
                ),
              ),
              const SizedBox(height: 10),
              IconButton(
                onPressed: () {
                  setState(() {
                    _isEditingBio = true;
                  });
                },
                icon: const Icon(
                  Icons.edit,
                  size: 35,
                  color: Color.fromARGB(255, 58, 70, 70),
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 50,
          )
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
          'Gallery',
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
              MaterialPageRoute(builder: (context) => const SavedItineraries()),
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
            color: Color.fromARGB(255, 58, 70, 70),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 25,
              color: Color.fromARGB(255, 58, 70, 70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _signOutButton(BuildContext context) {
    return Container(
      width: 800,
      margin: const EdgeInsets.all(10),
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
                fontSize: 42,
                color: Color(0xFFAD547F),
                fontWeight: FontWeight.w500))),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Load bio and username from Firestore when the profile page initializes
    fetchUsernameFromFirestore().then((retrievedUsername) {
      setState(() {
        username = retrievedUsername ?? '';
      });
    });

    getBioFromFirestore().then((bio) {
      setState(() {
        _bioController.text = bio ?? '';
      });
    });
  }

  Future<String?> fetchUsernameFromFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      if (doc.exists && doc.data()!.containsKey('username')) {
        String retrievedUsername = (doc.data()?['username'] as String?) ?? '';
        print('Retrieved username: $retrievedUsername');
        setState(() {
          username = retrievedUsername;
        });
        return retrievedUsername;
      } else {
        print(
            'No username field found in the document or document does not exist');
        return null;
      }
    } catch (error) {
      print('Error fetching username from Firestore: $error');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 100,
        title: const Text(
          'Profile',
          style: TextStyle(fontFamily: 'Nunito', fontSize: 36),
        ),
        backgroundColor: const Color(0xFFAD547F),
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
      ),
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
              gradient: LinearGradient(
            begin: Alignment.topCenter,
            colors: [const Color(0xFFAD547F), Colors.pink.shade200],
          )),
          child: Column(
            children: [
              Row(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 100, horizontal: 50),
                    child: SizedBox(
                      height: 350,
                      child: Image.asset('lib/images/lakbayan-text-2.png'),
                    ),
                  )
                ],
              ),
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 50),
                    child: Container(
                      decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(100),
                              topRight: Radius.circular(100),
                              bottomLeft: Radius.circular(100),
                              bottomRight: Radius.circular(100)),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black38,
                                spreadRadius: 0,
                                blurRadius: 20),
                          ]),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 80),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Center(
                                child: _buildImageSection()), // Profile image
                            Center(child: _buildUserEmail(currentUser?.email)),
                            const SizedBox(height: 20),
                            _buildBioSection(), // Bio section
                            _buildSectionIcons(context), // Bio section
                            // Add more sections here as needed
                            const SizedBox(height: 50),
                            Center(
                                child:
                                    _signOutButton(context)), // Sign-out button
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
