import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:the_wall/components/drawer.dart';
import 'package:the_wall/components/text_feild.dart';
import 'package:the_wall/components/wall_post.dart';
import 'package:the_wall/helper.dart/helper_methods.dart';
import 'package:the_wall/pages/profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // text controller
  final textController = TextEditingController();
  //get current user
  final currentUser = FirebaseAuth.instance.currentUser!;

  

  //post message
  void postMessage() {
    //only post if the is soneting in the text field
    if (textController.text.isNotEmpty) {
      //store in firebase
      FirebaseFirestore.instance.collection("User Posts").add({
        'UserEmail': currentUser.email,
        'Message': textController.text,
        'TimeStamp': Timestamp.now(),
        'Likes': [],
      });
    }
    //clear the text after posting
    textController.clear();
    //hide the keyboard
    FocusScope.of(context).unfocus();
  }

  //user sign out
  void signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  //go to profile page
  void goToProfilePage() {
    //pop the drawer
    Navigator.pop(context);

    ///navigate to profile page
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProfilePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: MyDrawer(onProfileTap: goToProfilePage, onSingOut: signOut),
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text('The Wall'),
        centerTitle: true,
        actions: [],
      ),

      body: Center(
        child: Column(
          children: [
            // the wall
            Expanded(
              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection("User Posts")
                    .orderBy("TimeStamp", descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return ListView.builder(
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        //get the message
                        final post = snapshot.data!.docs[index];
                        return WallPost(
                          message: post['Message'],
                          user: post['UserEmail'],
                          postId: post.id,
                          likes: List<String>.from(post['Likes'] ?? []),
                          time: formatDate(post['TimeStamp']),
                        );
                      },
                    );
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  return const Center(child: CircularProgressIndicator());
                },
              ),
            ),

            //post message
            Padding(
              padding: const EdgeInsets.all(25.0),
              child: Row(
                children: [
                  Expanded(
                    child: MyTextField(
                      controller: textController,
                      hintText: 'Write something on the wall',
                      obscureText: false,
                    ),
                  ),

                  IconButton(onPressed: postMessage, icon: Icon(Icons.send)),
                ],
              ),
            ),

            //logged in as
            Text('Logged in as: ${currentUser.email!}'),
          ],
        ),
      ),
    );
  }
}
