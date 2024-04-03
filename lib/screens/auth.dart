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
  var _username = ""; // Kullanıcı adını saklamak için bir değişken

  void submitForm() async {
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
    } // Kullanıcı kaydı için
// submitForm fonksiyonu içinde, kayıt işlemi bölümü

    else {
      try {
        final userCredentials = await firebaseAuthInstance
            .createUserWithEmailAndPassword(email: _email, password: _password);

        // Firestore'a kullanıcı bilgilerini kaydet
        await firebaseFireStoreInstance
            .collection("users")
            .doc(userCredentials.user!.uid)
            .set({
          'email': _email,
          'name': _username, // Kullanıcının girdiği adı buraya ekleyin
        });
      } on FirebaseAuthException {
        // FirebaseAuthException hatası oluştuğunda yapılacak işlemler
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kayıt işlemi sırasında bir hata oluştu')),
        );
      }
    }
  }

  void signInWithGoogle() async {
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

      // Google'dan gelen kullanıcı bilgilerini Firestore'a kaydetmek
      firebaseFireStoreInstance
          .collection("users")
          .doc(userCredential.user!.uid)
          .set({
        'email': userCredential.user!.email,
        'name': userCredential.user!.displayName, // Kullanıcının adını alıyoruz
        'imageUrl': userCredential
            .user!.photoURL, // Kullanıcının profil resmini alıyoruz
      });
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message!)));
    }
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.white, // Arka plan rengi
    body: Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            "assets/login.jpg",
            fit: BoxFit.cover, // Resmi tam ekran yapmak için
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
          ), // Arka plan resmi
          SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Card(
                  color: Colors.blueAccent[100], // Kart arka plan rengi
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
                              backgroundColor: Colors.green, // Buton rengi
                            ),
                            onPressed: () {
                              submitForm();
                            },
                            child: Text(
                              _isLogin ? "Giriş Yap" : "Kayıt Ol",
                              style: TextStyle(color: Colors.white), // Buton metin rengi
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isLogin = !_isLogin;
                              });
                            },
                            child: Text(
                              _isLogin
                                  ? "Kayıt Sayfasına Git"
                                  : "Giriş Sayfasına Git",
                              style: TextStyle(
                                color: Colors.black,
                              ),
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red, // Buton rengi
                            ),
                            onPressed: () {
                              signInWithGoogle();
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  "assets/google_icon.png",
                                  width: MediaQuery.of(context).size.width *
                                      0.06,
                                  color: Colors.black,
                                ),
                                SizedBox(
                                  width: 10.0,
                                ),
                                Text(
                                  "Google ile Giriş Yap",
                                  style: TextStyle(
                                      color: Colors.white), // Buton metin rengi
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
