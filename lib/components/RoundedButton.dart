import 'package:flutter/material.dart';

class RoundedButton extends StatelessWidget {
  RoundedButton({this.text, this.onPressed});
  final String text;
  final Function onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.0),
      child: Material(
        elevation: 10.0,
        color: Color(0xff3f50b5),
        borderRadius: BorderRadius.circular(10.0),
        child: MaterialButton(
          onPressed: onPressed,
          minWidth: 400.0,
          height: 50.0,
          child: Text(
            text,
            style: TextStyle(
                fontSize: 20.0, fontFamily: 'Brand-Bold', color: Colors.white),
          ),
        ),
      ),
    );
  }
}
