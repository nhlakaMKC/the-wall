import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Comment extends StatefulWidget {
  final String text;
  final String user;
  final String time;
  final String commentId;
  final String postId;

  const Comment({
    super.key,
    required this.text,
    required this.user,
    required this.time,
    required this.commentId,
    required this.postId,
  });

  @override
  State<Comment> createState() => _CommentState();
}

class _CommentState extends State<Comment> {
  String? _userProfileImageUrl;
  String? _username;
  bool _isLoading = true;
  String _currentCommentText = '';
  final TextEditingController _editCommentController = TextEditingController();
  final currentUser = FirebaseAuth.instance.currentUser!;

  @override
  void initState() {
    super.initState();
    _currentCommentText = widget.text;
    _fetchUserData();
  }

  @override
  void dispose() {
    _editCommentController.dispose();
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
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _username = widget.user;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching user data for comment: $e');
      if (mounted) {
        setState(() {
          _username = widget.user;
          _isLoading = false;
        });
      }
    }
  }

  // Edit comment
  Future<void> editComment(String newText) async {
    try {
      await FirebaseFirestore.instance
          .collection("User Posts")
          .doc(widget.postId)
          .collection("Comments")
          .doc(widget.commentId)
          .update({'CommentText': newText});

      if (mounted) {
        setState(() {
          _currentCommentText = newText;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comment updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating comment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Delete comment
  Future<void> deleteComment() async {
    try {
      await FirebaseFirestore.instance
          .collection("User Posts")
          .doc(widget.postId)
          .collection("Comments")
          .doc(widget.commentId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comment deleted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting comment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Show edit comment dialog
  void showEditCommentDialog() {
    _editCommentController.text = _currentCommentText;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Comment'),
        content: TextField(
          controller: _editCommentController,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'Edit your comment...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          //cancel button
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _editCommentController.clear();
            },
            child: Text('Cancel'),
          ),

          //save button
          TextButton(
            onPressed: () {
              if (_editCommentController.text.trim().isNotEmpty) {
                editComment(_editCommentController.text.trim());
                Navigator.of(context).pop();
                _editCommentController.clear();
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

  // Show delete comment dialog
  void showDeleteCommentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Comment'),
        content: Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              deleteComment();
              Navigator.of(context).pop();
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(4),
      ),
      margin: EdgeInsets.only(bottom: 5),
      padding: EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info with profile image and options
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // User info section
              Expanded(
                child: Row(
                  children: [
                    // Profile image
                    _isLoading
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.grey[400],
                            ),
                          )
                        : CircleAvatar(
                            radius: 8,
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.surface,
                            backgroundImage: _userProfileImageUrl != null
                                ? NetworkImage(_userProfileImageUrl!)
                                : null,
                            child: _userProfileImageUrl == null
                                ? Icon(
                                    Icons.person,
                                    size: 12,
                                    color: Colors.grey[600],
                                  )
                                : null,
                          ),

                    const SizedBox(width: 6),

                    // Username and time
                    Flexible(
                      child: Row(
                        children: [
                          // Username
                          Flexible(
                            child: Text(
                              _isLoading
                                  ? widget.user
                                  : (_username ?? widget.user),
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          // Separator
                          Text(
                            ' • ',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),

                          // Time
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
              ),

              // Edit and delete options (only for comment owner)
              if (widget.user == currentUser.email)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Edit button
                    IconButton(
                      onPressed: showEditCommentDialog,
                      icon: Icon(Icons.edit, color: Colors.grey[600], size: 16),
                      constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: EdgeInsets.all(4),
                      tooltip: 'Edit comment',
                    ),
                    // Delete button
                    IconButton(
                      onPressed: showDeleteCommentDialog,
                      icon: Icon(
                        Icons.delete,
                        color: Colors.grey[600],
                        size: 16,
                      ),
                      constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: EdgeInsets.all(4),
                      tooltip: 'Delete comment',
                    ),
                  ],
                ),
            ],
          ),

          const SizedBox(height: 8),

          // Comment text
          Text(
            _currentCommentText,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
    );
  }
}
