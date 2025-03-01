import 'package:flutter/material.dart';
import 'package:inf_calendar_widget/view_mode.dart';
import 'package:intl/intl.dart';

import 'calendar_group.dart';
import 'header_settings.dart';

class ViewModeHorizontal extends ViewMode {
  ViewModeHorizontal({
    super.entryMainAxisSize = 100,
    super.dataAreaStartOffset = 150,
    super.groupPadding = 10,
    HeaderSettings? header,
  }) : super(
            headerSettings: HeaderSettings(
          size: 150,
          headerWidget: _defaultHeaderWidget,
          backgroundColor: Colors.transparent,
        ));

  @override
  int entriesPerScreen({required Size screenSize, required double entrySize}) =>
      screenSize.width ~/ entrySize;

  @override
  Widget itemWidget(
      {required double position,
      required double size,
      required double crossDirectionOffset,
      required double? crossDirectionSize,
      required Widget child}) {
    return Positioned(
      top: crossDirectionOffset,
      left: position,
      width: size,
      height: crossDirectionSize,
      child: child,
    );
  }

  @override
  setWidgetCrossAxisSize(Size value) =>
      super.widgetCrossAxisSize = value.height;

  @override
  Widget titlePositionWidget(
      {required double parentPosition,
      required double parentSize,
      required double? crossDirectionSize,
      required bool textDirectionStraight,
      required Widget title,
      required Color backgroundColor}) {
    return Container(
      decoration: BoxDecoration(
          color: backgroundColor,
          border:
              const Border(left: BorderSide(color: Colors.black, width: 1))),
      child: Stack(fit: StackFit.expand, children: [
        Positioned(
          left: parentPosition < 0 ? -(parentPosition) : 0,
          child: ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: crossDirectionSize ?? 0, maxWidth: parentSize),
            child: title,
          ),
        ),
      ]),
    );
  }

  @override
  double getValueInCorrectDirection(Offset value) => value.dx;

  @override
  String hourFormat(DateTime d) => DateFormat("HH\n00").format(d);

  @override
  String minHourFormat(DateTime d) => DateFormat("HH\nmm").format(d);

  @override
  String dayFormat(DateTime d) => DateFormat("EEE\ndd").format(d);

  static Widget _defaultHeaderWidget(CalendarGroup group) {
    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(color: Colors.black, blurRadius: 10, offset: Offset(5, 1))
        ],
        color: group.color,
      ),
      child: Center(
          child: Text(
        group.title,
        style: TextStyle(
          fontFamily: "Noto",
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(color: Colors.grey, blurRadius: 1, offset: Offset(0.5, 1))
          ],
        ),
      )),
    );
  }
}
