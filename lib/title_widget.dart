import 'package:flutter/material.dart';

class TitleWidget extends StatelessWidget {
  const TitleWidget({super.key, required this.title, required this.textColor});
  final String title;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      child: Text(
        title,
        style: TextStyle(color: textColor),
        overflow: TextOverflow.fade,
        maxLines: 2,
        textAlign: TextAlign.center,
      ),
    );
  }
}
