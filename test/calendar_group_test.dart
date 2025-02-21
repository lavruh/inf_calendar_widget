import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inf_calendar_widget/inf_calendar_widget.dart';
import 'package:inf_calendar_widget/utils/color_extension.dart';

main() {
  //create test for calendar group toMap

  test('Test toMap method of CalendarGroup', () {
    final group = CalendarGroup(
      id: '1',
      title: 'Test Group',
      color: Colors.blue,
      entries: [],
    );

    final map = group.settingsToMap();

    expect(map['id'], '1');
    expect(map['title'], 'Test Group');
    expect(map['color'], Colors.blue.toHex());
  });

  test("toMap and fromMap", (){
    final group = CalendarGroup(
      id: '1',
      title: 'Test Group',
      color: Colors.blue,
      entries: [],
    );

    final map = group.settingsToMap();
    final newGroup = CalendarGroup.settingsFromMap(map);
    expect(newGroup, group);
  });
}