import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lakbayan/auth.dart';
import 'package:lakbayan/pages/create_itinerary_page.dart';
import 'package:lakbayan/pages/login_register_page.dart';
import 'package:lakbayan/homepage_Files/custom_nav_bar.dart';
import 'package:lakbayan/homepage_Files/destination_service.dart';
import 'package:lakbayan/homepage_Files/itinerary_card.dart';
import 'package:lakbayan/homepage_Files/lakbayan_Feed.dart';
>>>>>>> 0bc3cf139490d40df23264daed5e6201e5d665e8

class HomePage extends StatefulWidget {
  HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final User? user = Auth().currentUser;
  String? username;

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _postController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
    migrateSharedItineraries();
  }

  _checkAuthentication() async {
    final user = Auth().currentUser;
    print("Current user ID: ${user}");


    if (user == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    } else {
      // Fetch the username from Firestore
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      setState(() {
        username = docSnapshot.data()?['username'];
      });
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: TextStyle(
            fontSize: fontSize,
          ),
        ),
        Text(
          nameToShow,
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _createItinerary(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CreateItineraryPage()),
        );
      },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: const Text(
        '+ Create Itinerary',
        style: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.bold,
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
        child: Image.asset('lib/images/dvo_logo.png'),
      ),
    );
  }

  Future<void> _createPost() async {
    final text = _postController.text;
    if (text.isEmpty && _selectedImage == null) return;

    // Placeholder for imageURL
    String? imageURL;

    // If an image is selected, convert it to JPEG and upload it to Firebase Storage
    if (_selectedImage != null) {
      // Compress image to JPEG format
      final Uint8List? compressedImage =
          await FlutterImageCompress.compressWithFile(
        _selectedImage!.path,
        format: CompressFormat.jpeg,
      );

      if (compressedImage != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('post_images')
            .child('${DateTime.now().toIso8601String()}.jpg');

        // Upload the compressed JPEG image
        await ref.putData(compressedImage);
        imageURL = await ref.getDownloadURL();
      }
    }

    // Add the post to Firestore
    await FirebaseFirestore.instance.collection('posts').add({
      'userId': user?.uid,
      'username': username,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'imageURL': imageURL,
      'likes': 0,
      'saves': 0,
    });

    // Clear the text field and the selected image
    _postController.clear();
    setState(() {
      _selectedImage = null;
      Navigator.pop(context); // Close the bottom sheet
    });
  }

  Widget _createPostSection() {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) => StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return FractionallySizedBox(
                heightFactor: 0.75, // posting mode container height
                child: Container(
                  padding: EdgeInsets.all(16.0),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(8.0),
                      topRight: Radius.circular(8.0),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: Icon(Icons.close),
                            onPressed: () {
                              Navigator.pop(context); // Close the bottom sheet
                            },
                          ),
                          ElevatedButton(
                            onPressed: _createPost,
                            child: Text('Post'),
                          ),
                        ],
                      ),
                      Divider(),
                      Expanded(
                        child: TextField(
                          controller: _postController,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Share Your Adventure!',
                          ),
                          maxLines: null,
                        ),
                      ),
                      if (_selectedImage != null)
                        Image.file(
                          _selectedImage!,
                          height: 300,
                          width: 300,
                          fit: BoxFit.cover,
                        ),
                      SizedBox(height: 10.0),
                      ElevatedButton(
                        onPressed: () async {
                          final pickedFile = await _picker.getImage(
                              source: ImageSource.gallery);
                          if (pickedFile != null) {
                            setState(() {
                              _selectedImage = File(pickedFile.path);
                            });
                          }
                        },
                        child: Text('Photo Upload'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            'Share Your Adventure!',
            style: TextStyle(fontSize: 20),
          ),
        ),
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
        toolbarHeight: 90,
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
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: ListView(
              children: <Widget>[
                Center(child: _davaoImage(context)),
                const SizedBox(height: 20),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Popular Destinations',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 50,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: fetchNearbyDestinations(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return Text(
                        'Error: ${snapshot.error}',
                        style: TextStyle(fontSize: 50),
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
                //LAKBAYAN CONTAINER
                Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: const Color(
                          0xFFAD547F), // Set the background color of the container
                      borderRadius:
                          BorderRadius.circular(8.0), // Set rounded corners
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'LAKBAYAN FEED',
                          style: TextStyle(
                            fontSize: 50, // Adjust the font size as needed
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Nunito',
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 20.0), // Adjust the spacing as needed
                        _createPostSection(),
                        const SizedBox(height: 20),
                        lakbayanFeed(context),
                      ],
                    )),
              ],
            ),
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
