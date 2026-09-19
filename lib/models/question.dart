class Question {
  final String question;
  final List<String> options;
  final int answer;

  Question(this.question, this.options, this.answer);

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      json['question'],
      List<String>.from(json['options']),
      json['answer'],
    );
  }
}
