import 'package:flutter/material.dart';

class XzButtons extends StatelessWidget {
  final String text;
  final void Function()? onTap;

  const XzButtons({super.key, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary,
            borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.symmetric(horizontal: 30),
        child: Center(
          child: Text(text),
        ),
      ),
    );
  }
}
