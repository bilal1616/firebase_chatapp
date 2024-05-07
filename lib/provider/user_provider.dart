import 'package:flutter/material.dart';

class UserProvider extends ChangeNotifier {
  String? _imageUrl;

  String? get imageUrl => _imageUrl;

  void setImageUrl(String? url) {
    _imageUrl = url;
    notifyListeners();
  }
}
