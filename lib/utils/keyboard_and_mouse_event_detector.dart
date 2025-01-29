import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class KeyboardAndMouseEventDetector extends StatelessWidget {
  const KeyboardAndMouseEventDetector({
    super.key,
    required this.onScroll,
    required this.child,
    required this.onCtrlKey,
  });

  final void Function(Offset event, Offset pointerOffset) onScroll;
  final void Function(bool) onCtrlKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: (e) {
        if (e is PointerScrollEvent) {
          final pointerOffset = e.position;
          onScroll(e.scrollDelta, pointerOffset);
        }
      },
      child: Focus(
        autofocus: true,
        onKeyEvent: (context, event) {
          if (event is KeyDownEvent &&
              event.physicalKey == PhysicalKeyboardKey.controlLeft) {
            onCtrlKey(true);
            return KeyEventResult.handled;
          } else {
            onCtrlKey(false);
          }
          return KeyEventResult.ignored;
        },
        child: child,
      ),
    );
  }
}
