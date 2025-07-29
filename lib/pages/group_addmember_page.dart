// ignore_for_file: strict_top_level_inference

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:xzchat/pages/group_create_page.dart';
import 'package:xzchat/auth/auth_service.dart';
import 'package:xzchat/widgets/xz_pageroute.dart';

class GroupAddmemberPage extends StatefulWidget {
  const GroupAddmemberPage({super.key});

  @override
  State<GroupAddmemberPage> createState() => _GroupAddmemberPageState();
}

class _GroupAddmemberPageState extends State<GroupAddmemberPage> {
  final AuthService authService = AuthService();
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  
  List<Map<String, dynamic>> memberList = [];

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  void getCurrentUser() async {
    await firestore
        .collection("Users")
        .doc(auth.currentUser!.uid)
        .get()
        .then((map) {
      setState(() {
        memberList.add({
          "email": map["email"],
          "uid": map["uid"],
        });
      });
    });
  }

  void removeUser(int index) {
    if (memberList[index]["uid"] != auth.currentUser!.uid) {
      setState(() {
        memberList.removeAt(index);
      });
    }
  }

  void selectUser(userData) {
    bool isAlreadyExist = false;

    for (int i = 0; i < memberList.length; i++) {
      if (memberList[i]['uid'] == userData['uid']) {
        isAlreadyExist = true;
      }
    }
    if (!isAlreadyExist) {
      setState(() {
        memberList.add({
          "email": userData["email"],
          "uid": userData["uid"],
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "Add Member",
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.tertiary,
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 20),
            child: Text(
              "Select Users",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 25,
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
            ),
          ),
          const SizedBox(
            height: 15.0,
          ),
          Expanded(
            child: Expanded(
              child: buildUserList(),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 20),
            child: Text(
              "Selected Group's Users",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 25,
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
            ),
          ),
          const SizedBox(
            height: 15.0,
          ),
          Expanded(
            child: ListView.builder(
                itemCount: memberList.length,
                shrinkWrap: true,
                scrollDirection: Axis.vertical,
                itemBuilder: (dynamic context, dynamic index) {
                  bool isCurrentUser = memberList[index]["uid"] ==
                      authService.getCurrentUser()!.uid;
                  return Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.symmetric(
                      vertical: 5.0,
                      horizontal: 25.0,
                    ),
                    child: ListTile(
                      onTap: () => removeUser(index),
                      leading: const Icon(Icons.person),
                      title: Text(memberList[index]["email"]),
                      trailing: isCurrentUser
                          ? const Icon(Icons.admin_panel_settings_outlined)
                          : const Icon(Icons.remove),
                    ),
                  );
                }),
          ),
          const SizedBox(
            height: 15.0,
          ),
        ],
      ),
      floatingActionButton: memberList.length >= 3
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  noAnimate(
                    child: GroupCreatePage(
                      memberList: memberList,
                    ),
                  ),
                );
              },
              child: Icon(
                Icons.navigate_next,
                color: Theme.of(context).colorScheme.tertiary,
              ),
            )
          : const SizedBox(),
    );
  }

  Stream<List<Map<String, dynamic>>> getUsersStream() {
    return firestore.collection("Users").snapshots().map((snapshots) {
      return snapshots.docs.map((doc) {
        final user = doc.data();
        return user;
      }).toList();
    });
  }

  Widget buildUserList() {
    return StreamBuilder(
      stream: getUsersStream(),
      builder: (context, snapshot) {
        //error
        if (snapshot.hasError) {
          return const Text("Error");
        }
        //loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text("Waiting");
        }
        return ListView(
          scrollDirection: Axis.vertical,
          shrinkWrap: true,
          children: snapshot.data!
              .map<Widget>((userData) => buildUserListItem(userData, context))
              .toList(),
        );
      },
    );
  }

  Widget buildUserListItem(userData, BuildContext context) {
    //display all users except current logged in user
    if (userData["email"] != authService.getCurrentUser()!.email) {
      return GestureDetector(
        onTap: () => selectUser(userData),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary,
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(
            vertical: 5.0,
            horizontal: 25.0,
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.person),
                  const SizedBox(width: 20.0),
                  Text(
                    userData["email"],
                    style: const TextStyle(
                      fontSize: 15.0,
                    ),
                  ),
                ],
              ),
              const Icon(Icons.add),
            ],
          ),
        ),
      );
    } else {
      return Container();
    }
  }
}
