import 'package:flutter/material.dart';

class XzUsertile extends StatelessWidget {
  final String text,userStatus;
  final void Function()? onTap;

  const XzUsertile({
    super.key,
    required this.text,
    required this.userStatus,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary,
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(
          vertical: 5.0,
          horizontal: 25.0,
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.person),
                const SizedBox(width: 20.0),
                Text(text),
              ],
            ),
            Text(userStatus),
          ],
        ),
      ),
    );
  }
}
