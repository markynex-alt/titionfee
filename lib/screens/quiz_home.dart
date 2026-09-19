import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/question.dart';
import '../controllers/quiz_timer.dart';
import '../utils/bangla_number.dart';
import '../utils/timer_widget.dart';
import 'result_page.dart';

class QuizHome extends StatefulWidget {
  const QuizHome({Key? key}) : super(key: key);

  @override
  State<QuizHome> createState() => _QuizHomeState();
}

class _QuizHomeState extends State<QuizHome> {
  final QuizTimer _timer = QuizTimer();
  final String _dataUrl = 'https://markynex.com/questions.json';

  List<Question> _questions = [];
  int _currentIndex = 0;
  double _score = 0;

  bool _loading = true;
  bool _hasError = false;

  int _timeLeft = 8;
  int? _selectedIndex;
  bool? _isCorrect;

  @override
  void initState() {
    super.initState();

    _timer.onTick = (value) {
      if (!mounted) return;
      setState(() => _timeLeft = value);
    };

    _timer.onTimeUp = _handleTimeOut;

    _loadQuestions();
  }

  @override
  void dispose() {
    _timer.dispose();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _hasError = false;
      _score = 0;
      _currentIndex = 0;
      _questions.clear();
      _selectedIndex = null;
      _isCorrect = null;
      _timeLeft = 8;
    });

    try {
      final response = await http.get(Uri.parse(_dataUrl));

      if (response.statusCode != 200) {
        throw Exception('Failed to load questions');
      }

      final List data = json.decode(response.body);
      final List<Question> loaded = data
          .map((e) => Question.fromJson(e))
          .toList();

      loaded.shuffle(Random());

      if (!mounted) return;
      setState(() {
        _questions = loaded.take(10).toList();
        _loading = false;
      });

      _timer.start();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _loading = false;
      });
    }
  }

  void _answerQuestion(int index) {
    if (_selectedIndex != null) return;

    _timer.stop();

    final correctAnswer = _questions[_currentIndex].answer;
    final bool correct = index == correctAnswer;

    setState(() {
      _selectedIndex = index;
      _isCorrect = correct;
      _score += correct ? 1 : -0.50;
    });

    Future.delayed(const Duration(milliseconds: 500), _goNext);
  }

  void _handleTimeOut() {
    if (!mounted) return;

    setState(() {
      _isCorrect = false;
      _selectedIndex = null;
      _score -= 0.25;
    });

    Future.delayed(const Duration(milliseconds: 500), _goNext);
  }

  void _goNext() {
    if (!mounted) return;

    _timer.stop();

    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedIndex = null;
        _isCorrect = null;
        _timeLeft = 8;
      });
      _timer.start();
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ResultPage(score: _score)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_hasError) {
      return Scaffold(
        appBar: AppBar(title: const Text('ত্রুটি')),
        body: Center(
          child: ElevatedButton(
            onPressed: _loadQuestions,
            child: const Text('পুনরায় চেষ্টা করুন'),
          ),
        ),
      );
    }

    final question = _questions[_currentIndex];

    return Scaffold(
      appBar: AppBar(title: const Text('হাবলু কুইজ'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'প্রশ্ন ${toBanglaNumber(_currentIndex + 1)}'
                  '/${toBanglaNumber(_questions.length)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
                TimerWidget(timeLeft: _timeLeft),
              ],
            ),

            const SizedBox(height: 20),

            /// QUESTION
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Colors.indigo.shade50,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  question.question,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            /// OPTIONS
            ...List.generate(question.options.length, (index) {
              Color bgColor = Colors.white;

              if (_selectedIndex != null) {
                if (index == question.answer) {
                  bgColor = Colors.green;
                } else if (index == _selectedIndex && _isCorrect == false) {
                  bgColor = Colors.red;
                }
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _selectedIndex == null
                      ? () => _answerQuestion(index)
                      : null,
                  child: Container(
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.indigo.shade100,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ListTile(
                      title: Text(
                        question.options[index],
                        style: const TextStyle(fontSize: 18),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    ),
                  ),
                ),
              );
            }),

            const Spacer(),

            /// SKIP
            Center(
              child: OutlinedButton(
                onPressed: () {
                  _timer.stop();
                  setState(() => _score -= 0.25);
                  _goNext();
                },
                child: const Text('পাস (Skip)', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
