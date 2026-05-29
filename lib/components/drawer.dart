import 'package:flutter/material.dart';
import 'package:the_wall/components/my_list_tile.dart';

class MyDrawer extends StatelessWidget {
  final void Function()? onProfileTap;
  final void Function()? onSingOut;
  const MyDrawer({super.key, required this.onProfileTap, required this.onSingOut});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              //drawer header
           DrawerHeader(
            child: Icon(Icons.person, color: Theme.of(context).colorScheme.onSecondary, size: 64),
          ),

          //home list tile
          MyListTile(
            onTap: () => Navigator.pop(context),
            icon: Icons.home,
            text: 'H O M E',
          ),

          //profile list tile
          MyListTile(onTap: onProfileTap, icon: Icons.person, text: 'P R O F I L E'),

            ],
          ),
          //logout list tile
          Padding(
            padding: const EdgeInsets.only(bottom: 25.0),
            child: MyListTile(onTap: onSingOut, icon: Icons.logout, text: 'L O G O U T'),
          ),
        ],
      ),
    );
  }
}
