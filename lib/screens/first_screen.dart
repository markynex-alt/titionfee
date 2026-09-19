import 'package:flutter/material.dart';
import 'quiz_home.dart';

class FirstScreen extends StatelessWidget {
  const FirstScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "এই কুইজ গেমটি খেলে তুমি তোমার সাধারণ জ্ঞান বৃদ্ধি করতে পারো ও সঠিক উত্তর দিয়ে জিতে নিতে পারো আকর্ষণীয় পুরস্কার! 🎉",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: "NotoSerifBengali",
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 40),

                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const QuizHome(),
                            ),
                          );
                        },
                        child: const Text(
                          "চলো শুরু করি",
                          style: TextStyle(
                            fontFamily: "NotoSerifBengali",
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Version & Developer Info
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  Text(
                    "Version 6.1.0+21 | Developed by Markynex",
                    style: TextStyle(
                      fontFamily: "NotoSerifBengali",
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
