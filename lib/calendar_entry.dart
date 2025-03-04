import 'package:uuid/uuid.dart';

class CalendarEntry {
  final String id;
  final DateTime start;
  final DateTime end;
  final String title;

  CalendarEntry({
    String? id,
    required this.start,
    required this.end,
    required this.title,
  }) : id = id ?? const Uuid().v4().replaceAll("-", "");

  @override
  String toString() {
    return 'CalendarEntry{$start - $end, title: $title}';
  }

  factory CalendarEntry.fromMap(Map<String, dynamic> map) {
    final int start = map['start'];
    final int end = map['end'];
    assert(start < end);
    return CalendarEntry(
      start: DateTime.fromMillisecondsSinceEpoch(start),
      end: DateTime.fromMillisecondsSinceEpoch(end),
      title: map['title'] ?? "",
      id: map['id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "start": start.millisecondsSinceEpoch,
      "end": end.millisecondsSinceEpoch,
      "title": title,
      "id": id,
    };
  }

  CalendarEntry copyWith({
    DateTime? start,
    DateTime? end,
    String? title,
    String? id,
  }) {
    return CalendarEntry(
      start: start ?? this.start,
      end: end ?? this.end,
      title: title ?? this.title,
      id: id ?? this.id,
    );
  }

  bool intersects(CalendarEntry other) {
    return !isNotIntersecting(other);
  }

  bool isNotIntersecting(CalendarEntry other) {
    return other.end.isBefore(start) || other.start.isAfter(end);
  }
}
