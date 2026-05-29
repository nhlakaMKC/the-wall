import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class UserImagePicker extends StatefulWidget {
  const UserImagePicker({super.key});

  @override
  State<UserImagePicker> createState() => _UserImagePickerState();
}

class _UserImagePickerState extends State<UserImagePicker> {
  File? _pickedImageFile;
  bool _isUploading = false;
  String? _profileImageUrl;
  final currentUser = FirebaseAuth.instance.currentUser!;

  @override
  void initState() {
    super.initState();
    _loadUserProfileImage();
  }

  // Load existing profile image URL from Firestore
  void _loadUserProfileImage() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection("Users")
          .doc(currentUser.email)
          .get();
      
      if (userDoc.exists && userDoc.data()!.containsKey('profileImageUrl')) {
        setState(() {
          _profileImageUrl = userDoc.data()!['profileImageUrl'];
        });
      }
    } catch (e) {
      print('Error loading profile image: $e');
    }
  }

  // Pick image from gallery function
  void _pickImage() async {
    final pickedImage = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 50,
      maxWidth: 150,
    );

    if (pickedImage == null) {
      return;
    }

    setState(() {
      _pickedImageFile = File(pickedImage.path);
    });
  }

  // Upload image to Firebase Storage
  Future<void> _uploadImage() async {
    if (_pickedImageFile == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      // Create a reference to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('user_images')
          .child('${currentUser.uid}.jpg');

      // Upload the file
      final uploadTask = storageRef.putFile(_pickedImageFile!);
      
      // Wait for upload to complete
      final snapshot = await uploadTask.whenComplete(() {});
      
      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Update user document in Firestore with image URL
      await FirebaseFirestore.instance
          .collection("Users")
          .doc(currentUser.email)
          .update({'profileImageUrl': downloadUrl});

      // Update local state
      setState(() {
        _profileImageUrl = downloadUrl;
        _pickedImageFile = null; // Clear picked image since it's now uploaded
        _isUploading = false;
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile image uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Get image provider based on current state
  ImageProvider? _getImageProvider() {
    if (_pickedImageFile != null) {
      // Show newly picked image
      return FileImage(_pickedImageFile!);
    } else if (_profileImageUrl != null) {
      // Show existing profile image from Firebase
      return NetworkImage(_profileImageUrl!);
    }
    return null; // Show default avatar
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // User image
        CircleAvatar(
          radius: 40,
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundImage: _getImageProvider(),
          child: _getImageProvider() == null
              ? Icon(
                  Icons.person,
                  size: 40,
                  color: Theme.of(context).colorScheme.onPrimary,
                )
              : null,
        ),

        const SizedBox(height: 10),

        // Add/Change image button
        TextButton.icon(
          onPressed: _isUploading ? null : _pickImage,
          label: Text(
            _profileImageUrl != null ? 'Change Image' : 'Add Image',
            style: TextStyle(
              color: _isUploading 
                  ? Colors.grey 
                  : Theme.of(context).colorScheme.onSecondary,
            ),
          ),
          icon: Icon(
            Icons.image,
            color: _isUploading 
                ? Colors.grey 
                : Theme.of(context).colorScheme.onSecondary,
          ),
        ),

        // Upload image button (only show when image is picked)
        if (_pickedImageFile != null)
          TextButton.icon(
            onPressed: _isUploading ? null : _uploadImage,
            label: Text(
              _isUploading ? 'Uploading...' : 'Upload Image',
              style: TextStyle(
                color: _isUploading 
                    ? Colors.grey 
                    : Theme.of(context).colorScheme.onSecondary,
              ),
            ),
            icon: _isUploading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                    ),
                  )
                : Icon(
                    Icons.upload,
                    color: Theme.of(context).colorScheme.onSecondary,
                  ),
          ),

        // Remove image button (only show when there's an existing image)
        if (_profileImageUrl != null && _pickedImageFile == null)
          TextButton.icon(
            onPressed: _isUploading ? null : _removeImage,
            label: Text(
              'Remove Image',
              style: TextStyle(
                color: _isUploading ? Colors.grey : Colors.red,
              ),
            ),
            icon: Icon(
              Icons.delete,
              color: _isUploading ? Colors.grey : Colors.red,
            ),
          ),
      ],
    );
  }

  // Remove profile image
  Future<void> _removeImage() async {
    try {
      setState(() {
        _isUploading = true;
      });

      // Remove image from Firebase Storage
      if (_profileImageUrl != null) {
        final storageRef = FirebaseStorage.instance.refFromURL(_profileImageUrl!);
        await storageRef.delete();
      }

      // Remove image URL from Firestore
      await FirebaseFirestore.instance
          .collection("Users")
          .doc(currentUser.email)
          .update({'profileImageUrl': FieldValue.delete()});

      setState(() {
        _profileImageUrl = null;
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile image removed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}