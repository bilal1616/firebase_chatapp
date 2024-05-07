import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebaseexampleapp/provider/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

class ChatPage extends StatefulWidget {
  final String recipientUid;
  final String recipientName;

  const ChatPage(
      {Key? key, required this.recipientUid, required this.recipientName})
      : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late CollectionReference<Map<String, dynamic>> _messagesCollection;
  final TextEditingController _messageController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  String? _previewImageUrl;

  @override
  void initState() {
    super.initState();
    final currentUser = FirebaseAuth.instance.currentUser;
    final currentUid = currentUser!.uid;
    final recipientUid = widget.recipientUid;

    final List<String> uids = [currentUid, recipientUid];
    uids.sort(); // Sorting UIDs to ensure consistency in collection name

    final String chatId = uids.join('_'); // Creating chat ID

    _messagesCollection = FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages');
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage:
                  userProvider.imageUrl == null ? null : NetworkImage(userProvider.imageUrl!),
            ),
            SizedBox(width: 8),
            Text(
              widget.recipientName,
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus(); // Klavyeyi kapat
        },
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/image1.jpg'), // Arka plan resmi
              fit: BoxFit.cover,
            ),
          ),
          child: Column(
            children: [
              Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _messagesCollection.orderBy('timestamp').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Bir hata oluştu'),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final List<QueryDocumentSnapshot<Map<String, dynamic>>>
                      documents = snapshot.data!.docs.reversed
                          .toList(); // Liste ters çevriliyor

                  return ListView.builder(
                    reverse: true, // Mesajları en üstten en alta doğru sırala
                    itemCount: documents.length,
                    itemBuilder: (context, index) {
                      final message = documents[index].data();
                      final senderUid = message['sender'] as String?;
                      final imageUrl = message['imageUrl'] as String?;
                      final text = message['text'] as String?;
                      final timestamp = message['timestamp'] as Timestamp?;

                      // Gönderenin adını almak için kullanıcı koleksiyonundan veri getir
                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(senderUid)
                            .get(),
                        builder: (context, userSnapshot) {
                          if (userSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (userSnapshot.hasError) {
                            return Text('Kullanıcı verisi alınamadı');
                          }

                          final senderName =
                              userSnapshot.data!.get('name') ?? 'Unknown';

                          final isCurrentUser = senderUid ==
                              FirebaseAuth.instance.currentUser!.uid;

                          // Mesajı sağa veya sola hizala
                          final messageAlignment = isCurrentUser
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start;

                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: messageAlignment,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8.0),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8.0),
                                    color: isCurrentUser
                                        ? Colors.green
                                        : Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.5),
                                        spreadRadius: 2,
                                        blurRadius: 3,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 8.0),
                                        child: Text(
                                          senderName, // Gönderen adını göster
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      if (imageUrl != null)
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Image.network(
                                              imageUrl,
                                              fit: BoxFit.contain,
                                              height: 300, // Resim boyutu
                                            ),
                                            SizedBox(height: 8),
                                          ],
                                        ),
                                      if (text != null &&
                                          text !=
                                              'Image') // 'Image' metnini kontrol et
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              text,
                                              style: TextStyle(
                                                fontSize: 16.0,
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                            SizedBox(height: 4.0),
                                            if (timestamp != null)
                                              Text(
                                                '${DateTime.fromMillisecondsSinceEpoch(timestamp.millisecondsSinceEpoch).hour}:${DateTime.fromMillisecondsSinceEpoch(timestamp.millisecondsSinceEpoch).minute}',
                                                style: TextStyle(
                                                  fontSize: 12.0,
                                                  fontWeight: FontWeight.w300,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              )),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        cursorColor: Colors.white,
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: "Mesajınız...",
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          contentPadding: EdgeInsets.all(12),
                          suffixIcon: IconButton(
                            icon: Icon(Icons.attach_file),
                            onPressed: () {
                              _showImagePicker(context);
                            },
                          ),
                        ),
                        onChanged: (value) {
                          if (value.isEmpty) {
                            setState(() {
                              _previewImageUrl = null;
                            });
                          }
                        },
                      ),
                    ),
                    SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 3,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.send,
                          size: 30,
                        ),
                        color: Colors.white,
                        onPressed: () {
                          _sendMessage();
                          FocusScope.of(context).unfocus(); // Klavyeyi kapat
                        },
                      ),
                    ),
                  ],
                ),
              ),
              if (_previewImageUrl != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.check),
                      onPressed: () {
                        _sendMessage();
                        setState(() {
                          _previewImageUrl = null;
                        });
                      },
                    ),
                    Container(
                      height: 100,
                      padding: EdgeInsets.all(8),
                      alignment: Alignment.center,
                      child: Image.network(
                        _previewImageUrl!,
                        fit: BoxFit.cover,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _previewImageUrl = null;
                        });
                      },
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    final imageUrl = _previewImageUrl;
    if (text.isNotEmpty || imageUrl != null) {
      final currentUser = FirebaseAuth.instance.currentUser;
      final recipientUid = widget.recipientUid;

      final Map<String, dynamic> messageData = {
        if (text.isNotEmpty) 'text': text,
        'sender': currentUser!.uid,
        'timestamp': FieldValue.serverTimestamp(),
        if (imageUrl != null) 'imageUrl': imageUrl,
      };

      _messagesCollection.add(messageData).then((docRef) {
        setState(() {
          _messageController.clear();
          _previewImageUrl = null;
        });
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $error'),
          ),
        );
      });
    }
  }

  void _showImagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Galeri'),
                onTap: () {
                  _pickImage(ImageSource.gallery);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('Kamera'),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      final imageFile = File(pickedFile.path);

      try {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('images/${DateTime.now().millisecondsSinceEpoch}');
        final uploadTask = storageRef.putFile(imageFile);
        final snapshot = await uploadTask.whenComplete(() {});

        final imageUrl = await snapshot.ref.getDownloadURL();
        setState(() {
          _previewImageUrl = imageUrl;
        });
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: $error'),
          ),
        );
      }
    }
  }
}
