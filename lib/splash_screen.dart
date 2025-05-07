import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_project1/login_screen.dart';

class SplashScreen extends StatefulWidget{
  const SplashScreen({super.key});
  @override
  State<StatefulWidget> createState() {
    return SplashScreenState();
  }
}

class SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()));//ไปยังหน้าที่ต้องการ
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 255, 255, 255),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/carrent.jpg',width: 100, height: 100,
            ),

            SizedBox(height: 20),
            Text('Welcome to Car rental',style: TextStyle(
            color: const Color.fromARGB(255, 31, 47, 100),
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            ),)
          ],
        ),
      ),
    );
  }
}