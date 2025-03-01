import 'package:flutter/material.dart';
import 'package:inf_calendar_widget/view_mode.dart';
import 'package:intl/intl.dart';

import 'calendar_group.dart';
import 'header_settings.dart';

class ViewModeVertical extends ViewMode {
  ViewModeVertical({
    super.entryMainAxisSize = 100,
    super.dataAreaStartOffset = 150,
    super.groupPadding = 10,
  }) : super(
            headerSettings: HeaderSettings(
          size: 30,
          headerWidget: _defaultHeaderWidget,
          backgroundColor: Colors.transparent,
        ));

  @override
  setWidgetCrossAxisSize(Size value) => super.widgetCrossAxisSize = value.width;

  @override
  int entriesPerScreen({
    required Size screenSize,
    required double entrySize,
  }) =>
      screenSize.height ~/ entrySize;

  @override
  Widget itemWidget({
    required double position,
    required double size,
    required double crossDirectionOffset,
    required double? crossDirectionSize,
    required Widget child,
  }) {
    return Positioned(
      top: position,
      left: crossDirectionOffset,
      width: crossDirectionSize,
      height: size,
      child: child,
    );
  }

  @override
  Widget titlePositionWidget({
    required double parentPosition,
    required double parentSize,
    required double? crossDirectionSize,
    required Widget title,
    required Color backgroundColor,
    required bool textDirectionStraight,
  }) {
    return Container(
      decoration: BoxDecoration(
          color: backgroundColor,
          border: const Border(top: BorderSide(color: Colors.black, width: 1))),
      child: Stack(fit: StackFit.expand, children: [
        Positioned(
          top: parentPosition < 0 ? -(parentPosition) : 0,
          child: ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: parentSize, maxWidth: crossDirectionSize ?? 0),
            child: RotatedBox(
              quarterTurns: textDirectionStraight ? 0 : 3,
              child: title,
            ),
          ),
        ),
      ]),
    );
  }

  @override
  double getValueInCorrectDirection(Offset value) => value.dy;

  @override
  String hourFormat(DateTime d) => DateFormat("HH:00").format(d);

  @override
  String minHourFormat(DateTime d) => DateFormat("HH : mm").format(d);

  @override
  String dayFormat(DateTime d) => DateFormat("EEE dd").format(d);

  static Widget _defaultHeaderWidget(CalendarGroup group) {
    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(color: Colors.black, blurRadius: 10, offset: Offset(1, 2))
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
