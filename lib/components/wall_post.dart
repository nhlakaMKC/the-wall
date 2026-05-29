import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:the_wall/components/comment.dart';
import 'package:the_wall/components/comment_button.dart';
import 'package:the_wall/components/delete_button.dart';
import 'package:the_wall/components/like_button.dart';
import 'package:the_wall/helper.dart/helper_methods.dart';

class WallPost extends StatefulWidget {
  final String message;
  final String user;
  final String time;
  final String postId;
  final List<String> likes;

  const WallPost({
    super.key,
    required this.message,
    required this.user,
    required this.postId,
    required this.likes,
    required this.time,
  });

  @override
  State<WallPost> createState() => _WallPostState();
}

class _WallPostState extends State<WallPost> {
  //user
  final currentUser = FirebaseAuth.instance.currentUser!;
  bool isLiked = false;
  final TextEditingController _commentTextController = TextEditingController();
  final TextEditingController _editPostController = TextEditingController();
  String? _userProfileImageUrl;
  String? _username;
  String _currentMessage = '';

  @override
  void initState() {
    super.initState();
    isLiked = widget.likes.contains(currentUser.email);
    _currentMessage = widget.message;
    _fetchUserData();
  }

  @override
  void dispose() {
    _commentTextController.dispose();
    _editPostController.dispose();
    super.dispose();
  }

  // Fetch user profile image and username
  Future<void> _fetchUserData() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection("Users")
          .doc(widget.user)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _userProfileImageUrl = userData['profileImageUrl'];
            _username = userData['username'] ?? widget.user;
          });
        }
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  //toggle like
  void toogleLike() {
    setState(() {
      isLiked = !isLiked;
    });

    //access the document in firebase
    DocumentReference postRef = FirebaseFirestore.instance
        .collection("User Posts")
        .doc(widget.postId);

    if (isLiked) {
      //if the post is liked , add the user to the 'Likes' field
      postRef.update({
        'Likes': FieldValue.arrayUnion([currentUser.email]),
      });
    } else {
      //if the post is unliked, remove the user from the 'Likes' field
      postRef.update({
        'Likes': FieldValue.arrayRemove([currentUser.email]),
      });
    }
  }

  //add a comment
  void addComment(String commentText) {
    //write the comment to firestore under the comment colllection for this post
    FirebaseFirestore.instance
        .collection("User Posts")
        .doc(widget.postId)
        .collection("Comments")
        .add({
          'CommentText': commentText,
          'CommentedBy': currentUser.email,
          'CommentTime': Timestamp.now(),
        });
  }

  //edit post
  void editPost(String newMessage) async {
    try {
      await FirebaseFirestore.instance
          .collection("User Posts")
          .doc(widget.postId)
          .update({'Message': newMessage});

      if (mounted) {
        setState(() {
          _currentMessage = newMessage;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating post: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  //show a dialog to add a comment
  void showCommentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add a comment'),
        content: TextField(
          controller: _commentTextController,
          decoration: InputDecoration(hintText: 'Write your comment here'),
        ),
        actions: [
          //cancel button
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _commentTextController.clear();
            },
            child: Text('Cancel'),
          ),

          //save button
          TextButton(
            onPressed: () {
              if (_commentTextController.text.trim().isNotEmpty) {
                addComment(_commentTextController.text);
                Navigator.of(context).pop();
                _commentTextController.clear();
                //hide the keyboard
                FocusScope.of(context).unfocus();
              }
            },
            child: Text('Post'),
          ),
        ],
      ),
    );
  }

  //show dialog to edit post
  void showEditPostDialog() {
    _editPostController.text = _currentMessage;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Post'),
        content: TextField(
          controller: _editPostController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Edit your post...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          //cancel button
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _editPostController.clear();
            },
            child: Text('Cancel'),
          ),

          //save button
          TextButton(
            onPressed: () {
              if (_editPostController.text.trim().isNotEmpty) {
                editPost(_editPostController.text.trim());
                Navigator.of(context).pop();
                _editPostController.clear();
                //hide the keyboard
                FocusScope.of(context).unfocus();
              }
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void deletePost() {
    //confirm deletion
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Post'),
        content: Text('Are you sure you want to delete this post?'),
        actions: [
          //cancel button
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),

          ///delete button
          TextButton(
            onPressed: () async {
              //delete the comments first
              final commentDocs = await FirebaseFirestore.instance
                  .collection("User Posts")
                  .doc(widget.postId)
                  .collection("Comments")
                  .get();

              for (var doc in commentDocs.docs) {
                await FirebaseFirestore.instance
                    .collection("User Posts")
                    .doc(widget.postId)
                    .collection("Comments")
                    .doc(doc.id)
                    .delete();
              }

              //delete the post
              await FirebaseFirestore.instance
                  .collection("User Posts")
                  .doc(widget.postId)
                  .delete()
                  .then((value) => print('Post deleted'))
                  .catchError(
                    (error) => print("failed to delete post: $error"),
                  );

              //close the dialog
              Navigator.pop(context);
            },
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      margin: EdgeInsets.only(top: 25, left: 25, right: 25),
      padding: EdgeInsets.all(25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 20),
          //wall post
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User info with profile image
                    Row(
                      children: [
                        // Profile image
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surface,
                          backgroundImage: _userProfileImageUrl != null
                              ? NetworkImage(_userProfileImageUrl!)
                              : null,
                          child: _userProfileImageUrl == null
                              ? Icon(
                                  Icons.person,
                                  size: 16,
                                  color: Colors.grey[600],
                                )
                              : null,
                        ),

                        const SizedBox(width: 8),

                        // Username and time
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Username
                              Text(
                                _username ?? widget.user,
                                style: TextStyle(
                                  color: Colors.grey[800],
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),

                              // Post time
                              Text(
                                widget.time,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),
                    //post message
                    Text(_currentMessage),
                  ],
                ),
              ),

              //edit and delete options if the post belongs to the current user
              if (widget.user == currentUser.email)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Edit button
                    IconButton(
                      onPressed: showEditPostDialog,
                      icon: Icon(Icons.edit, color: Colors.grey[600], size: 20),
                      tooltip: 'Edit post',
                    ),
                    // Delete button
                    DeleteButton(onTap: deletePost),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              //Like section
              Row(
                children: [
                  LikeButton(isLiked: isLiked, onTap: toogleLike),

                  const SizedBox(width: 5),
                  //like count
                  Text(widget.likes.length.toString()),
                ],
              ),

              const SizedBox(width: 20),

              ///comment section
              Row(
                children: [
                  CommentButton(onTap: showCommentDialog),

                  const SizedBox(width: 5),
                  //comment count - let's show actual count
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection("User Posts")
                        .doc(widget.postId)
                        .collection("Comments")
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Text(snapshot.data!.docs.length.toString());
                      }
                      return Text('0');
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          //comments section
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("User Posts")
                .doc(widget.postId)
                .collection("Comments")
                .orderBy("CommentTime", descending: false)
                .snapshots(),
            builder: (context, snapShot) {
              // show loading indicator while waiting for data
              if (!snapShot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              return ListView(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                children: snapShot.data!.docs.map((doc) {
                  //get comment data
                  final commentData = doc.data() as Map<String, dynamic>;

                  //return the comments
                  return Comment(
                    text: commentData["CommentText"] ?? '',
                    user: commentData["CommentedBy"] ?? '',
                    time: formatDate(commentData["CommentTime"]),
                    commentId: doc.id, // Pass comment ID for editing
                    postId: widget.postId, // Pass post ID for reference
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
