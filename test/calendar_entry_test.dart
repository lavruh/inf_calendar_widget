import 'package:flutter_test/flutter_test.dart';
import 'package:inf_calendar_widget/calendar_entry.dart';

main() {
  final entry = CalendarEntry(
      start: DateTime(2025, 1, 10), end: DateTime(2025, 1, 20), title: "entry");
  final intInFront = CalendarEntry(
      start: DateTime(2025, 1, 5), end: DateTime(2025, 1, 15), title: "front");
  final intInRear = CalendarEntry(
      start: DateTime(2025, 1, 15), end: DateTime(2025, 1, 25), title: "rear");
  final overlap = CalendarEntry(
      start: DateTime(2025, 1, 5), end: DateTime(2025, 1, 25), title: "overlap");
  final include = CalendarEntry(
      start: DateTime(2025, 1, 11), end: DateTime(2025, 1, 17), title: "include");


  test("is mot intersect", () {
    final before = CalendarEntry(
        start: DateTime(2025, 1, 1), end: DateTime(2025, 1, 2), title: "before");
    final after = CalendarEntry(
        start: DateTime(2025, 2, 1), end: DateTime(2025, 2, 2), title: "after");

    expect(entry.isNotIntersecting(before), true);
    expect(entry.isNotIntersecting(after), true);
    expect(entry.isNotIntersecting(intInFront), false);
    expect(entry.isNotIntersecting(intInRear), false);
    expect(entry.isNotIntersecting(overlap), false);
    expect(entry.isNotIntersecting(include), false);
    expect(entry.isNotIntersecting(entry), false);
  });

  test("is intersect", () {
    expect(entry.intersects(intInFront), true);
    expect(entry.intersects(intInRear), true);
    expect(entry.intersects(overlap), true);
    expect(entry.intersects(include), true);
    expect(entry.intersects(entry), true);
  });
}
