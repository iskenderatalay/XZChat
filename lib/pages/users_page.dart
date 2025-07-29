import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:xzchat/pages/chat_page.dart';
import 'package:xzchat/auth/auth_service.dart';
import 'package:xzchat/widgets/xz_drawer.dart';
import '../widgets/xz_pageroute.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final AuthService authService = AuthService();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  late final AppLifecycleListener appListener;

  @override
  void initState() {
    super.initState();

    appListener = AppLifecycleListener(
      onStateChange: didChangeAppLifecycleState,
    );
  }

  @override
  void dispose() {
    super.dispose();
    appListener.dispose();
  }

  void setStatus(String status) async {
    await firestore
        .collection("Users")
        .doc(authService.getCurrentUser()!.uid)
        .update({
      "status": status,
    });
  }

  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setStatus("Online");
    } else {
      setStatus("Offline");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "Users",
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
            child: buildUserList(),
          ),
        ],
      ),
    );
  }

  Widget buildUserList() {
    return StreamBuilder(
      stream: firestore.collection("Users").snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text("Error");
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.data!.docs.length < 2) {
          return Center(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.all(25.0),
              child: Text(
                "Does Not Have An Another User",
                style: TextStyle(
                  fontSize: 20,
                ),
              ),
            ),
          );
        } else {
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (content, index) {
              Map<String, dynamic> userData = snapshot.data!.docs[index].data();
              return buildUserListItem(userData);
            },
          );
        }
      },
    );
  }

  Widget buildUserListItem(Map<String, dynamic> userData) {
    final String currentUserID = authService.getCurrentUser()!.uid;
    List<String> ids = [currentUserID, userData["uid"]];
    ids.sort();
    String chatRoomID = ids.join('_');

    return Builder(
      builder: (_) {
        bool uStatus = userData["status"] == "Online" ? true : false;

        if (userData["email"] != authService.getCurrentUser()!.email) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                noAnimate(
                  child: ChatPage(
                    receiverEmail: userData["email"],
                    receiverID: userData["uid"],
                    userStatus: userData["status"],
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
                      const Icon(Icons.person),
                      const SizedBox(width: 20.0),
                      Text(userData["email"]),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        userData["status"],
                        style: TextStyle(
                          color: uStatus
                              ? Colors.red
                              : Theme.of(context).colorScheme.inversePrimary,
                        ),
                      ),
                      const SizedBox(width: 20.0),
                      StreamBuilder(
                        stream: firestore
                            .collection("Private Chats")
                            .doc(chatRoomID)
                            .snapshots(),
                        builder: (context, snapshot2) {
                          if (snapshot2.hasError) {
                            return const Text("Error");
                          }
                          if (snapshot2.hasData && snapshot2.data!.exists) {
                            var data = snapshot2.data!.data();
                            var count = data!["unread"];
                            if (count != 0 &&
                                data["unreadId"] != currentUserID) {
                              return Container(
                                padding: EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  count.toString(),
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
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        } else {
          return Container();
        }
      },
    );
  }
}
