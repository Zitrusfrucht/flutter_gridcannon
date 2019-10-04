import 'package:flutter/material.dart';

class Highlight extends StatelessWidget {
  final Widget child;
  final Color color;
  final double opacity;

  Highlight({
    this.child,
    this.color = Colors.lightGreenAccent,
    this.opacity = 0.4,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned.fill(
            child: Container(
          color: color.withOpacity(opacity),
        )),
        child,
      ],
    );
  }
}
