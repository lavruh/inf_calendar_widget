import 'package:flutter/material.dart';
import 'package:inf_calendar_widget/inf_calendar_widget_controller.dart';
import 'package:inf_calendar_widget/utils/keyboard_and_mouse_event_detector.dart';

class InfCalendarView extends StatefulWidget {
  const InfCalendarView({super.key, required this.controller});

  final InfCalendarWidgetController controller;

  @override
  State<InfCalendarView> createState() => _InfCalState();
}

class _InfCalState extends State<InfCalendarView> {
  late InfCalendarWidgetController controller;

  @override
  void initState() {
    super.initState();
    controller = widget.controller;
    controller.addListener(_rebuild);
  }

  _rebuild() => setState(() {});

  @override
  void dispose() {
    controller.removeListener(_rebuild);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    controller.determinateViewPortDatesLimits(context: context);
    return KeyboardAndMouseEventDetector(
      onScroll: (d, p) => controller.handleMouseScroll(d, p),
      onCtrlKey: (b) => controller.zoomMode = b,
      child: GestureDetector(
        onScaleUpdate: (details) {
          if (details.scale != 1.0) {
            final focalPoint =
                details.focalPoint.dy + details.focalPointDelta.dy / 2;
            controller.scaleCalendar(details.scale, focalPoint);
          }
          controller.scrollCalendar(details.focalPointDelta);
        },
        onScaleEnd: (details) {
          controller.scrollFling(details.velocity.pixelsPerSecond);
        },
        child: Stack(
          children: [
            Container(color: Colors.white),
            ...controller.updateView(),
          ],
        ),
      ),
    );
  }
}
