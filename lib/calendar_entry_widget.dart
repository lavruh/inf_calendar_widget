import 'package:flutter/material.dart';

class CalendarEntryWidget extends StatelessWidget {
  const CalendarEntryWidget(
      {super.key, required this.title, required this.backgroundColor});
  final Widget title;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(color: Colors.black, blurRadius: 1, offset: Offset(1, 1))
          ],
          color: backgroundColor,
        ),
        child: title);
  }
}
