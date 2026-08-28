import 'package:flutter/material.dart';
import 'bangla_number.dart';

class TimerWidget extends StatelessWidget {
  final int timeLeft;

  const TimerWidget({super.key, required this.timeLeft});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.timer, color: Colors.red),
        const SizedBox(width: 6),
        Text(
          "${toBanglaNumber(timeLeft)} সেকেন্ড",
          style: const TextStyle(
            fontSize: 20,
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
