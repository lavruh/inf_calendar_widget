import 'package:flutter/material.dart';
import 'package:inf_calendar_widget/calendar_entry.dart';
import 'package:inf_calendar_widget/utils/color_extension.dart';
import 'package:uuid/uuid.dart';

class CalendarGroup {
  final String id;
  final String title;
  final List<CalendarEntry> entries;
  final Color color;

  CalendarGroup(
      {required this.title, required this.entries, Color? color, String? id})
      : color = color ?? Colors.green,
        id = id ?? const Uuid().v4().replaceAll("-", "");

  @override
  String toString() {
    return '\nCalendarGroup[$id]{title: $title entries ${entries.length} \n';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalendarGroup &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  factory CalendarGroup.settingsFromMap(Map<String, dynamic> map) {
    final c = map['color'];
    return CalendarGroup(
      id: map['id'],
      title: map['title'],
      entries: [],
      color:
          HexColor.fromHex(c), // Assuming color is stored as an int in the map
    );
  }

  CalendarGroup copyWith({
    String? id,
    String? title,
    List<CalendarEntry>? entries,
    Color? color,
  }) {
    return CalendarGroup(
      id: id ?? this.id,
      title: title ?? this.title,
      entries: entries ?? this.entries,
      color: color ?? this.color,
    );
  }

  Map<String, dynamic> settingsToMap() {
    return {
      "id": id,
      "title": title,
      "color": color.toHex(),
    };
  }
}
