import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    setState(() {
      isLiked = likeDoc.exists;
    });
  }

  Future<void> _toggleLike() async {
    if (isLiked) {
      await _unlikePost();
    } else {
      await _likePost();
    }
    setState(() {
      isLiked = !isLiked;
    });
  }

  Future<void> _likePost() async {
    await _likesCollection.doc(widget.userId).set({});
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

  void _editPost() {
    TextEditingController editController =
        TextEditingController(text: widget.post['text']);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Post'),
        content: TextField(controller: editController),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await _postsCollection
                  .doc(widget.post.id)
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Comments'),
        content: _buildCommentContent(),
        actions: [
          ElevatedButton(
            onPressed: () async {
              final commentText = _commentController.text.trim();
              if (commentText.isNotEmpty) {
                await _commentsCollection.add({
                  'userId': widget.userId,
                  'username': (widget.userData.data()
                      as Map<String, dynamic>)['username'],
                  'text': commentText,
                  'timestamp': FieldValue.serverTimestamp(),
                });
                _commentController.clear();
              }
            },
            child: const Text('Post Comment'),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentContent() {
    return SizedBox(
      width: double.maxFinite,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: _commentsCollection
                .orderBy('timestamp', descending: true)
                .snapshots(),
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
            controller: _commentController,
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
