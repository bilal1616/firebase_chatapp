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
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: MediaQuery.of(context).size.width * 0.9,
                decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 7,
                        offset: const Offset(0, 3),
                      )
                    ]),
                child: Padding(
                  padding: const EdgeInsets.all(
                      16.0), // Daha büyük bir iç kenar boşluğu ekledik.
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText:
                                "E-Mail", // "label" özelliğini "labelText" olarak güncelledik.
                          ),
                          keyboardType: TextInputType.emailAddress,
                          onSaved: (newValue) {
                            _email = newValue!;
                          },
                        ),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText:
                                "Şifre", // "label" özelliğini "labelText" olarak güncelledik.
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
                          height: 20.0, // Daha büyük bir boşluk ekledik.
                        ),
                        ElevatedButton(
                          onPressed: () {
                            submitForm();
                          },
                          child: Text(_isLogin ? "Giriş Yap" : "Kayıt Ol"),
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
                                : "Giriş Sayfasına Git", // Metinleri güncelledik.
                            style: TextStyle(
                              color:
                                  Colors.blue, // Daha belirgin bir renk seçtik.
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            signInWithGoogle();
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                "assets/google_icon.png",
                                width: MediaQuery.of(context).size.width * 0.06,
                              ),
                              SizedBox(
                                width: 10.0, // Daha büyük bir boşluk ekledik.
                              ),
                              Text("Google ile Giriş Yap"),
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
      ),
    );
  }
}
