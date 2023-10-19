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
    final userId =
        widget.userId; // Use the userId passed from the parent widget

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
  TextEditingController commentController = TextEditingController();

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
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) async {
                          final commentId = comments[index].id;
                          if (value == 'edit') {
                            final TextEditingController editController =
                                TextEditingController(text: comment['text']);
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Edit Comment'),
                                content: TextField(
                                  controller: editController,
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop(); // Close the dialog
                                    },
                                    child: Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      await FirebaseFirestore.instance
                                          .collection('posts')
                                          .doc(widget.post.id)
                                          .collection('comments')
                                          .doc(commentId)
                                          .update({'text': editController.text});
                                      Navigator.of(context).pop(); // Close the dialog
                                    },
                                    child: Text('Save'),
                                  ),
                                ],
                              ),
                            );
                          } else if (value == 'delete') {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text('Confirm Delete'),
                                  content: Text('Are you sure you want to delete this comment?'),
                                  actions: <Widget>[
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop(); // Close the dialog
                                      },
                                      child: Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        await FirebaseFirestore.instance
                                            .collection('posts')
                                            .doc(widget.post.id)
                                            .collection('comments')
                                            .doc(commentId)
                                            .delete();
                                        Navigator.of(context).pop(); // Close the dialog
                                      },
                                      child: Text('Delete'),
                                    ),
                                  ],
                                );
                              },
                            );
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
                      ),
                    );
                  },
                );
              },
            ),
            // TextField to add a new comment
            TextFormField(
              controller: commentController,
              decoration: InputDecoration(
                labelText: 'Write a comment...',
              ),
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () async {
            // Get the text from the controller
            final commentText = commentController.text.trim();

            // Check if the comment text is not empty
            if (commentText.isNotEmpty) {
              // Add the comment to Firestore
              await FirebaseFirestore.instance
                  .collection('posts')
                  .doc(widget.post.id)
                  .collection('comments')
                  .add({
                'userId': widget.userId, // Use the current user's ID
                'username': (widget.userData.data() as Map<String, dynamic>)['username'], // Use the current user's username
                'text': commentText,
                'timestamp': FieldValue.serverTimestamp(),
              });

              // Clear the controller
              commentController.clear();
            }
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        if (widget.userId == post['userId']) // If it's the current user's post
                          PopupMenuButton<String>(
                            onSelected: (String result) async {
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
                  ]),
            )));
  }

  void _editPost() {
    TextEditingController editController = TextEditingController(text: widget.post['text']);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Post'),
        content: TextField(
          controller: editController,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Update the post in Firestore
              await FirebaseFirestore.instance
                  .collection('posts')
                  .doc(widget.post.id)
                  .update({'text': editController.text});
              Navigator.of(context).pop(); // Close the dialog
            },
            child: Text('Save'),
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
          title: Text('Confirm Delete'),
          content: Text('Are you sure you want to delete this post?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // Delete the post from Firestore
                await FirebaseFirestore.instance.collection('posts').doc(widget.post.id).delete();
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }
  void _editComment(DocumentSnapshot comment) {
  TextEditingController editController = TextEditingController(text: comment['text']);
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Edit Comment'),
      content: TextField(
        controller: editController,
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog
          },
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            // Update the comment in Firestore
            await FirebaseFirestore.instance
                .collection('posts')
                .doc(widget.post.id)
                .collection('comments')
                .doc(comment.id)
                .update({'text': editController.text});
            Navigator.of(context).pop(); // Close the dialog
          },
          child: Text('Save'),
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
        title: Text('Confirm Delete'),
        content: Text('Are you sure you want to delete this comment?'),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Delete the comment from Firestore
              await FirebaseFirestore.instance
                  .collection('posts')
                  .doc(widget.post.id)
                  .collection('comments')
                  .doc(comment.id)
                  .delete();
              Navigator.of(context).pop(); // Close the dialog
            },
            child: Text('Delete'),
          ),
        ],
      );
    },
  );
}

}