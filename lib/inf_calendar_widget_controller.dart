import 'dart:async';

import 'package:flutter/material.dart';
import 'package:inf_calendar_widget/calendar_entry.dart';
import 'package:inf_calendar_widget/calendar_group.dart';
import 'package:inf_calendar_widget/date_ranges_intersection.dart';
import 'package:inf_calendar_widget/header_settings.dart';
import 'package:inf_calendar_widget/title_widget.dart';
import 'package:inf_calendar_widget/utils/scale_level.dart';
import 'package:inf_calendar_widget/utils/date_extension.dart';
import 'package:inf_calendar_widget/view_mode.dart';
import 'package:inf_calendar_widget/view_mode_vertical.dart';
import 'package:intl/intl.dart';

import 'calendar_entry_widget.dart';
import 'entry_title_widget.dart';

class InfCalendarWidgetController extends ChangeNotifier {
  List<CalendarGroup> calendarGroups;
  late ScaleLevel _scaleLevel;
  late Duration _iteration;
  late double _entrySize;
  late final ViewMode _viewMode;

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
  final Color nowBackgroundColor;
  final Color backgroundColor;
  final Color backgroundShadeColor;
  final Color textColor;
  final bool showHeader;

  final Function(CalendarEntry entry, String? calendarId)? onTap;
  final Widget Function({required String title, required Color textColor})
      entryTitleBuilder;
  final Widget Function({required String title, required Color textColor})
      calendarTitleBuilder;
  final Widget Function({required Widget title, required Color backgroundColor})
      entryWidgetBuilder;

  InfCalendarWidgetController({
    this.calendarGroups = const <CalendarGroup>[],
    ViewMode? viewMode,
    this.onTap,
    ScaleLevel? scaleLevel,
    double? initScale,
    this.showHeader = true,
    this.nowBackgroundColor = const Color(0xFFFFE082),
    this.backgroundColor = Colors.white,
    this.backgroundShadeColor = const Color(0xffd3d3d3),
    this.textColor = Colors.black,
    this.entryTitleBuilder = defaultEntryTitleWidget,
    this.calendarTitleBuilder = defaultTitleWidget,
    this.entryWidgetBuilder = defaultEntryWidget,
  })  : _scaleLevel = scaleLevel ?? ScaleLevel.hours(),
        _scaleFactor = initScale ?? 1.0,
        _viewMode = viewMode ?? ViewModeVertical() {
    _entrySize = _scaleLevel.initEntrySize;
    _iteration = _scaleLevel.iterator;
    updateControllerValues();
    notifyListeners();
  }

  bool get zoomMode => _zoomMode;

  set zoomMode(bool value) {
    _zoomMode = value;
    if (value) _mouseScale = 1;
    notifyListeners();
  }

  void scrollCalendar(Offset offset) {
    _scroll += _viewMode.getValueInCorrectDirection(offset);
    notifyListeners();
  }

  void scrollFling(Offset velocity) {
    double v = _viewMode.getValueInCorrectDirection(velocity);
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
      mouseScaleCalendar(s, pointerOffset.dy / 2);
    } else {
      _scroll += s;
      notifyListeners();
    }
    Timer(const Duration(milliseconds: 25), () {
      updateControllerValues();
    });
  }

  void determinateViewPortDatesLimits({required BuildContext context}) {
    _entriesPerScreen = _viewMode.entriesPerScreen(
      screenSize: MediaQuery.of(context).size,
      entrySize: _entrySize,
    );

    _viewStartOffsetEntries = -_entriesPerScreen * 4;
    _bufferStart = _currentDate.add(_iteration * _viewStartOffsetEntries);
    if (_scaleLevel != ScaleLevel.minutes()) {
      _bufferStart = _bufferStart?.copyWith(
          minute: 0, second: 0, millisecond: 0, microsecond: 0);
    }
    _bufferEnd = _currentDate.add(_iteration * _entriesPerScreen * 5);
    _viewMode.setWidgetCrossAxisSize(MediaQuery.of(context).size);
  }

  List<Widget> generateHeader(HeaderSettings settings) {
    List<Widget> buffer = [];

    final size = settings.size;

    buffer.add(_viewMode.itemWidget(
      position: 0,
      size: size,
      crossDirectionOffset: 0,
      crossDirectionSize: _viewMode.widgetCrossAxisSize,
      child: Container(color: settings.backgroundColor),
    ));

    final crossDirectionSize =
        _viewMode.groupCrossAxisSize(calendarGroups.length);
    final padding = _viewMode.groupPadding;
    final dataAreaStartOffset = _viewMode.dataAreaStartOffset;
    for (int i = 0; i < calendarGroups.length; i++) {
      final group = calendarGroups[i];
      final child = settings.headerWidget;

      final position = dataAreaStartOffset + i * (crossDirectionSize + padding);

      buffer.add(_viewMode.itemWidget(
          position: 0,
          size: size - padding,
          crossDirectionOffset: position,
          crossDirectionSize: crossDirectionSize,
          child: child(group)));
    }

    return buffer;
  }

  List<Widget> updateView() {
    List<Widget> viewBuffer = [];
    final view =
        CalendarEntry(start: _bufferStart!, end: _bufferEnd!, title: "");

    viewBuffer.addAll(_generateBackground());
    final crossDirectSize = _viewMode.groupCrossAxisSize(calendarGroups.length);
    final padding = _viewMode.groupPadding;
    final dataAreaStartOffset = _viewMode.dataAreaStartOffset;

    final intersection = DateRangesIntersectionChecker();
    for (final group in calendarGroups) {
      final indexOfGroup = calendarGroups.indexOf(group);
      List<CalendarEntry> entries = group.entries;
      entries.sort((a, b) => a.start.compareTo(b.start));

      double entrySize = crossDirectSize;
      double entryOffset =
          dataAreaStartOffset + indexOfGroup * (crossDirectSize + padding);

      if (entries.isEmpty) continue;
      for (int i = 0; i < entries.length; i++) {
        final e = entries[i];
        if (e.isNotIntersecting(view)) continue;

        final next = i < entries.length - 1 ? entries[i + 1] : null;

        if (next != null) {
          if (intersection.checkAndUpdateIntersection(e, next)) continue;
        }

        final intersectionWidgets = intersection.getIntersectingItems(
            size: entrySize,
            crossDirectionOffset: entryOffset,
            widgetGenerator: (
                    {required double size,
                    required double offset,
                    required CalendarEntry entry}) =>
                generateCrossFlowItem(
                    startDate: entry.start,
                    endDate: entry.end,
                    title: entry.title,
                    crossDirectionSize: size,
                    color: group.color,
                    crossDirectionOffset: offset,
                    useTooltip: true,
                    titlePosWidget: (titleWidget) => entryWidgetBuilder(
                        title: titleWidget, backgroundColor: group.color),
                    tapCallback: () {
                      if (onTap != null) onTap!(entry, group.id);
                    }));

        if (intersectionWidgets.isNotEmpty) {
          viewBuffer.addAll(intersectionWidgets);
        } else {
          viewBuffer.add(generateCrossFlowItem(
              startDate: e.start,
              endDate: e.end,
              title: e.title,
              crossDirectionSize: entrySize,
              color: group.color,
              crossDirectionOffset: entryOffset,
              useTooltip: true,
              titlePosWidget: (titleWidget) => entryWidgetBuilder(
                  title: titleWidget, backgroundColor: group.color),
              tapCallback: () {
                if (onTap != null) onTap!(e, group.id);
              }));
        }
      }
    }
    if (showHeader) {
      viewBuffer.addAll(generateHeader(_viewMode.headerSettings));
    }
    return viewBuffer;
  }

  List<Widget> _generateBackground() {
    List<Widget> viewBuffer = [];
    final start = _bufferStart;
    final end = _bufferEnd;
    final scaledSize = (_entrySize * _scaleFactor);
    final viewStartOffset = _viewStartOffsetEntries * scaledSize;
    int i = 0;

    if (start == null || end == null) return [];
    for (DateTime d = start;
        d.millisecondsSinceEpoch < end.millisecondsSinceEpoch;
        d = d.add(_iteration)) {
      final p = _scroll + viewStartOffset + i * scaledSize;
      if (p + scaledSize > 0 && p <= scaledSize) _firstEntryOnScreen = d;

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
    bool? textDirectionStraight,
    Color? color,
    bool useTooltip = false,
    void Function()? tapCallback,
    Widget Function(Widget title)? titlePosWidget,
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

    final scaledSize = _entrySize * _scaleFactor;
    final viewStartOffset = _viewStartOffsetEntries * scaledSize;
    final durationDivider = _iteration.inMicroseconds;
    final daysDiff =
        start.difference(viewStartDate).inMicroseconds ~/ durationDivider;

    final position = _scroll +
        daysDiff * scaledSize +
        viewStartOffset +
        _onScreenFocusPointOffset;

    double size =
        (end.difference(start).inMicroseconds ~/ durationDivider) * scaledSize;
    if (size <= 0) size = 1;

    final titleWidget =
        entryTitleBuilder(title: title, textColor: Colors.black);

    final body = GestureDetector(
        onTap: () {
          if (tapCallback != null) {
            tapCallback();
          } else if (onTap != null) {
            onTap!(CalendarEntry(start: start, end: end, title: title), null);
          }
        },
        child: titlePosWidget != null
            ? titlePosWidget(titleWidget)
            : _viewMode.titlePositionWidget(
                parentPosition: position,
                parentSize: size,
                backgroundColor: color ?? backgroundColor,
                textDirectionStraight: textDirectionStraight ?? true,
                title:
                    calendarTitleBuilder(title: title, textColor: Colors.black),
                crossDirectionSize: crossDirectionSize,
              ));

    return _viewMode.itemWidget(
        position: position,
        size: size,
        crossDirectionOffset: crossDirectionOffset,
        crossDirectionSize: crossDirectionSize,
        child: useTooltip ? Tooltip(message: title, child: body) : body);
  }

  void updateControllerValues() {
    _currentDate = _firstEntryOnScreen;
    _entrySize *= _scaleFactor;
    _scaleFactor = 1.0;
    _scroll = 0.0;
    final oldScaleLevel = _scaleLevel.level;
    _scaleLevel = _scaleLevel.changeScaleLevel(entrySize: _entrySize);
    if (_scaleLevel.level != oldScaleLevel) {
      _entrySize = _scaleLevel.entrySize;
      _iteration = _scaleLevel.iterator;
      updateControllerValues();
    }
  }

  Color _chooseColor(int i, bool isNow) {
    final color = i % 2 == 0 ? backgroundColor : backgroundShadeColor;
    return isNow ? nowBackgroundColor : color;
  }

  List<Widget> _generateMinutesView(int i, DateTime d) {
    List<Widget> viewBuffer = [];
    viewBuffer.add(generateCrossFlowItem(
      startDate: d,
      endDate: d.add(_iteration),
      title: _viewMode.minHourFormat(d),
      crossDirectionSize: _viewMode.widgetCrossAxisSize,
      crossDirectionOffset: 40,
      color: _chooseColor(i, d.isSameMinute(DateTime.now())),
    ));

    if (i == 0 || (d.hour == 0 && d.minute == 0)) {
      viewBuffer.add(generateCrossFlowItem(
        startDate: d,
        endDate: d.add(const Duration(days: 1)),
        title: DateFormat("EEEE dd MMMM yyyy").format(d),
        crossDirectionSize: 20,
        crossDirectionOffset: 20,
        textDirectionStraight: false,
        color: backgroundShadeColor,
      ));
    }
    if (i == 0 || (d.weekday == 1 && d.hour == 0 && d.minute == 0)) {
      viewBuffer.add(generateCrossFlowItem(
        startDate: d,
        endDate: d.add(const Duration(days: 6)),
        title: "Week: ${d.weekNumber()}",
        crossDirectionSize: 20,
        crossDirectionOffset: 0,
        textDirectionStraight: false,
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
        title: _viewMode.hourFormat(d),
        crossDirectionSize: _viewMode.widgetCrossAxisSize,
        crossDirectionOffset: 40,
        color: _chooseColor(d.hour, d.isSameHour(DateTime.now())),
      ));
    }
    if (i == 0 || (d.hour == 0 && d.minute == 0)) {
      viewBuffer.add(generateCrossFlowItem(
        startDate: d,
        endDate: d.add(const Duration(days: 1)),
        title: DateFormat("EEEE dd MMMM yyyy").format(d),
        crossDirectionSize: 20,
        crossDirectionOffset: 20,
        textDirectionStraight: false,
        color: backgroundShadeColor,
      ));
    }
    if (i == 0 || (d.weekday == 1 && d.hour == 0 && d.minute == 0)) {
      viewBuffer.add(generateCrossFlowItem(
        startDate: d,
        endDate: d.add(const Duration(days: 6)),
        title: "Week: ${d.weekNumber()}",
        crossDirectionSize: 20,
        crossDirectionOffset: 0,
        textDirectionStraight: false,
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
        title: _viewMode.dayFormat(d),
        crossDirectionSize: _viewMode.widgetCrossAxisSize,
        crossDirectionOffset: 70,
        color: _chooseColor((i / 24).floor(), d.isSameDate(DateTime.now())),
      ));
    }
    if (i == 0 || (d.day == 1 && d.hour == 0)) {
      viewBuffer.add(generateCrossFlowItem(
        startDate: d,
        endDate: d.addMonths(1),
        title: DateFormat("MMM - yyyy").format(d),
        crossDirectionSize: 50,
        textDirectionStraight: false,
      ));
    }
    if (i == 0 || (d.weekday == 1 && d.hour == 0)) {
      viewBuffer.add(generateCrossFlowItem(
        startDate: d,
        endDate: d.add(const Duration(days: 6)),
        title: "wk: ${NumberFormat("00").format(d.weekNumber())}",
        crossDirectionSize: 20,
        crossDirectionOffset: 50,
        textDirectionStraight: false,
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
        textDirectionStraight: false,
      ));
    }
    if (i == 0 || d.day == 1) {
      viewBuffer.add(generateCrossFlowItem(
        startDate: d,
        endDate: d.addMonths(1),
        title: DateFormat("MMM").format(d),
        crossDirectionSize: 20,
        crossDirectionOffset: 20,
        textDirectionStraight: false,
      ));
    }
    if (i == 0 || d.weekday == 1) {
      viewBuffer.add(generateCrossFlowItem(
        startDate: d,
        endDate: d.add(const Duration(days: 7)),
        title: NumberFormat("00").format(d.weekNumber()),
        crossDirectionSize: _viewMode.widgetCrossAxisSize,
        crossDirectionOffset: 40,
        color: _chooseColor(i, d.isSameWeek(DateTime.now())),
      ));
    }
    return viewBuffer;
  }

  static Widget defaultEntryWidget(
          {required Widget title, required Color backgroundColor}) =>
      CalendarEntryWidget(title: title, backgroundColor: backgroundColor);

  static Widget defaultTitleWidget(
          {required String title, required Color textColor}) =>
      TitleWidget(title: title, textColor: textColor);

  static Widget defaultEntryTitleWidget(
          {required String title, required Color textColor}) =>
      EntryTitleWidget(title: title, textColor: textColor);
}
