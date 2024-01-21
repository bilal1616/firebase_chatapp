import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String? uid;
  final String message;
  final Timestamp date;
  final String userId;

  Message(
      {required this.uid,
      required this.message,
      required this.date,
      required this.userId});

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        uid: json['uid'],
        message: json['message'],
        date: json['date'],
        userId: json['userId'],
      );
}