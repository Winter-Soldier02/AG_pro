import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:cupertino_icons/cupertino_icons.dart';
import 'homepage.dart';
import 'loginpage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      // theme: ThemeData(
      //
      //   //colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      //   //useMaterial3: true,
      // ),
      home: const LoginPage(),
    );
  }
}

