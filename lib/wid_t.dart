import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth.dart';
import 'homepage.dart';
import 'loginpage.dart';
import 'auth.dart';


class Widt extends StatefulWidget {
  const Widt({super.key});

  @override
  State<Widt> createState() => _WidtState();
}

class _WidtState extends State<Widt> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(stream: Auth().authStateChanges, builder: (context,snapshot)
    {
      if (snapshot.hasData)
      {
        return MyHomePage();
      }
      else{
        return const LoginPage();
      }
    });
  }
}
