import 'package:flutter/material.dart';

class DividerWidget extends StatelessWidget {
  const DividerWidget({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1.5,
      color: Colors.amberAccent,
      thickness: 1.5,
    );
  }
}
