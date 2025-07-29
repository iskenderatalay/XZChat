import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:xzchat/pages/groups_page.dart';
import 'package:xzchat/auth/auth_service.dart';
import 'package:xzchat/pages/users_page.dart';
import 'package:xzchat/pages/settings_page.dart';
import 'package:xzchat/widgets/xz_pageroute.dart';

class XzDrawer extends StatefulWidget {
  const XzDrawer({super.key});

  @override
  State<XzDrawer> createState() => _XzDrawerState();
}

class _XzDrawerState extends State<XzDrawer> {
  final AuthService authService = AuthService();
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  void logout() async{
    authService.signOut();
    await firestore.collection("Users").doc(authService.getCurrentUser()!.uid).update({
      "status":"Offline",
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              DrawerHeader(
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.messenger_outline_outlined,
                        color: Theme.of(context).colorScheme.primary,
                        size: 70,
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Text(
                        "Welcome",
                        style: TextStyle(
                          fontSize: 20,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(auth.currentUser!.email.toString(),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          )),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(left: 20.0),
                child: ListTile(
                    title: Text(
                      "U S E R S",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    leading: Icon(
                      Icons.people,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        noAnimate(child: UsersPage()),
                      );
                    }),
              ),

              Padding(
                padding: const EdgeInsets.only(left: 20.0),
                child: ListTile(
                    title: Text(
                      "G R O U P S",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    leading: Icon(
                      Icons.group_work,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        noAnimate(child: const GroupsPage()),
                      );
                    }),
              ),

              Padding(
                padding: const EdgeInsets.only(left: 20.0),
                child: ListTile(
                    title: Text(
                      "S E T T I N G S",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    leading: Icon(
                      Icons.settings,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        noAnimate(child: const SettingsPage()),
                      );
                    }),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 20.0, bottom: 20.0),
            child: ListTile(
              title: Text(
                "L O G O U T",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              leading: Icon(
                Icons.logout_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              onTap: () {
                logout();
                Navigator.pushReplacementNamed(context, '/');
              },
            ),
          ),
        ],
      ),
    );
  }
}
