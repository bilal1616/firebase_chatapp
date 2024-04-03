import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebaseexampleapp/models/message_model.dart';
import 'package:firebaseexampleapp/screens/auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

final firebaseAuthInstance = FirebaseAuth.instance;
final firebaseStorageInstance = FirebaseStorage.instance;
final FirebaseFirestoreInstance = FirebaseFirestore.instance;

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final messageController = TextEditingController();
  final DateFormat formatter = DateFormat('hh:mm dd/MM/yyyy');
  File? _pickedFile;
  String? _imageUrl;
  DateTime? date;

  @override
  void initState() {
    super.initState();
    _getUserImage();
  }

  void _getUserImage() async {
    final user = firebaseAuthInstance.currentUser;
    final document =
        firebaseFireStoreInstance.collection("users").doc(user!.uid);
    final docSnapshot = await document.get();

    setState(() {
      _imageUrl = docSnapshot.get("imageUrl");
    });
  }

  Future<String> _getUserEmail(String userId) async {
    final document = firebaseFireStoreInstance.collection("users").doc(userId);
    final docSnapshot = await document.get();

    print(docSnapshot.get('email'));

    return docSnapshot.get('email');
  }

  Future<List<Message>> _getMessages() async {
    final document =
        await firebaseFireStoreInstance.collection("messages").get();

    final messagesList =
        document.docs.map((e) => Message.fromJson(e.data())).toList();

    // mesajları tarihe göre sıralıyor
    messagesList.sort((a, b) {
      return a.date.compareTo(b.date);
    });

    return messagesList;
  }

  void _pickImage() async {
    final image = await ImagePicker()
        .pickImage(source: ImageSource.camera, imageQuality: 50, maxWidth: 150);
    if (image != null) {
      setState(() {
        _pickedFile = File(image.path);
      });
    }
  }

  void _upload() async {
    final user = firebaseAuthInstance.currentUser;
    final ref =
        firebaseStorageInstance.ref().child("images").child("${user!.uid}.jpg");

    await ref.putFile(_pickedFile!);
    final url = await ref.getDownloadURL();
    print(url);

    final document =
        firebaseFireStoreInstance.collection("users").doc(user.uid);

    await document.update({'imageUrl': url});
  }

  void _submitMessage() async {
    final user = firebaseAuthInstance.currentUser;
    date = DateTime.now();

    try {
      firebaseFireStoreInstance.collection("messages").doc().set({
        'message': messageController.text,
        'date': date,
        'userId': user!.uid
      });
    } on FirebaseException catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message!)));
    }

    messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Firebase ChatApp",
          style: TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              firebaseAuthInstance.signOut();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Stack(
        children: [
          Image.asset(
            "assets/login.jpg",
            fit: BoxFit.cover,
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
          ),
          SingleChildScrollView(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        foregroundImage:
                            _imageUrl == null ? null : NetworkImage(_imageUrl!),
                      ),
                      TextButton(
                        onPressed: () {
                          _pickImage();
                        },
                        child: Text(
                          "Resim Seç",
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      _pickedFile != null
                          ? ElevatedButton(
                              onPressed: () {
                                _upload();
                              },
                              child: Text("Resim Yükle"),
                            )
                          : Container(),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(width: 3, color: Colors.black12),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      height: MediaQuery.of(context).size.height * 0.65,
                      width: MediaQuery.of(context).size.width * 0.92,
                      child: FutureBuilder(
                        future: _getMessages(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return ListView.builder(
                              itemCount: snapshot.data!.length,
                              itemBuilder: (context, index) {
                                if (snapshot.data![index].userId ==
                                    firebaseAuthInstance.currentUser!.uid) {
                                  return Padding(
                                    padding: const EdgeInsets.all(6.0),
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: Container(
                                        width: MediaQuery.of(context).size.width *
                                            0.70,
                                        margin: EdgeInsets.all(4.0),
                                        padding: EdgeInsets.all(4.0),
                                        decoration: BoxDecoration(
                                          color: Colors.yellow,
                                          border: Border.all(
                                            width: 1,
                                            color: Colors.blue,
                                          ),
                                          borderRadius: BorderRadius.only(
                                            topRight: Radius.circular(8.0),
                                            topLeft: Radius.circular(8.0),
                                            bottomLeft: Radius.circular(8.0),
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: [
                                                Text(
                                                  snapshot.data![index].message,
                                                  style: TextStyle(
                                                    color: Colors.blue,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                Text(
                                                  formatter
                                                      .format(
                                                        DateTime
                                                            .fromMillisecondsSinceEpoch(
                                                          snapshot
                                                              .data![index]
                                                              .date
                                                              .millisecondsSinceEpoch,
                                                        ),
                                                      )
                                                      .toString(),
                                                  style:
                                                      TextStyle(fontSize: 12),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                } else {
                                  return Padding(
                                    padding: const EdgeInsets.all(6.0),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Container(
                                        width: MediaQuery.of(context).size.width *
                                            0.70,
                                        margin: EdgeInsets.all(4.0),
                                        padding: EdgeInsets.all(4.0),
                                        decoration: BoxDecoration(
                                          color: Colors.blue,
                                          border: Border.all(
                                            width: 1,
                                            color: Colors.yellow,
                                          ),
                                                                                   borderRadius: BorderRadius.only(
                                            topRight: Radius.circular(8.0),
                                            topLeft: Radius.circular(8.0),
                                            bottomRight: Radius.circular(8.0),
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: [
                                                FutureBuilder(
                                                  future: _getUserEmail(
                                                      snapshot.data![index].userId),
                                                  builder: (context, value) {
                                                    if (value.hasData) {
                                                      return Text(
                                                        value.data!,
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                        ),
                                                      );
                                                    } else if (value.hasError) {
                                                      return Text(
                                                        "Bir şeyler yanlış gitti",
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                        ),
                                                      );
                                                    }
                                                    return Text(
                                                      "Yükleniyor",
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                Text(
                                                  snapshot.data![index].message,
                                                  style: TextStyle(
                                                    color: Colors.yellow,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: [
                                                Text(
                                                  formatter
                                                      .format(
                                                        DateTime
                                                            .fromMillisecondsSinceEpoch(
                                                              snapshot
                                                                  .data![index]
                                                                  .date
                                                                  .millisecondsSinceEpoch,
                                                            ),
                                                      )
                                                      .toString(),
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }
                              },
                            );
                          } else if (snapshot.hasError) {
                            return Text("Bir şeyler yanlış gitti.");
                          }
                          return CircularProgressIndicator();
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: messageController,
                            decoration: InputDecoration(
                              hintText: 'Mesajınız...',
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(8.0)),
                              ),
                            ),
                            keyboardType: TextInputType.text,
                          ),
                        ),
                        SizedBox(
                          width: 10.0,
                        ),
                        CircleAvatar(
                          backgroundColor: Colors.green,
                          child: IconButton(
                            onPressed: () {
                              _submitMessage();
                            },
                            icon: Icon(
                              Icons.send,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

