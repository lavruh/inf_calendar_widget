import 'package:flutter/material.dart';
import 'package:inf_calendar_widget/header_settings.dart';

abstract class ViewMode {
  ViewMode({
    required this.entryMainAxisSize,
    required this.dataAreaStartOffset,
    required this.groupPadding,
    required this.headerSettings,
  });

  double entryMainAxisSize;
  final double dataAreaStartOffset;
  double widgetCrossAxisSize = 0;
  double groupPadding;
  HeaderSettings headerSettings;

  double groupCrossAxisSize(int groupsLength) {
    return ((widgetCrossAxisSize - 50 - dataAreaStartOffset) / groupsLength) -
        (groupPadding);
  }

  void setWidgetCrossAxisSize(Size value);
  int entriesPerScreen({required Size screenSize, required double entrySize});
  double getValueInCorrectDirection(Offset value);

  Widget itemWidget({
    required double position,
    required double size,
    required double crossDirectionOffset,
    required double? crossDirectionSize,
    required Widget child,
  });

  Widget titlePositionWidget({
    required double parentPosition,
    required double parentSize,
    required double? crossDirectionSize,
    required bool textDirectionStraight,
    required Widget title,
    required Color backgroundColor,
  });

  String minHourFormat(DateTime d);
  String hourFormat(DateTime d);
  String dayFormat(DateTime d);
}
