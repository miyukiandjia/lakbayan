import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lakbayan/auth.dart';
import 'package:lakbayan/pages/home_page.dart';

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

  Future<void> signInWithEmailAndPassword() async {
    try {
      await Auth().signInWithEmailAndPassword(
          email: _controllerEmail.text, password: _controllerPassword.text);

      // After successful login, navigate to the HomePage
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message;
      });
    }
  }

  Future<void> createUserWithEmailAndPassword() async {
    try {
      await Auth().createUserWithEmailAndPassword(
          email: _controllerEmail.text, password: _controllerPassword.text);
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
      width: MediaQuery.of(context).size.width * 0.8, // Adjust the width
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
          ), // Set a relative padding
          labelStyle: TextStyle(fontSize: fontSize), // Set a relative font size
        ),
      ),
    );
  }

  Widget _errorMessage() {
    return Text(errorMessage == '' ? '' : 'Error! $errorMessage',
        style: const TextStyle(
          fontSize: 40,
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
      ),
      child: Text(
        isLogin ? 'Login' : 'Register',
        style: TextStyle(
          fontSize: buttonWidth * 0.04, // Use relative value here
          fontFamily: 'Roboto',
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
          fontSize: fontSize,
          color: Color.fromARGB(192, 167, 166, 166),
          fontFamily: 'Roboto',
        ),
      ),
    );
  }

  Widget _titleName() {
    return Center(
      child: Text(
        isLogin ? 'Login' : 'Register',
        style: const TextStyle(
          fontSize: 50,
          fontFamily: 'Roboto',
          color: Color(0xFFAD547F),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          width: double.infinity,
          padding: const EdgeInsets.all(30), // Set a relative padding
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("lib/images/Login.png"),
              fit: BoxFit.cover,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _titleName(),
              _entryField('Email', _controllerEmail, 200, false),
              _entryField('Password', _controllerPassword, 150, true),
              const SizedBox(height: 10), // Set a relative spacing
              _errorMessage(),
              _submitButton(),
              _loginOrRegisterButton(),
            ],
          ),
        ),
      ),
    );
  }
}
