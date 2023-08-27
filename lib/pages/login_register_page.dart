import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lakbayan/auth.dart';

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

  Widget _title() {
    return const Text('Register');
  }

  Widget _entryField(
    String title,
    TextEditingController controller,
    int maxLength,
    bool isPassword,
  ) {
    return Container(
        width: 800, // Set the desired width
        child: TextField(
          controller: controller,
          obscureText: isPassword,
          style: const TextStyle(
            fontSize: 40,
          ),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            labelText: title,
            contentPadding: const EdgeInsets.symmetric(vertical: 30),
            labelStyle: const TextStyle(fontSize: 40),
          ),
        ));
  }

  Widget _errorMessage() {
    return Text(errorMessage == '' ? '' : 'Error! $errorMessage',
        style: const TextStyle(
          fontSize: 40,
        ));
  }

  Widget _submitButton() {
    return ElevatedButton(
      onPressed:
          isLogin ? signInWithEmailAndPassword : createUserWithEmailAndPassword,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFAD547F), // Hex code AD547F
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50), // Adjust the value as needed
        ),
        minimumSize: const Size(700, 50), // Set the minimum width and height
        padding: const EdgeInsets.symmetric(
            vertical: 20), // Adjust the padding as needed
      ),
      child: Text(
        isLogin ? 'Login' : 'Register',
        style: const TextStyle(
          fontSize: 30,
          fontFamily: 'Roboto', // Use the "Roboto" font family
        ),
      ),
    );
  }

  Widget _loginOrRegisterButton() {
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
        style: const TextStyle(
          fontSize: 30,
          color: Color.fromARGB(192, 167, 166, 166),
          fontFamily: 'Roboto', // Use the "Roboto" font family
        ),
      ),
    );
  }

  Widget _titleName() {
    return Text(isLogin ? 'Login' : 'Register',
        style: const TextStyle(
            fontSize: 50,
            fontFamily: 'Roboto',
            color: Color(0xFFAD547F),
            fontWeight: FontWeight.bold));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context)
              .size
              .height, // Set the container height to screen height
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("lib/images/Login.png"),
              fit: BoxFit.cover,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Center the children
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _titleName(),
              _entryField('Email', _controllerEmail, 200, false),
              _entryField('Password', _controllerPassword, 150, true),
              const SizedBox(height: 30),
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
