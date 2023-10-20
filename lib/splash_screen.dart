import 'package:lakbayan/pages/authentication/auth.dart';
import 'package:lakbayan/pages/homepage/home_page.dart';
import 'package:lakbayan/pages/authentication/login_register_page.dart';
import 'package:flutter/material.dart';

class WidgetTree extends StatefulWidget {
  const WidgetTree({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _WidgetTreeState createState() => _WidgetTreeState();
}

class _WidgetTreeState extends State<WidgetTree> {
  void _onSplashButtonPressed() {
    setState(() {
      _hasPressedButton = true;
    });
  }


  bool _hasPressedButton = false;

  @override
  void initState() {
    super.initState();

    Auth().authStateChanges.listen((user) {
      if (user != null && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      }
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
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }

            if (snapshot.hasData) {
              return HomePage();
            } else {
              return const LoginPage();
            }
          }
          return const CircularProgressIndicator();
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
                  bottom: screenHeight * 0.1), 
              child: ElevatedButton(
                onPressed: onButtonPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF9CDDD),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                        screenWidth * 0.5), 
                  ),
                  minimumSize: Size(screenWidth * 0.8,
                      screenHeight * 0.08), 
                  elevation: 10,
                  padding: EdgeInsets.symmetric(
                      vertical:
                          screenHeight * 0.02), 
                ),
                child: Text(
                  "Get Started",
                  style: TextStyle(
                    fontSize: screenWidth * 0.05,
                    fontWeight: FontWeight.w400, 
                    fontFamily: 'Nunito',
                    color: const Color.fromARGB(255, 58, 70, 70),
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
