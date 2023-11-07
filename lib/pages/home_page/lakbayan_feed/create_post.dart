import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreatePost {
  final User? user;
  final String? username;
  final BuildContext context;
  final TextEditingController _postController = TextEditingController();
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  StateSetter? _setLocalState;

  CreatePost(
      {required this.user, required this.username, required this.context});

  Future<void> _create() async {
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
    _setLocalState!(() {
      _selectedImage = null;
    });
    // ignore: use_build_context_synchronously
    Navigator.pop(context);
  }

Widget section() {
  return GestureDetector(
    onTap: () {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            _setLocalState = setState;
            return FractionallySizedBox(
              heightFactor: 0.75, // posting mode container height
              child: Container(
                padding: const EdgeInsets.all(16.0),
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
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            Navigator.pop(context); // Close the bottom sheet
                          },
                        ),
                        ElevatedButton(
                          onPressed: _create,
                          child: const Text('Post'),
                        ),
                      ],
                    ),
                    const Divider(),
                    Expanded(
                      child: TextField(
                        controller: _postController,
                        decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Share Your Adventure!',
                            hintStyle: TextStyle(fontFamily: 'Nunito')),
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
                    const SizedBox(height: 10.0),
                    ElevatedButton(
                      onPressed: () async {
                        // ignore: deprecated_member_use
                        final pickedFile = await _picker.getImage(
                            source: ImageSource.gallery);
                        if (pickedFile != null) {
                          setState(() {
                            _selectedImage = File(pickedFile.path);
                          });
                        }
                      },
                      child: const Text('Photo Upload',
                          style: TextStyle(fontFamily: 'Nunito')),
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
      padding: const EdgeInsets.all(16.0),
      constraints: BoxConstraints(
        maxWidth: 600, // This is the maximum width you want for your button
      ),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: Text(
          'Share Your Adventure!',
          style: TextStyle(fontSize: 20),
        ),
      ),
    ),
  );
}
}