import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:cupertino_icons/cupertino_icons.dart';
import 'homepage.dart';
import 'loginpage.dart';
import 'wid_t.dart';
import 'package:firebase_core/firebase_core.dart';
import 'liquidglass.dart';

// void main() {
//   runApp(const MyApp());
// }

Future<void> main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyBdMu8dJkHw72KzOEZfzRzhwE9O6LOPkRQ",
        appId: "1:880811800818:android:de8a894b7efa11bc50f86b",
        messagingSenderId: "880811800818",
        projectId: "ag-pro02",
        storageBucket: "ag-pro02.firebasestorage.app",)

  );
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
      home: const Widt(),
      // home: MyGlassWidget()
    );
  }
}

