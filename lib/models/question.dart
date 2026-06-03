class Question {
  final String question;
  final List<String> options;
  final int correctIndex;
  final int points;

  Question({
    required this.question,
    required this.options,
    required this.correctIndex,
    this.points = 10,
  });
}
