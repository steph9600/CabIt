import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rider_app/AllScreens/registrationScreen.dart';
import 'package:rider_app/components/RoundedButton.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rider_app/AllScreens/mainscreen.dart';
import 'package:rider_app/Widgets/progressDialog.dart';
import 'package:fluttertoast/fluttertoast.dart';

class LoginScreen extends StatefulWidget {
  static const String id = 'login';
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool showSpinner = false;
  final _auth = FirebaseAuth.instance;
  String email;
  String password;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: 20.0,
              ),
              Image(
                image: AssetImage('images/logo.png'),
                width: 300.0,
                height: 300.0,
                alignment: Alignment.center,
              ),
              Text(
                'Login as a Rider?',
                style: TextStyle(
                  fontSize: 25.0,
                  fontFamily: 'Brand-Bold',
                ),
                textAlign: TextAlign.center,
              ),
              Padding(
                padding: const EdgeInsets.all(30.0),
                child: Column(
                  children: [
                    TextField(
                      onChanged: (value) {
                        email = value;
                      },
                      keyboardType: TextInputType.emailAddress,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Color(0xffff9800),
                            ),
                            borderRadius: BorderRadius.circular(8.0)),
                        contentPadding: EdgeInsets.all(5.0),
                        hintText: 'Your email address',
                        labelText: 'Email',
                        labelStyle:
                            TextStyle(fontSize: 14.0, fontFamily: 'Brand-Bold'),
                        hintStyle:
                            TextStyle(color: Colors.grey, fontSize: 10.0),
                      ),
                      style: TextStyle(fontSize: 14.0),
                    ),
                    SizedBox(
                      height: 5.0,
                    ),
                    TextField(
                      onChanged: (value) {
                        password = value;
                      },
                      obscureText: true,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Color(0xffff9800),
                            ),
                            borderRadius: BorderRadius.circular(8.0)),
                        contentPadding: EdgeInsets.all(5.0),
                        hintText: 'Password',
                        labelText: 'Password',
                        labelStyle:
                            TextStyle(fontSize: 14.0, fontFamily: 'Brand-Bold'),
                        hintStyle:
                            TextStyle(color: Colors.grey, fontSize: 10.0),
                      ),
                      style: TextStyle(fontSize: 14.0),
                    ),
                    SizedBox(
                      height: 10.0,
                    ),
                    RoundedButton(
                      text: 'Login',
                      onPressed: () async {
                        if (!RegExp(
                                r"[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?")
                            .hasMatch(email)) {
                          displayErrorMessage(
                              'The email address is invalid', context);
                        } else if (password.isEmpty) {
                          displayErrorMessage('Must input password', context);
                        } else {
                          loginUSer(context);
                        }
                      },
                    )
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                      context, RegistrationScreen.id, (route) => false);
                },
                child: Text("Haven't got an account? Register here"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void loginUSer(BuildContext context) async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return ProgressDialog(message: 'Authenticating. Please wait...');
        });
    try {
      final user = await _auth
          .signInWithEmailAndPassword(email: email, password: password)
          .catchError((errMsg) {
        Navigator.pop(context);
      });
      if (user != null) {
        Navigator.pushNamed(context, MainScreen.id);
        Navigator.pop(context);
      } else {
        Navigator.pop(context);
        _auth.signOut();
        displayErrorMessage('No records exist for this user', context);
      }
    } catch (e) {
      print(e);
    }
  }

  displayErrorMessage(String message, BuildContext context) {
    Fluttertoast.showToast(
      timeInSecForIosWeb: 3,
      msg: message,
      backgroundColor: Color(0xffff9800),
      textColor: Colors.white,
    );
  }
}
