import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

final firebaseAuthInstance = FirebaseAuth.instance;
final firebaseFireStoreInstance = FirebaseFirestore.instance;

class Auth extends StatefulWidget {
  const Auth({Key? key}) : super(key: key);

  @override
  _AuthState createState() => _AuthState();
}

class _AuthState extends State<Auth> {
  final _formKey = GlobalKey<FormState>();
  var _isLogin = true;
  var _email = "";
  var _password = "";
  var _username = ""; 

  void submitForm(BuildContext context) async {
    _formKey.currentState!.save();

    if (_isLogin) {
      try {
        final userCredentials = await firebaseAuthInstance
            .signInWithEmailAndPassword(email: _email, password: _password);
        print(userCredentials);
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message!)));
      }
    } else {
      try {
        final userCredentials = await firebaseAuthInstance
            .createUserWithEmailAndPassword(email: _email, password: _password);

        await firebaseFireStoreInstance
            .collection("users")
            .doc(userCredentials.user!.uid)
            .set({
          'email': _email,
          'name': _username,
        });
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message!)),
        );
      }
    }
  }

  void signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      final GoogleSignInAuthentication? googleAuth =
          await googleUser!.authentication;
      final googleCredential = GoogleAuthProvider.credential(
        accessToken: googleAuth!.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential =
          await firebaseAuthInstance.signInWithCredential(googleCredential);
      print(userCredential);

      firebaseFireStoreInstance
          .collection("users")
          .doc(userCredential.user!.uid)
          .set({
        'email': userCredential.user!.email,
        'name': userCredential.user!.displayName,
        'imageUrl': userCredential.user!.photoURL,
      });
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.asset(
              "assets/login.jpg",
              fit: BoxFit.cover,
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
            ),
            SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Card(
                    color: Color.fromARGB(255, 252, 247, 238),
                    elevation: 5,
                    margin: EdgeInsets.all(20),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: "E-Mail",
                              ),
                              keyboardType: TextInputType.emailAddress,
                              onSaved: (newValue) {
                                _email = newValue!;
                              },
                            ),
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: "Şifre",
                              ),
                              autocorrect: false,
                              obscureText: true,
                              keyboardType: TextInputType.visiblePassword,
                              onSaved: (newValue) {
                                _password = newValue!;
                              },
                            ),
                            if (!_isLogin)
                              TextFormField(
                                decoration: const InputDecoration(
                                  labelText: "Kullanıcı Adı",
                                ),
                                onSaved: (newValue) {
                                  _username = newValue!;
                                },
                              ),
                            SizedBox(
                              height: 20.0,
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              onPressed: () {
                                submitForm(context);
                              },
                              child: Text(
                                _isLogin ? "Giriş Yap" : "Kayıt Ol",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isLogin = !_isLogin;
                                });
                              },
                              child: Text(
                                _isLogin ? "Kayıt Sayfasına Git" : "Giriş Sayfasına Git",
                                style: TextStyle(
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                              ),
                              onPressed: () {
                                signInWithGoogle(context);
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    "assets/google_icon.png",
                                    width: MediaQuery.of(context).size.width * 0.08,
                                  ),
                                  SizedBox(
                                    width: 10.0,
                                  ),
                                  Text(
                                    "Google ile Giriş Yap",
                                    style: TextStyle(color: Colors.grey[700]),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
