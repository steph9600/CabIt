import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rider_app/AllScreens/loginScreen.dart';
import 'package:rider_app/components/RoundedButton.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rider_app/AllScreens/mainscreen.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:rider_app/main.dart';
import 'package:rider_app/Widgets/progressDialog.dart';

class RegistrationScreen extends StatefulWidget {
  static const String id = 'register';
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _auth = FirebaseAuth.instance;
  bool showSpinner = false;
  String email;
  String password;
  String name;
  String number;

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
                height: 10.0,
              ),
              Image(
                image: AssetImage('images/logo.png'),
                width: 300.0,
                height: 300.0,
                alignment: Alignment.center,
              ),
              Text(
                'Register as a Rider?',
                style: TextStyle(
                  fontSize: 25.0,
                  fontFamily: 'Brand-Bold',
                ),
                textAlign: TextAlign.center,
              ),
              Padding(
                padding: const EdgeInsets.only(
                    left: 30.0, right: 30.0, bottom: 50.0, top: 10.0),
                child: Column(
                  children: [
                    TextField(
                      onChanged: (value) {
                        name = value;
                      },
                      keyboardType: TextInputType.name,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Color(0xffff9800),
                            ),
                            borderRadius: BorderRadius.circular(8.0)),
                        contentPadding: EdgeInsets.all(5.0),
                        hintText: 'Your name',
                        labelText: 'Name',
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
                        number = value;
                      },
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Color(0xffff9800),
                            ),
                            borderRadius: BorderRadius.circular(8.0)),
                        contentPadding: EdgeInsets.all(5.0),
                        hintText: 'Your phone number',
                        labelText: 'Phone number',
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
                      text: 'Create account',
                      onPressed: () {
                        if (name.length < 3) {
                          displayErrorMessage(
                              'Name must be at least 3 characters', context);
                        } else if (!RegExp(
                                r"[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?")
                            .hasMatch(email)) {
                          displayErrorMessage(
                              'The email address is invalid', context);
                        } else if (number.isEmpty) {
                          displayErrorMessage(
                              'Phone Number is mandatory', context);
                        } else if (number.length < 6) {
                          displayErrorMessage(
                              'Phone Number is invalid', context);
                        } else if (password.length < 7) {
                          displayErrorMessage(
                              'Password must be at least 6 characters',
                              context);
                        } else {
                          registerNewUSer(context);
                        }
                      },
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                      context, LoginScreen.id, (route) => false);
                },
                child: Text("Already have an account? Login here"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void registerNewUSer(BuildContext context) async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return ProgressDialog(message: 'Authenticating. Please wait...');
        });
    try {
      final newUser = await _auth
          .createUserWithEmailAndPassword(email: email, password: password)
          .catchError((errMsg) {
        Navigator.pop(context);
      });
      if (newUser != null) {
        Navigator.pop(context);
        Map userDataMap = {
          'name': name.trim(),
          'email': email.trim(),
          'phone': number.trim(),
        };
        usersRef.child(newUser.user.uid).set(userDataMap);
        displayErrorMessage('Your account has been created!', context);
        Navigator.pushNamedAndRemoveUntil(
            context, LoginScreen.id, (route) => false);
      } else {
        Navigator.pop(context);
        displayErrorMessage('New Account has not been created.', context);
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
