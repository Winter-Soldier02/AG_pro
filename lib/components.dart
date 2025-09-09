import 'package:flutter/material.dart';


class Textf extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;

  const Textf({
    super.key,
    required this.controller,
    required this.hintText,
    required this.obscureText,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 30, left: 25, right: 25, bottom: 0),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          fillColor: Colors.grey,
          focusColor: Colors.grey,

          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.black),
          ),
          hintText: hintText,
        ),
      ),
    );
  }
}