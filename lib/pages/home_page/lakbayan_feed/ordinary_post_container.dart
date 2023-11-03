import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:firebase_auth/firebase_auth.dart';

class PostCard extends StatefulWidget {
  final DocumentSnapshot post;
  final DocumentSnapshot userData;
  final String userId;

  const PostCard({
    Key? key,
    required this.post,
    required this.userData,
    required this.userId,
  }) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _PostCardState createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late TextEditingController _commentController;
  final _formKey = GlobalKey<FormState>();
  bool isLiked = false;

  CollectionReference get _postsCollection =>
      FirebaseFirestore.instance.collection('posts');
  late CollectionReference _likesCollection;
  late CollectionReference _commentsCollection;

   Future<XFile?> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    // Pick an image
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    return image;
  }

   Future<String?> _uploadImage(XFile? image) async {
    if (image == null) return null;

    firebase_storage.UploadTask uploadTask;
    firebase_storage.Reference ref = firebase_storage.FirebaseStorage.instance
        .ref()
        .child('path/to/your/directory/${DateTime.now().toIso8601String() + '_' + image.name}');

    uploadTask = ref.putFile(File(image.path));

    final url = await (await uploadTask).ref.getDownloadURL();
    return url; // URL of the uploaded image
  }

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController();
    _likesCollection = _postsCollection.doc(widget.post.id).collection('likes');
    _commentsCollection =
        _postsCollection.doc(widget.post.id).collection('comments');
    _checkIfLiked();
  }

  Future<void> _checkIfLiked() async {
    DocumentSnapshot likeDoc = await _likesCollection.doc(widget.userId).get();
    print("Check if liked: ${likeDoc.exists}");
    setState(() {
      isLiked = likeDoc.exists;
    });
  }

  Future<void> _toggleLike() async {
    final userId = widget.userId;
    print("Toggle like for userId $userId, current isLiked: $isLiked");
    if (isLiked) {
      print("Unliking the post");
      await _unlikePost();
    } else {
      print("Post is liked.");
      await _likePost();
    }
    setState(() {
      isLiked = !isLiked;
      print("isLiked set to: $isLiked");
    });
  }

Future<void> _likePost() async {
  // Fetch the username from Firestore
  DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
  String username = userDoc['username'] ?? 'Anonymous'; // Default to 'Anonymous' if username is not found
  // Set the like with the username
  await _likesCollection.doc(widget.userId).set({
    'userId': widget.userId,
    'username': username, // Include the username
  });
  await _updatePostLikes(1);
}


  Future<void> _unlikePost() async {
    await _likesCollection.doc(widget.userId).delete();
    await _updatePostLikes(-1);
  }

  Future<void> _updatePostLikes(int increment) async {

    await _postsCollection
        .doc(widget.post.id)
        .update({'likes': FieldValue.increment(increment)});
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post.data() as Map<String, dynamic>;
    final userData = widget.userData.data() as Map<String, dynamic>;
    final userProfilePic = userData['profile_pic_url'] ??
        'https://i.pinimg.com/originals/f1/0f/f7/f10ff70a7155e5ab666bcdd1b45b726d.jpg';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 200),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundImage: NetworkImage(userProfilePic),
                          ),
                          const SizedBox(width: 8.0),
                          Text(
                            post['username'] ?? 'Username',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      if (widget.userId == post['userId']) _buildPostActions(),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  if (post['imageURL']?.isNotEmpty ?? false)
                    Image.network(
                      post['imageURL']!,
                      height: 500,
                      width: 500,
                      fit: BoxFit.cover,
                    ),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      Text(
                        post['username'] ?? 'Username',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(' '),
                      Text(post['text'] ?? ''),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: isLiked ? Colors.red : null,
                        ),
                        onPressed: _toggleLike,
                      ),
                      Text(post['likes']?.toString() ?? '0'),
                      IconButton(
                        icon: const Icon(Icons.star_border),
                        onPressed: () => _postsCollection
                            .doc(widget.post.id)
                            .update({'saves': FieldValue.increment(1)}),
                      ),
                      IconButton(
                        icon: const Icon(Icons.comment),
                        onPressed: _showCommentsDialog,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPostActions() {
    return PopupMenuButton<String>(
      onSelected: (String result) {
        if (result == 'edit') {
          _editPost();
        } else if (result == 'delete') {
          _deletePost();
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'edit',
          child: Text('Edit'),
        ),
        const PopupMenuItem<String>(
          value: 'delete',
          child: Text('Delete'),
        ),
      ],
    );
  }

void _editPost() async {
  TextEditingController editController = TextEditingController(text: widget.post['text']);
  XFile? newImage;
  bool deleteImage = false;  // Flag to track if user wants to delete the image

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Edit Post'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: editController),
          TextButton(
            onPressed: () async {
              newImage = await _pickImage();
              // Optionally add an image preview here
              deleteImage = false; // Reset deleteImage flag if new image is picked
            },
            child: const Text('Pick a New Image'),
          ),
          if (widget.post['imageURL'] != null && widget.post['imageURL'].isNotEmpty)
            TextButton(
              onPressed: () {
                // Set deleteImage to true to indicate the image should be deleted
                deleteImage = true;
              },
              child: const Text('Delete Current Image'),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel')
        ),
        TextButton(
          onPressed: () async {
            String? newImageUrl;
            if (newImage != null) {
              // If a new image was picked, upload it
              newImageUrl = await _uploadImage(newImage);
            } else if (deleteImage) {
              // If deleteImage is true, set newImageUrl to null
              newImageUrl = null;
            } else {
              // Otherwise, keep the old image URL
              newImageUrl = widget.post['imageURL'];
            }
            await _postsCollection.doc(widget.post.id).update({
              'text': editController.text,
              'imageURL': newImageUrl // Update with new image URL, null, or keep the old one
            });
            Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}





  void _deletePost() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this post?'),
          actions: <Widget>[
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                await _postsCollection.doc(widget.post.id).delete();
                // ignore: use_build_context_synchronously
                Navigator.of(context).pop();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showCommentsDialog() {
  // Declare a local TextEditingController
  TextEditingController commentController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Comments'),
      content: _buildCommentContent(commentController), // Pass the controller to the build method
      actions: [
        ElevatedButton(
          onPressed: () async {
            final commentText = commentController.text.trim();
            if (commentText.isNotEmpty) {
              await _commentsCollection.add({
                'userId': widget.userId,
                'username': (widget.userData.data() as Map<String, dynamic>)['username'],
                'text': commentText,
                'timestamp': FieldValue.serverTimestamp(),
              });
              commentController.clear(); // Clear the text field
            }
          },
          child: const Text('Post Comment'),
        ),
      ],
    ),
  );
}

  Widget _buildCommentContent(TextEditingController commentController) {
  return SizedBox(
    width: double.maxFinite,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        StreamBuilder<QuerySnapshot>(
            stream: _commentsCollection.orderBy('timestamp', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const CircularProgressIndicator();
              final comments = snapshot.data!.docs;
              return ListView.builder(
                shrinkWrap: true,
                itemCount: comments.length,
                itemBuilder: (context, index) {
                  final comment =
                      comments[index].data() as Map<String, dynamic>;
                  return ListTile(
                    title: Text(comment['username']),
                    subtitle: Text(comment['text']),
                    trailing: _buildCommentActions(comments[index]),
                  );
                },
              );
            },
          ),
        TextFormField(
          controller: commentController,
          decoration: const InputDecoration(labelText: 'Write a comment...'),
        ),
      ],
    ),
  );
}

  Widget _buildCommentActions(DocumentSnapshot comment) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'edit') {
          _editComment(comment);
        } else if (value == 'delete') {
          _deleteComment(comment);
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(value: 'edit', child: Text('Edit')),
        const PopupMenuItem<String>(value: 'delete', child: Text('Delete')),
      ],
    );
  }

  void _editComment(DocumentSnapshot comment) {
    TextEditingController editController =
        TextEditingController(text: comment['text']);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Comment'),
        content: TextField(controller: editController),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await _commentsCollection
                  .doc(comment.id)
                  .update({'text': editController.text});
              // ignore: use_build_context_synchronously
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteComment(DocumentSnapshot comment) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this comment?'),
          actions: <Widget>[
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                await _commentsCollection.doc(comment.id).delete();
                // ignore: use_build_context_synchronously
                Navigator.of(context).pop();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
