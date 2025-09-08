import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[300],


        body:SingleChildScrollView(child:
        Column(
      children: [
        // Container(
        //   decoration: BoxDecoration(
        //     // boxShadow: [BoxShadow(
        //     //   color: Colors.black.withOpacity(0.1),
        //     //   spreadRadius: 3,
        //     //   blurRadius: 6,
        //     // ),],
        //
        //     color: Colors.green[300],
        //     borderRadius: BorderRadius.only(
        //
        //       //bottomLeft: Radius.circular(50),
        //       //bottomRight: Radius.circular(50),
        //     ),
        //   ),
        //   height: 300,
        //
        // ),
        SizedBox(height: 300,),
        Container(
          decoration: BoxDecoration(
            boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 3,
              blurRadius: 6,
            ),],

            color: Colors.white,
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(50),
              topLeft:(Radius.circular(50))
            ),
          ),
          height: 700,

        ),

      ],
    )));
  }
}
