import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PostCard extends StatefulWidget {
  final DocumentSnapshot post;
  final DocumentSnapshot userData;
  final String userId; // Current User ID

  const PostCard({
    Key? key,
    required this.post,
    required this.userData,
    required this.userId, // Initialize userId
  }) : super(key: key);

  @override
  _PostCardState createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late TextEditingController _commentController;
  final _formKey = GlobalKey<FormState>();
  bool isLiked = false; // Track if the current user has liked the post

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController();
    checkIfLiked(); // Check if the current user has liked the post initially
  }

  void checkIfLiked() async {
    final postId = widget.post.id;
    final userId = widget.userId; // Use the userId passed from the parent widget
    
    DocumentSnapshot likeDoc = await FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .collection('likes')
        .doc(userId)
        .get();

        // print("Check if liked: ${likeDoc.exists}"); // Debug print


    setState(() {
      isLiked = likeDoc.exists;
    });
  }

  void toggleLike() async {
  final postId = widget.post.id;
  final userId = widget.userId; // Ensure this is the correct user ID
  
  // print("Toggle like for userId $userId, current isLiked: $isLiked"); // Debug print
  
  if (isLiked) {
    // If already liked, then unlike the post
    // print("Unliking the post"); // Debug print
    await FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .collection('likes')
        .doc(userId)
        .delete();
    await FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .update({'likes': FieldValue.increment(-1)});
  } else {
    // If not liked, then like the post
    // print("Liking the post"); // Debug print
    await FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .collection('likes')
        .doc(userId)
        .set({});
    await FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .update({'likes': FieldValue.increment(1)});
  }

  // Update the isLiked state
  setState(() {
    isLiked = !isLiked;
  });
}


  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

    void showCommentsDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Comments'),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // StreamBuilder to display the list of comments
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('posts')
                    .doc(widget.post.id)
                    .collection('comments')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return CircularProgressIndicator();
                  }
                  final comments = snapshot.data!.docs;
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final comment = comments[index].data() as Map<String, dynamic>;
                      return ListTile(
                        title: Text(comment['username']),
                        subtitle: Text(comment['text']),
                      );
                    },
                  );
                },
              ),
              // TextField to add a new comment
              TextFormField(
                controller: _commentController,
                decoration: InputDecoration(
                  labelText: 'Write a comment...',
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              // Code to add a new comment
            },
            child: Text('Post Comment'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final userData = widget.userData.data() as Map<String, dynamic>;
    final userProfilePic = userData.containsKey('profile_pic_url')
        ? userData['profile_pic_url']
        : 'https://i.pinimg.com/originals/f1/0f/f7/f10ff70a7155e5ab666bcdd1b45b726d.jpg';
    final postId = post.id;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(userProfilePic),
                  ),
                  SizedBox(width: 8.0),
                  Text(
                    post['username'] ?? 'Username',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 8.0),
              if (post['imageURL'] != null &&
                  post['imageURL'].isNotEmpty &&
                  Uri.parse(post['imageURL']).isAbsolute)
                Image.network(
                  post['imageURL'],
                  height: 100,
                  width: 100,
                  fit: BoxFit.cover,
                ),
              SizedBox(height: 8.0),
              Text(post['text'] ?? ''),
              Row(
              children: [
                IconButton(
                  icon: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? Colors.red : null,
                  ),
                  onPressed: toggleLike,
                ),
                Text(post['likes']?.toString() ?? '0'),
                IconButton(
                  icon: Icon(Icons.star_border),
                  onPressed: () {
                    FirebaseFirestore.instance
                        .collection('posts')
                        .doc(postId)
                        .update({
                      'saves': FieldValue.increment(1),
                    });
                  },
                ),
                IconButton(
            icon: Icon(Icons.comment),
            onPressed: showCommentsDialog,
          ),
              ],
            ),
            ]    
      ),
        )
      )
    );
  }
}
