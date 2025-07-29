import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:xzchat/pages/groups_page.dart';
import 'package:xzchat/widgets/xz_pageroute.dart';

class GroupCreatePage extends StatefulWidget {
  final List<Map<String, dynamic>> memberList;
  const GroupCreatePage({
    super.key,
    required this.memberList,
  });

  @override
  State<GroupCreatePage> createState() => _GroupCreatePageState();
}

class _GroupCreatePageState extends State<GroupCreatePage> {
  final TextEditingController groupNameController = TextEditingController();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;
  final Timestamp timestamp = Timestamp.now();

  void createGroup() async {
    String groupId = Uuid().v1();

    final encrypt.Key key;
    key = encrypt.Key.fromSecureRandom(32);

    List<String> userIds = [];
    for (int i = 0; i < widget.memberList.length; i++) {
      String uid = widget.memberList[i]["uid"];
      userIds.add(uid);
    }

    Map<String, int> unreadCounts = {
      for (var userId in userIds) userId: 0,
    };

    await firestore.collection("Groups").doc(groupId).set({
      "name": groupNameController.text,
      "members": widget.memberList,
      "enKey": key.base64,
      "unreadCounts": unreadCounts,
    });

    for (int i = 0; i < widget.memberList.length; i++) {
      String uid = widget.memberList[i]["uid"];

      await firestore
          .collection("Users")
          .doc(uid)
          .collection("Groups")
          .doc(groupId)
          .set({
        "name": groupNameController.text,
        "id": groupId,
      });
    }
    if (mounted) {
      Navigator.push(
        context,
        noAnimate(child: const GroupsPage()),
      );
    }
    await firestore
        .collection("Groups")
        .doc(groupId)
        .collection("Messages")
        .add({
      "message": "Admin is : ${auth.currentUser!.email}",
      "type": "notify",
      "sendBy": auth.currentUser!.email,
      "time": timestamp,
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text(
            "Create Group",
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.tertiary,
        ),
        body: Column(
          children: [
            const SizedBox(
              height: 25,
            ),
            Container(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: TextField(
                  obscureText: false,
                  controller: groupNameController,
                  decoration: InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                    ),
                    fillColor: Theme.of(context).colorScheme.secondary,
                    filled: true,
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    hintText: "Type a Group Name",
                    hintStyle:
                        TextStyle(color: Theme.of(context).colorScheme.primary),
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 25,
            ),
            ElevatedButton(
                onPressed: createGroup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  elevation: 0,
                  foregroundColor: Theme.of(context).colorScheme.tertiary,
                  padding: const EdgeInsets.all(15.0),
                ),
                child: const Text("Create Group")),
          ],
        ),
      ),
    );
  }
}
