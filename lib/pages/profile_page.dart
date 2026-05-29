import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:the_wall/components/text_box.dart';
import 'package:the_wall/components/user_image_picker.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  //get all users
  final usersCollection = FirebaseFirestore.instance.collection("Users");
  //get current user
  final currentUser = FirebaseAuth.instance.currentUser!;
  //edit field  function
  Future<void> editfield(String field) async {
    String newValue = "";
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Edit $field', style: TextStyle(color: Colors.white),
          ),
        content: TextField(
          autofocus: true,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Enter new $field",
            hintStyle: TextStyle(color: Colors.grey)
          ),
          onChanged: (value) {
            newValue = value;
          },
          ),

          actions: [
            //cancel button
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: Colors.white)),
            ),
            //save button
            TextButton(
              onPressed: ()=> Navigator.of(context).pop(newValue),
              child: Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
      ),
    );

    //update the field in firestore
    if ( newValue.trim().isNotEmpty) {
      //update if there is something in the text field
      await usersCollection.doc(currentUser.email).update({field: newValue});
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile Page'),
        centerTitle: true,
      ),

      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("Users")
            .doc(currentUser.email)
            .snapshots(),
        builder: (context, snapshot) {
          //get user data
          if (snapshot.hasData) {
            final userData = snapshot.data!.data() as Map<String, dynamic>;
            return ListView(
              children: [
                //profile pic
                const SizedBox(height: 50),

                UserImagePicker(),
                //user email
                const SizedBox(height: 10),
                Text(
                  currentUser.email!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[700]),
                ),

                const SizedBox(height: 50),

                //user details
                Padding(
                  padding: EdgeInsets.only(left: 25.0),
                  child: Text(
                    'My Details',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),

                //username
                MyTextBox(
                  text: userData['username'],
                  sectionName: 'Username',
                  onPressed: () => editfield('username'),
                ),

                //bio
                MyTextBox(
                  text: userData['bio'],
                  sectionName: 'bio',
                  onPressed: () => editfield('bio'),
                ),

                const SizedBox(height: 50),

                //user posts
                Padding(
                  padding: EdgeInsets.only(left: 25.0),
                  child: Text(
                    'My Posts',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ],
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          return Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
