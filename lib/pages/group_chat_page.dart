// ignore_for_file: strict_top_level_inference

import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'package:xzchat/auth/auth_service.dart';
import 'package:xzchat/theme/theme_provider.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:http/http.dart' as http;

class GroupChatPage extends StatefulWidget {
  final String groupChatId, groupName;

  const GroupChatPage({
    super.key,
    required this.groupChatId,
    required this.groupName,
  });

  @override
  State<GroupChatPage> createState() => _GroupChatPageState();
}

class _GroupChatPageState extends State<GroupChatPage> {
  final TextEditingController messageController = TextEditingController();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final AuthService authService = AuthService();

  FocusNode myFocusNode = FocusNode();
  final ScrollController scrollController = ScrollController();

  late encrypt.Key xzKey;

  PlatformFile? selectedFile;

  bool _isGranted = true;

  Future<void> checkPermission() async {
    if (!await Permission.manageExternalStorage.isGranted) {
      PermissionStatus result =
          await Permission.manageExternalStorage.request();
      if (result.isGranted) {
        setState(() {
          _isGranted = true;
        });
      } else {
        _isGranted = false;
      }
    }
  }

  @override
  void initState() {
    unreadReset();
    super.initState();
    myFocusNode.addListener(() {
      if (myFocusNode.hasFocus) {
        Future.delayed(
          const Duration(milliseconds: 500),
          () => scrollDown(),
        );
      }
    });
    Future.delayed(
      const Duration(milliseconds: 500),
      () => scrollDown(),
    );
  }

  @override
  void dispose() {
    myFocusNode.dispose();
    messageController.dispose();
    super.dispose();
  }

  void scrollDown() async {
    scrollController.animateTo(
      scrollController.position.maxScrollExtent,
      duration: const Duration(seconds: 1),
      curve: Curves.fastOutSlowIn,
    );
  }

  Future<void> unreadReset() async {
    final String currentUserID = authService.getCurrentUser()!.uid;
    final groupRef =
        FirebaseFirestore.instance.collection("Groups").doc(widget.groupChatId);
    await groupRef.update({
      "unreadCounts.$currentUserID": 0,
    });
  }

  void sendMessage() async {
    var docSnapshot =
        await firestore.collection("Groups").doc(widget.groupChatId).get();
    Map<String, dynamic>? data = docSnapshot.data();

    var value = data?["enKey"];
    xzKey = encrypt.Key.fromBase64(value);
    final iv = encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(xzKey));
    final encrypted = encrypter.encrypt(messageController.text, iv: iv);
    final ivBase64 = iv.base64;
    final encryptedBase64 = encrypted.base64;

    final groupRef =
        FirebaseFirestore.instance.collection("Groups").doc(widget.groupChatId);
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final groupSnapshot = await transaction.get(groupRef);

      if (groupSnapshot.exists) {
        final unreadCounts = groupSnapshot.data()?["unreadCounts"] ?? {};
        unreadCounts.forEach((userId, dynamic count) {
          if (userId != authService.getCurrentUser()!.uid) {
            unreadCounts[userId] = (count ?? 0) + 1;
          }
        });
        transaction.update(groupRef, {"unreadCounts": unreadCounts});
      }
    });

    if (messageController.text.isNotEmpty) {
      Map<String, dynamic> chatData = {
        "sendBy": authService.getCurrentUser()!.email,
        "message": '$ivBase64:$encryptedBase64',
        "time": FieldValue.serverTimestamp(),
        "type": "text",
      };
      messageController.clear();
      await firestore
          .collection("Groups")
          .doc(widget.groupChatId)
          .collection("Messages")
          .add(chatData);
    }
    scrollDown();
  }

  Future<bool> selectAndEncryptFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result == null) return false;
    setState(() {
      selectedFile = result.files.first;
    });

    var docSnapshot =
        await firestore.collection("Groups").doc(widget.groupChatId).get();
    Map<String, dynamic>? data = docSnapshot.data();
    var value = data?["enKey"];
    xzKey = encrypt.Key.fromBase64(value);

    final sFile = File(selectedFile!.path!);
    final sFileContents = await sFile.readAsBytes();

    final iv = encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(xzKey));
    final encrypted = encrypter.encryptBytes(sFileContents, iv: iv);
    final ivBase64 = iv.base64;
    final encryptedBytes = encrypted.bytes;

    String docFileName = Uuid().v1();
    await firestore
        .collection("Groups")
        .doc(widget.groupChatId)
        .collection("Messages")
        .doc(docFileName)
        .set({
      "sendBy": authService.getCurrentUser()!.email,
      "message": "",
      "fName": selectedFile!.name,
      "type": "file",
      "iv": ivBase64,
      "time": FieldValue.serverTimestamp(),
    });

    String fileName = "${selectedFile!.name}.xz";
    String cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
    var uri =
        Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/raw/upload");
    var request = http.MultipartRequest("POST", uri);
    var multipartFile = http.MultipartFile.fromBytes(
      'file',
      encryptedBytes,
      filename: fileName,
    );
    request.files.add(multipartFile);
    request.fields['upload_preset'] = "preset-for-file-upload";
    request.fields['resource_type'] = "raw";
    var response = await request.send();
    var responseBody = await response.stream.bytesToString();
    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(responseBody);
      String fileURL = jsonResponse["secure_url"];
      await firestore
          .collection("Groups")
          .doc(widget.groupChatId)
          .collection("Messages")
          .doc(docFileName)
          .update({"message": fileURL});
      return true;
    } else {
      await firestore
          .collection("Groups")
          .doc(widget.groupChatId)
          .collection("Messages")
          .doc(docFileName)
          .delete();
      return false;
    }
  }

  Widget getEncKey() {
    return StreamBuilder(
      stream:
          firestore.collection("Groups").doc(widget.groupChatId).snapshots(),
      builder: (_, snapshot) {
        if (snapshot.hasError) {
          return const Text("Error");
        }
        if (snapshot.hasData) {
          var data = snapshot.data!.data();
          var value = data?["enKey"];
          if (value != null) {
            xzKey = encrypt.Key.fromBase64(value);
          }
        }
        return Container();
      },
    );
  }

  String deText(String dataMessage) {
    final parts = dataMessage.split(":");
    final iv = encrypt.IV.fromBase64(parts[0]);
    final encrypted = encrypt.Encrypted.fromBase64(parts[1]);
    final encrypter = encrypt.Encrypter(encrypt.AES(xzKey));
    final decrypted = encrypter.decrypt(encrypted, iv: iv);

    return decrypted;
  }

  Future<void> deFile(String fName, String ivKey, String fileURL) async {
    Directory d = await getExternalVisibleDir;

    if (await File("${d.path}/$fName").exists()) {
      return;
    } else if (await canLaunchUrl(Uri.parse(fileURL))) {
      var resp = await http.get(Uri.parse(fileURL));

      String fNameFirst = fName.split(".").first;
      await writeData(resp.bodyBytes, "${d.path}/$fNameFirst");

      Uint8List encData = await readData("${d.path}/$fNameFirst");
      encrypt.Encrypted en = encrypt.Encrypted(encData);
      final iv = encrypt.IV.fromBase64(ivKey);
      final encrypter = encrypt.Encrypter(encrypt.AES(xzKey));
      final decrypted = encrypter.decryptBytes(en, iv: iv);

      await writeData(decrypted, "${d.path}/$fName");
      await deleteData("${d.path}/$fNameFirst");
    }
  }

  Future<Directory> get getExternalVisibleDir async {
    if (await Directory("/storage/emulated/0/XZChat").exists()) {
      final externalDir = Directory("/storage/emulated/0/XZChat");
      return externalDir;
    } else {
      await Directory("/storage/emulated/0/XZChat").create(recursive: true);
      final externalDir = Directory("/storage/emulated/0/XZChat");
      return externalDir;
    }
  }

  Future<Uint8List> readData(fileNameWithPath) async {
    File f = File(fileNameWithPath);
    return await f.readAsBytes();
  }

  Future<String> writeData(dataToWrite, fileNameWithPath) async {
    File f = File(fileNameWithPath);
    await f.writeAsBytes(dataToWrite);
    return f.absolute.toString();
  }

  Future<FileSystemEntity> deleteData(fileNameWithPath) async {
    File f = File(fileNameWithPath);
    return await f.delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(widget.groupName),
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
        },
        child: Column(
          children: [
            getEncKey(),
            Expanded(
              child: buildMessageList(),
            ),
            buildUserInput(),
          ],
        ),
      ),
    );
  }

  Widget buildMessageList() {
    return StreamBuilder(
        stream: firestore
            .collection("Groups")
            .doc(widget.groupChatId)
            .collection("Messages")
            .orderBy("time", descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Text("Error");
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            scrollController.jumpTo(scrollController.position.maxScrollExtent);
          });
          return ListView.builder(
            controller: scrollController,
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              Map<String, dynamic> groupMap = snapshot.data!.docs[index].data();
              return buildGroupItems(groupMap);
            },
          );
        });
  }

  Widget buildGroupItems(Map<String, dynamic> groupMap) {
    return Builder(builder: (_) {
      bool isCurrentUser =
          groupMap["sendBy"] == authService.getCurrentUser()!.email;
      bool isDarkMode =
          Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
      var alignment =
          isCurrentUser ? Alignment.centerRight : Alignment.centerLeft;

      if (groupMap["type"] == "text") {
        return Container(
          alignment: alignment,
          child: Container(
            decoration: BoxDecoration(
              color: isCurrentUser
                  ? (isDarkMode ? Colors.green.shade600 : Colors.grey.shade500)
                  : (isDarkMode ? Colors.green.shade900 : Colors.white),
              borderRadius: isCurrentUser
                  ? BorderRadius.only(
                      topLeft: Radius.circular(10.0),
                      bottomLeft: Radius.circular(10.0),
                      bottomRight: Radius.circular(10.0),
                    )
                  : BorderRadius.only(
                      topRight: Radius.circular(10.0),
                      bottomRight: Radius.circular(10.0),
                      bottomLeft: Radius.circular(10.0),
                    ),
            ),
            padding: const EdgeInsets.all(10.0),
            margin: const EdgeInsets.symmetric(
              vertical: 5.0,
              horizontal: 25.0,
            ),
            child: Column(
              children: [
                Text(
                  groupMap["sendBy"],
                  style: TextStyle(
                    color: isCurrentUser
                        ? (isDarkMode ? Colors.white : Colors.white)
                        : (isDarkMode ? Colors.white : Colors.grey.shade500),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                Text(
                  deText(groupMap["message"]),
                  style: TextStyle(
                    color: isCurrentUser
                        ? (isDarkMode ? Colors.white : Colors.white)
                        : (isDarkMode ? Colors.white : Colors.grey.shade500),
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (groupMap["type"] == "file") {
        if (_isGranted) {
          deFile(groupMap["fName"], groupMap["iv"], groupMap["message"]);
        } else {
          checkPermission();
        }
        return Container(
          alignment: alignment,
          child: Container(
            decoration: BoxDecoration(
              color: isCurrentUser
                  ? (isDarkMode ? Colors.green.shade600 : Colors.grey.shade500)
                  : (isDarkMode ? Colors.green.shade900 : Colors.white),
              borderRadius: isCurrentUser
                  ? BorderRadius.only(
                      topLeft: Radius.circular(10.0),
                      bottomLeft: Radius.circular(10.0),
                      bottomRight: Radius.circular(10.0),
                    )
                  : BorderRadius.only(
                      topRight: Radius.circular(10.0),
                      bottomRight: Radius.circular(10.0),
                      bottomLeft: Radius.circular(10.0),
                    ),
            ),
            padding: const EdgeInsets.all(10.0),
            margin: const EdgeInsets.symmetric(
              vertical: 5.0,
              horizontal: 25.0,
            ),
            child: Column(
              children: [
                Text(
                  groupMap["sendBy"],
                  style: TextStyle(
                    color: isCurrentUser
                        ? (isDarkMode ? Colors.white : Colors.white)
                        : (isDarkMode ? Colors.white : Colors.grey.shade500),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                Text(
                  "File : ${groupMap["fName"]}",
                  style: TextStyle(
                    color: isCurrentUser
                        ? (isDarkMode ? Colors.white : Colors.white)
                        : (isDarkMode ? Colors.white : Colors.grey.shade500),
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    if (await File(
                            "/storage/emulated/0/XZChat/${groupMap["fName"]}")
                        .exists()) {
                      await OpenFile.open(
                          "/storage/emulated/0/XZChat/${groupMap["fName"]}");
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary,
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(top: 10),
                    width: 50,
                    child: Center(
                      child: Text("Aç"),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (groupMap["type"] == "notify") {
        return Container(
          alignment: Alignment.center,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            margin: EdgeInsets.symmetric(vertical: 5, horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              color: Colors.black38,
            ),
            child: Text(
              groupMap["message"],
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        );
      }
      return SizedBox();
    });
  }

  Widget buildUserInput() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0, top: 15.0),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: TextField(
                obscureText: false,
                controller: messageController,
                focusNode: myFocusNode,
                decoration: InputDecoration(
                  suffixIcon: IconButton(
                    onPressed: () async {
                      if (_isGranted) {
                        selectAndEncryptFile();
                      } else {
                        checkPermission();
                      }
                    },
                    icon: Icon(
                      Icons.attach_file,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  fillColor: Theme.of(context).colorScheme.secondary,
                  filled: true,
                  hintText: "Type a Messsage",
                  hintStyle:
                      TextStyle(color: Theme.of(context).colorScheme.primary),
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            margin: const EdgeInsets.only(right: 25.0),
            child: IconButton(
              onPressed: sendMessage,
              icon: const Icon(Icons.send),
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
