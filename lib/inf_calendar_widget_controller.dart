import 'dart:async';

import 'package:flutter/material.dart';
import 'package:inf_calendar_widget/calendar_entry.dart';
import 'package:inf_calendar_widget/calendar_group.dart';
import 'package:inf_calendar_widget/utils/scale_level.dart';
import 'package:inf_calendar_widget/utils/date_extension.dart';
import 'package:intl/intl.dart';

class InfCalendarWidgetController extends ChangeNotifier {
  List<CalendarGroup> calendarGroups;
  ScaleLevel _scaleLevel = ScaleLevel.minutes();
  Duration _iteration = const Duration(minutes: 1);
  double _entryHeight = 20.0;
  double _widgetWidth = 100.0;
  double _scroll = 0.0;
  int _entriesPerScreen = 0;
  DateTime? _bufferStart;
  DateTime? _bufferEnd;
  DateTime _currentDate = DateTime.now();
  double _scaleFactor = 1.0;
  int _viewStartOffsetEntries = 0;
  DateTime _firstEntryOnScreen = DateTime.now();
  bool _zoomMode = false;
  double _mouseScale = 1;
  double _onScreenFocusPointOffset = 0;
  final _dataAreaStartOffset = 150;
  final double padding;

  final Function(CalendarEntry entry, String? calendarId)? onTap;

  InfCalendarWidgetController({
    this.padding = 10,
    this.calendarGroups = const <CalendarGroup>[],
    this.onTap,
  });

  bool get zoomMode => _zoomMode;

  set zoomMode(bool value) {
    _zoomMode = value;
    if (value) _mouseScale = 1;
    notifyListeners();
  }

  void scrollCalendar(double offset) {
    _scroll += offset;
    notifyListeners();
  }

  void scrollFling(double velocity) {
    double v = velocity;
    if (v.abs() > 20) {
      Timer.periodic(const Duration(milliseconds: 1), (timer) {
        _scroll += v / 30;
        v *= 0.9;
        if (v.abs() < 0.2) {
          timer.cancel();
          updateControllerValues();
        }
        notifyListeners();
      });
    }
    updateControllerValues();
    notifyListeners();
  }

  void scaleCalendar(double scale, double pointOffset) {
    _scaleFactor = scale;
    _onScreenFocusPointOffset = pointOffset;
    notifyListeners();
  }

  void mouseScaleCalendar(double scale, double pointOffset) {
    if (scale < 0) _mouseScale += 0.1;
    if (scale > 0) _mouseScale -= 0.1;
    scaleCalendar(_mouseScale, pointOffset);
  }

  handleMouseScroll(Offset offset, Offset pointerOffset) {
    final s = -offset.dy;
    if (zoomMode) {
      mouseScaleCalendar(s, pointerOffset.dy/2);
    } else {
      scrollCalendar(s);
    }
    Timer(const Duration(milliseconds: 25), () {
      updateControllerValues();
    });
  }

  void determinateViewPortDatesLimits({required BuildContext context}) {
    _entriesPerScreen = MediaQuery.of(context).size.height ~/ _entryHeight;
    _viewStartOffsetEntries = -_entriesPerScreen * 4;
    _bufferStart = _currentDate.add(_iteration * _viewStartOffsetEntries);
    if (_scaleLevel != ScaleLevel.minutes()) {
      _bufferStart = _bufferStart?.copyWith(
          minute: 0, second: 0, millisecond: 0, microsecond: 0);
    }
    _bufferEnd = _currentDate.add(_iteration * _entriesPerScreen * 5);
    _widgetWidth = MediaQuery.of(context).size.width;
  }

  List<Widget> updateView() {
    List<Widget> viewBuffer = [];
    final viewStartDate = _bufferStart!;
    final viewEndDate = _bufferEnd!;
    viewBuffer.addAll(_generateBackground());
    final crossDirectSize = _getGroupCrossDirectSize();
    for (final group in calendarGroups) {
      final indexOfGroup = calendarGroups.indexOf(group);
      for (final e in group.entries) {
        if (e.end.compareTo(viewStartDate) == -1 ||
            e.start.compareTo(viewEndDate) == 1) {
          continue;
        }
        viewBuffer.add(generateCrossFlowItem(
            startDate: e.start,
            endDate: e.end,
            title: e.title,
            crossDirectionSize: crossDirectSize,
            textDirection: 4,
            color: group.color,
            crossDirectionOffset: _dataAreaStartOffset +
                indexOfGroup * (crossDirectSize + padding),
            useTooltip: true,
            tapCallback: () {
              if (onTap != null) onTap!(e, group.id);
            }));
      }
    }
    return viewBuffer;
  }

  double _getGroupCrossDirectSize() {
    return ((_widgetWidth - _dataAreaStartOffset) / calendarGroups.length) -
        (padding * calendarGroups.length);
  }

  List<Widget> _generateBackground() {
    List<Widget> viewBuffer = [];
    final start = _bufferStart;
    final end = _bufferEnd;
    final scaledHeight = (_entryHeight * _scaleFactor);
    final viewStartOffset = _viewStartOffsetEntries * scaledHeight;
    int i = 0;

    if (start == null || end == null) return [];
    for (DateTime d = start;
        d.millisecondsSinceEpoch < end.millisecondsSinceEpoch;
        d = d.add(_iteration)) {
      final p = _scroll + viewStartOffset + i * scaledHeight;
      if (p + scaledHeight > 0 && p <= scaledHeight) _firstEntryOnScreen = d;

      if (_scaleLevel == ScaleLevel.months()) {
        viewBuffer.addAll(_generateMonthsView(i, d));
      }
      if (_scaleLevel == ScaleLevel.days()) {
        viewBuffer.addAll(_generateDaysView(i, d));
      }
      if (_scaleLevel == ScaleLevel.hours()) {
        viewBuffer.addAll(_generateHoursView(i, d));
      }
      if (_scaleLevel == ScaleLevel.minutes()) {
        viewBuffer.addAll(_generateMinutesView(i, d));
      }
      i++;
    }
    return viewBuffer;
  }

  Widget generateCrossFlowItem({
    required DateTime startDate,
    required DateTime endDate,
    required String title,
    double? crossDirectionSize,
    double crossDirectionOffset = 0,
    int textDirection = 0,
    AlignmentGeometry? alignment,
    Color? color,
    bool useTooltip = false,
    void Function()? tapCallback,
  }) {
    final viewStartDate = _bufferStart!;
    final start =
        startDate.millisecondsSinceEpoch > viewStartDate.millisecondsSinceEpoch
            ? startDate
            : viewStartDate;
    final viewEndDate = _bufferEnd!;
    final end =
        endDate.microsecondsSinceEpoch < viewEndDate.microsecondsSinceEpoch
            ? endDate
            : viewEndDate;

    final scaledHeight = _entryHeight * _scaleFactor;
    final viewStartOffset = _viewStartOffsetEntries * scaledHeight;
    final durationDivider = _iteration.inMicroseconds;
    final daysDiff =
        start.difference(viewStartDate).inMicroseconds ~/ durationDivider;

    final topPosition = _scroll +
        daysDiff * scaledHeight +
        viewStartOffset +
        _onScreenFocusPointOffset;
    double height = (end.difference(start).inMicroseconds ~/ durationDivider) *
        scaledHeight;
    if (height <= 0) height = 1;

    final body = GestureDetector(
      onTap: () {
        if (tapCallback != null) {
          tapCallback();
        } else if (onTap != null) {
          onTap!(CalendarEntry(start: start, end: end, title: title), null);
        }
      },
      child: Container(
        alignment: alignment,
        decoration: BoxDecoration(
            color: color ?? Colors.white,
            border:
                const Border(top: BorderSide(color: Colors.black, width: 1))),
        child: Stack(fit: StackFit.expand, children: [
          Positioned(
            top: topPosition < 0 ? -(topPosition) : 0,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight: height, maxWidth: crossDirectionSize ?? 0),
              child: RotatedBox(
                quarterTurns: textDirection,
                child: Text(title, softWrap: true),
              ),
            ),
          ),
        ]),
      ),
    );

    return Positioned(
        top: topPosition,
        left: crossDirectionOffset,
        width: crossDirectionSize,
        height: height,
        child: useTooltip ? Tooltip(message: title, child: body) : body);
  }

  void updateControllerValues() {
    _currentDate = _firstEntryOnScreen;
    _entryHeight *= _scaleFactor;
    _scaleFactor = 1.0;
    _scroll = 0.0;
    final oldScaleLevel = _scaleLevel.level;
    _scaleLevel = _scaleLevel.changeScaleLevel(entrySize: _entryHeight);
    if (_scaleLevel.level != oldScaleLevel) {
      _entryHeight = _scaleLevel.entrySize;
      _iteration = _scaleLevel.iterator;
      updateControllerValues();
    }
  }

  List<Widget> _generateMinutesView(int i, DateTime d) {
    List<Widget> viewBuffer = [];
    viewBuffer.add(generateCrossFlowItem(
      startDate: d,
      endDate: d.add(_iteration),
      title: DateFormat("HH : mm").format(d),
      crossDirectionSize: _widgetWidth,
      crossDirectionOffset: 40,
      alignment: Alignment.centerLeft,
      color: i % 2 == 0 ? Colors.grey.shade50 : null,
    ));

    if (i == 0 || (d.hour == 0 && d.minute == 0)) {
      viewBuffer.add(generateCrossFlowItem(
        startDate: d,
        endDate: d.add(const Duration(days: 1)),
        title: DateFormat("EEEE dd MMMM yyyy").format(d),
        crossDirectionSize: 20,
        crossDirectionOffset: 20,
        textDirection: 3,
        alignment: Alignment.center,
        color: Colors.grey.shade100,
      ));
    }
    if (i == 0 || (d.weekday == 1 && d.hour == 0 && d.minute == 0)) {
      viewBuffer.add(generateCrossFlowItem(
        startDate: d,
        endDate: d.add(const Duration(days: 6)),
        title: "Week: ${d.weekNumber()}",
        crossDirectionSize: 20,
        crossDirectionOffset: 0,
        textDirection: 3,
        alignment: Alignment.topLeft,
      ));
    }
    return viewBuffer;
  }

  List<Widget> _generateHoursView(int i, DateTime d) {
    List<Widget> viewBuffer = [];
    if (i == 0 || d.minute == 0) {
      viewBuffer.add(generateCrossFlowItem(
        startDate: d,
        endDate: d.add(_iteration * 24),
        title: DateFormat("HH:00").format(d),
        crossDirectionSize: _widgetWidth,
        crossDirectionOffset: 40,
        alignment: Alignment.centerLeft,
        color: i % 2 == 0 ? Colors.grey.shade50 : null,
      ));
    }
    if (i == 0 || (d.hour == 0 && d.minute == 0)) {
      viewBuffer.add(generateCrossFlowItem(
        startDate: d,
        endDate: d.add(const Duration(days: 1)),
        title: DateFormat("EEEE dd MMMM yyyy").format(d),
        crossDirectionSize: 20,
        crossDirectionOffset: 20,
        textDirection: 3,
        color: Colors.grey.shade100,
      ));
    }
    if (i == 0 || (d.weekday == 1 && d.hour == 0 && d.minute == 0)) {
      viewBuffer.add(generateCrossFlowItem(
        startDate: d,
        endDate: d.add(const Duration(days: 6)),
        title: "Week: ${d.weekNumber()}",
        crossDirectionSize: 20,
        crossDirectionOffset: 0,
        textDirection: 3,
      ));
    }
    return viewBuffer;
  }

  List<Widget> _generateDaysView(int i, DateTime d) {
    List<Widget> viewBuffer = [];
    if (i == 0 || d.hour == 0) {
      viewBuffer.add(generateCrossFlowItem(
        startDate: d,
        endDate: d.add(const Duration(days: 1)),
        title: DateFormat("EEE dd").format(d),
        crossDirectionSize: _widgetWidth,
        crossDirectionOffset: 70,
        alignment: Alignment.centerLeft,
        color: i % 2 == 0 ? Colors.grey.shade50 : null,
      ));
    }
    if (i == 0 || (d.day == 1 && d.hour == 0)) {
      viewBuffer.add(generateCrossFlowItem(
        startDate: d,
        endDate: d.addMonths(1),
        title: DateFormat("MMM - yyyy").format(d),
        crossDirectionSize: 50,
        textDirection: 3,
        alignment: Alignment.center,
      ));
    }
    if (i == 0 || (d.weekday == 1 && d.hour == 0)) {
      viewBuffer.add(generateCrossFlowItem(
        startDate: d,
        endDate: d.add(const Duration(days: 6)),
        title: "wk: ${d.weekNumber()}",
        crossDirectionSize: 20,
        crossDirectionOffset: 50,
        textDirection: 3,
        alignment: Alignment.topLeft,
      ));
    }
    return viewBuffer;
  }

  List<Widget> _generateMonthsView(int i, DateTime d) {
    List<Widget> viewBuffer = [];
    if (i == 0 || (d.month == 1 && d.day == 1)) {
      viewBuffer.add(generateCrossFlowItem(
        startDate: d,
        endDate: d.addMonths(12),
        title: DateFormat("yyyy").format(d),
        crossDirectionSize: 20,
        textDirection: 3,
        alignment: Alignment.center,
      ));
    }
    if (i == 0 || d.day == 1) {
      viewBuffer.add(generateCrossFlowItem(
        startDate: d,
        endDate: d.addMonths(1),
        title: DateFormat("MMM").format(d),
        crossDirectionSize: 20,
        crossDirectionOffset: 20,
        textDirection: 3,
        alignment: Alignment.center,
      ));
    }
    if (i == 0 || d.weekday == 1) {
      viewBuffer.add(generateCrossFlowItem(
        startDate: d,
        endDate: d.add(const Duration(days: 6)),
        title: "wk: ${d.weekNumber()}",
        crossDirectionSize: _widgetWidth,
        crossDirectionOffset: 40,
        textDirection: 0,
        alignment: Alignment.topLeft,
        color: i % 2 == 0 ? Colors.grey.shade50 : null,
      ));
    }
    return viewBuffer;
  }
}
