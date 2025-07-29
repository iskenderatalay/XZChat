import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:xzchat/pages/group_addmember_page.dart';
import 'package:xzchat/pages/group_chat_page.dart';
import 'package:xzchat/widgets/xz_drawer.dart';
import 'package:xzchat/widgets/xz_pageroute.dart';

class GroupsPage extends StatefulWidget {
  const GroupsPage({super.key});

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> memberList = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "Groups",
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.tertiary,
      ),
      drawer: XzDrawer(),
      body: Column(
        children: [
          const SizedBox(
            height: 15,
          ),
          Expanded(
            child: viewGroupList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            noAnimate(
              child: const GroupAddmemberPage(),
            ),
          );
        },
        child: Icon(
          Icons.group_add_rounded,
          color: Theme.of(context).colorScheme.tertiary,
        ),
      ),
    );
  }

  Widget viewGroupList() {
    String uid = auth.currentUser!.uid;
    return StreamBuilder(
      stream: firestore
          .collection("Users")
          .doc(uid)
          .collection("Groups")
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text("Error");
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (content, index) {
              Map<String, dynamic> groupData =
                  snapshot.data!.docs[index].data();
              return groupListItem(groupData);
            },
          );
        } else {
          return Center(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.all(25.0),
              child: Text(
                "Does Not Have A Group",
                style: TextStyle(
                  fontSize: 20,
                ),
              ),
            ),
          );
        }
      },
    );
  }

  Widget groupListItem(Map<String, dynamic> groupData) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          noAnimate(
            child: GroupChatPage(
              groupName: groupData["name"],
              groupChatId: groupData["id"],
            ),
          ),
        );
      },
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
                const Icon(Icons.groups),
                const SizedBox(width: 20),
                Text(groupData["name"]),
              ],
            ),
            Row(
              children: [
                StreamBuilder(
                    stream: firestore
                        .collection("Groups")
                        .doc(groupData["id"])
                        .snapshots(),
                    builder: (context, snapshot) {
                      String currentUserId = auth.currentUser!.uid;
                      if (snapshot.hasError) {
                        return const Text("Error");
                      }
                      if (snapshot.hasData && snapshot.data!.exists) {
                        var data = snapshot.data!.data();
                        var unreadCounts = data!["unreadCounts"];

                        if (unreadCounts[currentUserId] != null &&
                            unreadCounts[currentUserId] > 0) {
                          return Container(
                            padding: EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              unreadCounts[currentUserId].toString(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                              ),
                            ),
                          );
                        } else {
                          return Container();
                        }
                      } else {
                        return Container();
                      }
                    })
              ],
            ),
          ],
        ),
      ),
    );
  }
}
