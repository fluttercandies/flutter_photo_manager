import 'package:flutter/material.dart';

class ThemeButton extends StatelessWidget {
  const ThemeButton({
    Key? key,
    required this.text,
    required this.onPressed,
  }) : super(key: key);

  final String text;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 5, top: 5),
      child: ElevatedButton(
        onPressed: onPressed,
        child: Text(text),
      ),
    );
  }
}
