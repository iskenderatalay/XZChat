import 'package:flutter/material.dart';

PageRouteBuilder noAnimate({required Widget child}) {
  return PageRouteBuilder(
    pageBuilder: (BuildContext context, Animation<double> animation1,
        Animation<double> animation2) {
      return child;
    },
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
  );
}
