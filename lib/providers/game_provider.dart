import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/question.dart';
import '../services/api_service.dart';

enum GameState { idle, playing, answering, finished }

class GameProvider extends ChangeNotifier {
  static const int totalQuestions = 10;
  static const int timePerQuestion = 15;

  GameState _state = GameState.idle;
  List<Question> _questions = [];
  int _currentIndex = 0;
  int _score = 0;
  int _correctCount = 0;
  int _wrongCount = 0;
  int _timeLeft = timePerQuestion;
  int _totalPointsEarned = 0;
  Timer? _timer;
  int? _selectedAnswer;
  int? _correctAnswer;
  bool _isSubmitting = false;
  String? _submitError;

  bool get isSubmitting => _isSubmitting;
  String? get submitError => _submitError;

  GameState get state => _state;
  List<Question> get questions => _questions;
  int get currentIndex => _currentIndex;
  int get score => _score;
  int get correctCount => _correctCount;
  int get wrongCount => _wrongCount;
  int get timeLeft => _timeLeft;
  int get totalPointsEarned => _totalPointsEarned;
  int? get selectedAnswer => _selectedAnswer;
  int? get correctAnswer => _correctAnswer;
  Question get currentQuestion => _questions[_currentIndex];
  bool get isLastQuestion => _currentIndex == totalQuestions - 1;
  double get progress => (_currentIndex + 1) / totalQuestions;

  void startGame() {
    _questions = _generateQuestions();
    _currentIndex = 0;
    _score = 0;
    _correctCount = 0;
    _wrongCount = 0;
    _totalPointsEarned = 0;
    _selectedAnswer = null;
    _correctAnswer = null;
    _state = GameState.playing;
    _startTimer();
    notifyListeners();
  }

  void _startTimer() {
    _timeLeft = timePerQuestion;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _timeLeft--;
      if (_timeLeft <= 0) {
        _handleTimeout();
      }
      notifyListeners();
    });
  }

  void _handleTimeout() {
    _timer?.cancel();
    _wrongCount++;
    _state = GameState.answering;
    _correctAnswer = currentQuestion.correctIndex;
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (_state != GameState.finished) {
        _nextQuestion();
      }
    });
  }

  void answerQuestion(int index) {
    if (_state != GameState.playing) return;
    _timer?.cancel();
    _selectedAnswer = index;
    _correctAnswer = currentQuestion.correctIndex;
    _state = GameState.answering;

    if (index == currentQuestion.correctIndex) {
      _score += currentQuestion.points + _timeLeft;
      _totalPointsEarned += currentQuestion.points + _timeLeft;
      _correctCount++;
    } else {
      _wrongCount++;
    }
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (_state != GameState.finished) {
        _nextQuestion();
      }
    });
  }

  void _nextQuestion() {
    if (isLastQuestion) {
      _state = GameState.finished;
      _timer?.cancel();
      notifyListeners();
    } else {
      _currentIndex++;
      _selectedAnswer = null;
      _correctAnswer = null;
      _state = GameState.playing;
      _startTimer();
      notifyListeners();
    }
  }

  List<Question> _generateQuestions() {
    final random = Random();
    final questions = <Question>[];
    final operations = ['+', '-', '×', '÷'];

    for (int i = 0; i < totalQuestions; i++) {
      final op = operations[i % 4];
      int a, b, answer;
      String display;

      switch (op) {
        case '+':
          a = random.nextInt(50) + 1;
          b = random.nextInt(50) + 1;
          answer = a + b;
          display = '$a + $b';
          break;
        case '-':
          a = random.nextInt(50) + 10;
          b = random.nextInt(a.clamp(1, a)) + 1;
          answer = a - b;
          display = '$a − $b';
          break;
        case '×':
          a = random.nextInt(12) + 1;
          b = random.nextInt(12) + 1;
          answer = a * b;
          display = '$a × $b';
          break;
        case '÷':
          b = random.nextInt(10) + 1;
          answer = random.nextInt(12) + 1;
          a = b * answer;
          display = '$a ÷ $b';
          break;
        default:
          a = 0;
          b = 0;
          answer = 0;
          display = '';
      }

      final options = <int>{answer};
      while (options.length < 4) {
        final offset = random.nextInt(20) + 1;
        if (random.nextBool()) {
          options.add(answer + offset);
        } else {
          options.add((answer - offset).clamp(0, 999));
        }
      }
      final shuffled = options.toList()..shuffle();
      final correctIdx = shuffled.indexOf(answer);

      questions.add(Question(
        question: display,
        options: shuffled.map((e) => e.toString()).toList(),
        correctIndex: correctIdx,
        points: 10,
      ));
    }
    return questions;
  }

  Future<Map<String, dynamic>?> submitScore() async {
    if (_isSubmitting) return null;
    _isSubmitting = true;

    try {
      final api = ApiService();
      final response = await api.post('/api/game/submit', data: {
        'score': _score,
        'correct_count': _correctCount,
        'wrong_count': _wrongCount,
        'total_questions': totalQuestions,
      });
      return response.data['data'] as Map<String, dynamic>?;
    } catch (e) {
      _submitError = e.toString();
      return null;
    } finally {
      _isSubmitting = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
