import 'package:flutter/material.dart';

class EntryTitleWidget extends StatelessWidget {
  const EntryTitleWidget(
      {super.key, required this.title, required this.textColor});
  final String title;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontFamily: "Noto",
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(color: Colors.grey, blurRadius: 1, offset: Offset(0.5, 1))
        ],
      ),
    );
  }
}
