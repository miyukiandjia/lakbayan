import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lakbayan/pages/authentication_page/auth.dart';
import 'package:lakbayan/pages/home_page/home_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String? errorMessage = '';
  bool isLogin = true;

  final TextEditingController _controllerEmail = TextEditingController();
  final TextEditingController _controllerPassword = TextEditingController();
  final TextEditingController _controllerUsername = TextEditingController();

  Future<void> signInWithEmailAndPassword() async {
    try {
      await Auth().signInWithEmailAndPassword(
          email: _controllerEmail.text, password: _controllerPassword.text);

      // After successful login, navigate to the HomePage
      // ignore: use_build_context_synchronously
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message;
      });
    }
  }

  Future<void> createUserWithEmailAndPassword() async {
    // Ensure a username is provided
    if (_controllerUsername.text.isEmpty) {
      setState(() {
        errorMessage = "Please provide a username.";
      });
      return;
    }

    try {
      await Auth().createUserWithEmailAndPassword(
          email: _controllerEmail.text, password: _controllerPassword.text);

      final user = FirebaseAuth.instance.currentUser;
      final userDoc =
          FirebaseFirestore.instance.collection('users').doc(user!.uid);

      userDoc.set({
        'username': _controllerUsername.text,
        'email': _controllerEmail.text,
      });

      // Toggle to Login UI after registration
      setState(() {
        isLogin = true;
        errorMessage = "Registration successful! Please log in.";
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message;
      });
    }
  }

  Widget _entryField(
    String title,
    TextEditingController controller,
    int maxLength,
    bool isPassword,
  ) {
    double fontSize = MediaQuery.of(context).size.width * 0.04;

    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.8,
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: TextStyle(
          fontSize: fontSize,
        ),
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          labelText: title,
          contentPadding: EdgeInsets.symmetric(
            vertical: fontSize * 0.5,
          ),
          labelStyle: TextStyle(fontSize: fontSize),
        ),
      ),
    );
  }

  Widget _errorMessage() {
    return Text(errorMessage == '' ? '' : 'Error! $errorMessage',
        style: const TextStyle(
          fontSize: 36,
        ));
  }

  Widget _submitButton() {
    double buttonWidth = MediaQuery.of(context).size.width * 0.8;
    double buttonHeight = MediaQuery.of(context).size.height * 0.07;

    return ElevatedButton(
      onPressed:
          isLogin ? signInWithEmailAndPassword : createUserWithEmailAndPassword,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFAD547F),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(buttonWidth * 0.1),
        ),
        minimumSize: Size(buttonWidth, buttonHeight),
        padding: EdgeInsets.symmetric(
          vertical: buttonHeight * 0.3,
        ),
        elevation: 5,
      ),
      child: Text(
        isLogin ? 'Login' : 'Register',
        style: TextStyle(
          fontSize: buttonWidth * 0.04,
          fontFamily: 'Nunito',
        ),
      ),
    );
  }

  Widget _loginOrRegisterButton() {
    double fontSize = MediaQuery.of(context).size.width * 0.05;

    return TextButton(
      onPressed: () {
        setState(() {
          isLogin = !isLogin;
        });
      },
      child: Text(
        isLogin
            ? 'Don\'t have an account? Create now'
            : 'Already have an account? Login instead',
        style: TextStyle(
          fontSize: fontSize - 20,
          color: const Color.fromARGB(255, 58, 70, 70),
          fontFamily: 'Nunito',
        ),
      ),
    );
  }

  Widget _titleName() {
    return Padding(
      padding: const EdgeInsets.all(50.0),
      child: Center(
        child: Text(
          isLogin ? 'Login' : 'Register',
          style: const TextStyle(
            fontSize: 50,
            fontFamily: 'Nunito',
            color: Color.fromARGB(255, 58, 70, 70),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            height: MediaQuery.of(context).size.height,
            width: double.infinity,
            decoration: const BoxDecoration(
                gradient: LinearGradient(
              begin: Alignment.topCenter,
              colors: [Color(0xFFAD547F), Color.fromARGB(255, 244, 143, 177)],
            )),
            child: Column(
              children: <Widget>[
                const SizedBox(
                  height: 80,
                ),
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: <Widget>[
                      SizedBox(
                        height: 200,
                      ),
                      Text(
                        "Welcome to Lakbayan!",
                        style: TextStyle(
                            fontSize: 48,
                            fontFamily: 'Roboto',
                            color: Colors.white,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 400,
                ),
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(100),
                            topRight: Radius.circular(120))),
                    child: Column(
                      children: <Widget>[
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            _titleName(),
                            isLogin
                                ? const SizedBox.shrink()
                                : _entryField('Username', _controllerUsername,
                                    30, false), // Add this line
                            _entryField('Email', _controllerEmail, 200, false),
                            _entryField(
                                'Password', _controllerPassword, 150, true),
                            const SizedBox(
                                height: 10), // Set a relative spacing
                            _errorMessage(),
                            _submitButton(),
                            _loginOrRegisterButton(),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
