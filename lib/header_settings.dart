import 'package:flutter/material.dart';

import 'calendar_group.dart';

class HeaderSettings {
  final double size;
  final Color backgroundColor;
  final Widget Function(CalendarGroup group) headerWidget;

  HeaderSettings({
    required this.size,
    this.backgroundColor = Colors.white,
    Widget Function(CalendarGroup group)? headerWidget,
  }) : headerWidget = headerWidget ?? _defaultHeaderWidget;

  static Widget _defaultHeaderWidget(CalendarGroup group) {
    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(color: Colors.grey, blurRadius: 10, offset: Offset(5, 1))
        ],
        gradient: RadialGradient(
          radius: 3,
          colors: [group.color, Colors.grey],
        ),
      ),
      child: Center(child: Text(group.title)),
    );
  }
}
