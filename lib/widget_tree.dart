import 'package:lakbayan/auth.dart';
import 'package:lakbayan/pages/home_page.dart';
import 'package:lakbayan/pages/login_register_page.dart';
import 'package:flutter/material.dart';

class WidgetTree extends StatefulWidget {
  const WidgetTree({super.key});

  @override
  _WidgetTreeState createState() => _WidgetTreeState();
}

class _WidgetTreeState extends State<WidgetTree> {
  bool _hasPressedButton = false;

  void _onSplashButtonPressed() {
    setState(() {
      _hasPressedButton = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: Auth().authStateChanges,
        builder: (context, snapshot) {
          if (!_hasPressedButton) {
            return SplashScreen(onButtonPressed: _onSplashButtonPressed);
          }

          if (snapshot.connectionState == ConnectionState.active) {
            if (snapshot.hasData) {
              return HomePage();
            } else {
              return const LoginPage();
            }
          }
          return const CircularProgressIndicator(); // or some other loading widget
        });
  }
}

class SplashScreen extends StatelessWidget {
  final VoidCallback onButtonPressed;

  const SplashScreen({required this.onButtonPressed, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("lib/images/Splash Screen.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(
                  bottom: screenHeight * 0.1), // Adjust the value as needed
              child: ElevatedButton(
                onPressed: onButtonPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF9CDDD),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                        screenWidth * 0.05), // Adjust the value as needed
                  ),
                  minimumSize: Size(screenWidth * 0.8,
                      screenHeight * 0.1), // Adjust the values as needed
                  padding: EdgeInsets.symmetric(
                      vertical:
                          screenHeight * 0.02), // Adjust the value as needed
                ),
                child: Text(
                  "Get Started",
                  style: TextStyle(
                    fontSize: screenWidth * 0.05, // Adjust the value as needed
                    fontFamily: 'Roboto',
                    color: Color.fromARGB(255, 12, 12, 12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
