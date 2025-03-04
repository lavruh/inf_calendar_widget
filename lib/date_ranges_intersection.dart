import 'package:flutter/material.dart';
import 'package:inf_calendar_widget/calendar_entry.dart';

class DateRangesIntersectionChecker {
  static DateRangesIntersectionChecker? _instance;
  DateRangesIntersectionChecker._();

  factory DateRangesIntersectionChecker() {
    _instance ??= DateRangesIntersectionChecker._();
    return _instance!;
  }

  CalendarEntry? _range;
  Map<String, CalendarEntry> items = {};

  CalendarEntry get range {
    final r = _range;
    if (r == null) throw Exception("Init first");
    return r;
  }

  set range(CalendarEntry? e) {
    _range = e;
    if (e == null) {
      items = {};
    } else {
      items.addAll({e.id: e});
    }
  }

  bool _isIntersects(CalendarEntry e) {
    if (range.isNotIntersecting(e)) return false;
    return true;
  }

  _addIntersectingItem(CalendarEntry e) {
    final minStart = range.start.isBefore(e.start) ? range.start : e.start;
    final maxEnd = range.end.isAfter(e.end) ? range.end : e.end;
    items.addAll({e.id: e});
    _range = CalendarEntry(id: e.id, start: minStart, end: maxEnd, title: "");
  }

  bool checkAndUpdateIntersection(CalendarEntry e1, CalendarEntry e2) {
    range = e1;
    if (_isIntersects(e2)) {
      _addIntersectingItem(e1);
      _addIntersectingItem(e2);
      return true;
    }
    range = null;
    return false;
  }

  List<Widget> getIntersectingItems({
    required double size,
    required double crossDirectionOffset,
    required Widget Function({
      required double size,
      required double offset,
      required CalendarEntry entry,
    }) widgetGenerator,
  }) {
    if (items.isNotEmpty) {
      List<Widget> buffer = [];
      final padding = 2;
      final numberOfItems = items.length;
      final intersectionSize = size / numberOfItems - padding;
      for (int i = 0; i < numberOfItems; i++) {
        final item = items.values.elementAt(i);
        final intersectionOffset =
            crossDirectionOffset + (i * (intersectionSize + padding));
        buffer.add(widgetGenerator(
          entry: item,
          size: intersectionSize,
          offset: intersectionOffset,
        ));
      }
      range = null;
      return buffer;
    }
    return [];
  }
}
