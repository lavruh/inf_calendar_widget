import 'package:flutter/material.dart';

abstract class ViewMode {
  ViewMode({
    required this.entryMainAxisSize,
    required this.dataAreaStartOffset,
    required this.groupPadding,
  });

  double entryMainAxisSize;
  final double dataAreaStartOffset;
  double widgetCrossAxisSize = 100;
  double groupPadding;

  double groupCrossAxisSize(int groupsLength) {
    return ((widgetCrossAxisSize - dataAreaStartOffset) / groupsLength) -
        (groupPadding * groupsLength);
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
}
