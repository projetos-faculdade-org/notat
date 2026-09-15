import 'package:flutter/material.dart';

class CustomSnackBar {
  final String message;
  final Duration duration;
  CustomSnackBar({required this.message, required this.duration});

  static show(BuildContext context, String message, Duration duration) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Theme.of(context).cardColor,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        content: Text(message)));
  }

  // Uses the app's root ScaffoldMessengerKey instead of a local context, so
  // the message survives a Navigator.pop() of the screen that triggered it
  // (a local ScaffoldMessenger is torn down together with its screen).
  static showGlobal(
      GlobalKey<ScaffoldMessengerState> messengerKey, String message,
      [Duration duration = const Duration(seconds: 2)]) {
    messengerKey.currentState?.showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: duration,
        content: Text(message)));
  }
}
