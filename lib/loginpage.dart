import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'components.dart';
// import 'package:firebase_core/firebase_core.dart'
import 'package:ag_pro/auth.dart';
import 'components.dart';





class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String errorMessage = '';
  bool isLogin = true;

  final TextEditingController _controllerEmail = TextEditingController();
  final TextEditingController _controllerPassword = TextEditingController();
  final TextEditingController _controllerName = TextEditingController();
  final TextEditingController _controllerPhone = TextEditingController();

  Future<void> signInWithEmailAndPassword() async {
    try {
      await Auth().signInWithEmailAndPassword(
        email:  _controllerEmail.text,
        password: _controllerPassword.text,
      );

    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message ?? "An error occurred";
        ;
      });
    }
  }

  Future<void> createUserWithEmailAndPassword() async {
    try {
      await Auth().createUserWithEmailAndPassword(
        email:  _controllerEmail.text,
        password: _controllerPassword.text,
      );

    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message ?? "An error occurred";
        ;
      });
    }
  }

  Widget _errorMessage(){
  return Text(errorMessage==''?'' : 'Hmm??$errorMessage');
  }
  
  Widget _submitButton(){
    
    return ElevatedButton(onPressed: isLogin ? signInWithEmailAndPassword : createUserWithEmailAndPassword, child: Text(isLogin ? 'Login': 'Register'),);
  }

Widget _LoginOrReg(){

    return TextButton(onPressed: (){
      setState(() {
        isLogin = !isLogin;
      });
    }, child: Text(isLogin ? 'Login': 'Register'),);
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.green[300],


        body:SingleChildScrollView(child:
        Column(
          children: [
            Container(
              decoration: BoxDecoration(
                // boxShadow: [BoxShadow(
                //   color: Colors.black.withOpacity(0.1),
                //   spreadRadius: 3,
                //   blurRadius: 6,
                // ),],

                color: Colors.green[300],
                borderRadius: BorderRadius.only(

                  //bottomLeft: Radius.circular(50),
                  //bottomRight: Radius.circular(50),
                ),
              ),
              height: 300,
              child:
              Column(mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.eco,
                    size: 70,
                  ),
                  SizedBox(height:30),
                  Text(
                    'Welcome to Ag pro',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,

                    ),
                  )

                ],
              ),

            ),
            //SizedBox(height: 300,),
            Container(
              padding: EdgeInsets.only(top:30,left:15,right: 15),
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
              child:
              Column(
                // mainAxisAlignment: MainAxisAlignment.center,
                // crossAxisAlignment: CrossAxisAlignment.center,
                // mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[

                  if (!isLogin) ...[
                    Textf(controller: _controllerName, hintText: 'Name', obscureText: false),
                    SizedBox(height: 15),
                    Textf(controller: _controllerPhone, hintText: 'Phone no.', obscureText: false,

                    ),
                  ],
                  SizedBox(height: 15),
                  Textf(controller: _controllerEmail, hintText: 'Email', obscureText: false),
                  SizedBox(height: 15),
                  Textf(controller: _controllerPassword, hintText: 'Password', obscureText: true),
                  SizedBox(height: 15),
                  _errorMessage(),
                  SizedBox(height: 15),
                  LoginButton(
                    onTap: isLogin
                        ? signInWithEmailAndPassword
                        : createUserWithEmailAndPassword,
                  ),
                  SizedBox(height: 15),
                  _LoginOrReg(),
                ],
              ),

            ),

          ],
        )));
  }
}

//oldcodebelow

// class LoginPage extends StatelessWidget {
//   const LoginPage({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.green[300],
//
//
//         body:SingleChildScrollView(child:
//         Column(
//       children: [
//         Container(
//           decoration: BoxDecoration(
//             // boxShadow: [BoxShadow(
//             //   color: Colors.black.withOpacity(0.1),
//             //   spreadRadius: 3,
//             //   blurRadius: 6,
//             // ),],
//
//             color: Colors.green[300],
//             borderRadius: BorderRadius.only(
//
//               //bottomLeft: Radius.circular(50),
//               //bottomRight: Radius.circular(50),
//             ),
//           ),
//           height: 300,
//           child:
//           Column(mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(Icons.eco,
//                 size: 70,
//               ),
//               SizedBox(height:30),
//               Text(
//                 'Welcome to Ag pro',
//                 style: TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//
//                 ),
//               )
//
//             ],
//           ),
//
//         ),
//         //SizedBox(height: 300,),
//         Container(
//           decoration: BoxDecoration(
//             boxShadow: [BoxShadow(
//               color: Colors.black.withOpacity(0.1),
//               spreadRadius: 3,
//               blurRadius: 6,
//             ),],
//
//             color: Colors.white,
//             borderRadius: BorderRadius.only(
//               topRight: Radius.circular(50),
//               topLeft:(Radius.circular(50))
//             ),
//           ),
//           height: 700,
//           child:
//           Column(
//             children: [
//               SizedBox(height:90 ),
//               TextField()
//             ],
//           ),
//
//         ),
//
//       ],
//     )));
//   }
// }
