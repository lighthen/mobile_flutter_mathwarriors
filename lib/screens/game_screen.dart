import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart' as game;
import 'game_result_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  bool _isFinishing = false;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _onAnswer(int index) {
    final gameProv = context.read<game.GameProvider>();
    if (gameProv.state == game.GameState.playing) {
      gameProv.answerQuestion(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text('Keluar Permainan?',
                  style: TextStyle(color: Colors.white)),
              content: const Text('Progress game akan hilang.',
                  style: TextStyle(color: Color(0xFF9E9E9E))),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Lanjutkan',
                      style: TextStyle(color: Color(0xFFFF8F00))),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade800,
                  ),
                  child: const Text('Keluar'),
                ),
              ],
            ),
          );
          if (confirm == true && context.mounted) {
            context.read<game.GameProvider>().dispose();
            Navigator.pop(context);
          }
        }
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF0D0D0D),
                Color(0xFF121212),
                Color(0xFF1A1A1A),
              ],
            ),
          ),
          child: SafeArea(
            child: Consumer<game.GameProvider>(
              builder: (context, gameProv, _) {
                if (gameProv.state == game.GameState.finished) {
                  if (!_isFinishing) {
                    _isFinishing = true;
                    _finishGame(gameProv);
                  }
                  return _buildLoadingState();
                }
                return _buildGameContent(context, gameProv);
              },
            ),
          ),
        ),
      ),
    );
  }

  void _finishGame(game.GameProvider gameProv) {
    gameProv.submitScore().then((result) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => GameResultScreen(
              score: gameProv.score,
              correctCount: gameProv.correctCount,
              wrongCount: gameProv.wrongCount,
              totalQuestions: game.GameProvider.totalQuestions,
              submissionResult: result,
            ),
          ),
        );
      }
    });
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFFFF6B00)),
          SizedBox(height: 16),
          Text(
            'Menyimpan skor...',
            style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildGameContent(BuildContext context, game.GameProvider gameProv) {
    final orange = const Color(0xFFFF6B00);
    final lightOrange = const Color(0xFFFF8F00);

    return Column(
      children: [
        _buildTopBar(gameProv, orange, lightOrange),
        Expanded(
          child: gameProv.state == game.GameState.idle
              ? _buildIdleState(orange)
              : _buildQuestionArea(context, gameProv, orange, lightOrange),
        ),
      ],
    );
  }

  Widget _buildTopBar(game.GameProvider gameProv, Color orange, Color lightOrange) {
    final progressValue = gameProv.progress;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withValues(alpha: 0.6),
            Colors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.maybePop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.close, color: Colors.white70, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Soal ${gameProv.currentIndex + 1} dari ${game.GameProvider.totalQuestions}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 300),
                        tween: Tween(begin: 0, end: progressValue),
                        builder: (context, value, _) => LinearProgressIndicator(
                          value: value,
                          minHeight: 4,
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            value < 0.5 ? orange : value < 0.8 ? lightOrange : Colors.green.shade400,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              _buildScoreBadge(gameProv.score, orange),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildScoreBadge(int score, Color orange) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [orange.withValues(alpha: 0.2), orange.withValues(alpha: 0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.stars_rounded, color: Color(0xFFFF8F00), size: 16),
          const SizedBox(width: 4),
          TweenAnimationBuilder<int>(
            duration: const Duration(milliseconds: 300),
            tween: IntTween(begin: 0, end: score),
            builder: (context, value, _) => Text(
              '$value',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdleState(Color orange) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.sports_esports, size: 80, color: Color(0xFFFF6B00)),
          const SizedBox(height: 16),
          const Text(
            'Siap bermain?',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.read<game.GameProvider>().startGame(),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Mulai'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionArea(
      BuildContext context, game.GameProvider gameProv, Color orange, Color lightOrange) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 8),
                _buildTimerCircle(gameProv, orange),
                const SizedBox(height: 24),
                _buildQuestionCard(context, gameProv, orange),
                const SizedBox(height: 24),
                _buildAnswerGrid(context, gameProv, orange, lightOrange),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimerCircle(game.GameProvider gameProv, Color orange) {
    final timeFraction = gameProv.timeLeft / game.GameProvider.timePerQuestion;
    final timerColor = timeFraction > 0.5
        ? orange
        : timeFraction > 0.25
            ? const Color(0xFFFF8F00)
            : const Color(0xFFF44336);

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween(begin: 1.0, end: timeFraction),
      builder: (context, value, _) {
        return Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF1E1E1E),
            boxShadow: [
              BoxShadow(
                color: timerColor.withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: CustomPaint(
            painter: _TimerPainter(
              progress: value,
              color: timerColor,
              backgroundColor: const Color(0xFF333333),
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  '${gameProv.timeLeft}',
                  key: ValueKey(gameProv.timeLeft),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: timerColor,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuestionCard(BuildContext context, game.GameProvider gameProv, Color orange) {
    final isAnswering = gameProv.state == game.GameState.answering;

    return AnimatedSlide(
      duration: const Duration(milliseconds: 400),
      offset: _slideAnimation.value,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: isAnswering ? 0.85 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                orange.withValues(alpha: 0.12),
                orange.withValues(alpha: 0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: orange.withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: orange.withValues(alpha: 0.08),
                blurRadius: 30,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'Berapa hasil dari?',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) => SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.2, 0.0),
                    end: Offset.zero,
                  ).animate(anim),
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: Text(
                  key: ValueKey(gameProv.currentQuestion.question),
                  gameProv.currentQuestion.question,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnswerGrid(
      BuildContext context, game.GameProvider gameProv, Color orange, Color lightOrange) {
    final options = gameProv.currentQuestion.options;
    final isAnswering = gameProv.state == game.GameState.answering;

    return Column(
      children: [
        for (int row = 0; row < 2; row++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                for (int col = 0; col < 2; col++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: col == 0 ? 0 : 6,
                        right: col == 1 ? 0 : 6,
                      ),
                      child: _buildAnswerButton(
                        index: row * 2 + col,
                        text: options[row * 2 + col],
                        isAnswering: isAnswering,
                        gameProv: gameProv,
                        orange: orange,
                        lightOrange: lightOrange,
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAnswerButton({
    required int index,
    required String text,
    required bool isAnswering,
    required game.GameProvider gameProv,
    required Color orange,
    required Color lightOrange,
  }) {
    final isSelected = gameProv.selectedAnswer == index;
    final isCorrect = gameProv.correctAnswer == index;
    final isWrong = isSelected && !isCorrect;
    final isTimeout = gameProv.selectedAnswer == null && gameProv.state == game.GameState.answering;

    Color? bgColor;
    Color? borderColor;
    Color? textColor;
    IconData? icon;
    Color? iconColor;

    if (!isAnswering) {
      bgColor = const Color(0xFF1E1E1E);
      borderColor = Colors.white.withValues(alpha: 0.08);
      textColor = Colors.white;
    } else if (isCorrect) {
      bgColor = const Color(0xFF1B5E20);
      borderColor = const Color(0xFF4CAF50);
      textColor = Colors.white;
      icon = Icons.check_circle_rounded;
      iconColor = const Color(0xFF4CAF50);
    } else if (isWrong || isTimeout) {
      bgColor = const Color(0xFFB71C1C);
      borderColor = const Color(0xFFF44336);
      textColor = Colors.white70;
      if (isWrong) {
        icon = Icons.cancel_rounded;
        iconColor = const Color(0xFFF44336);
      }
    } else {
      bgColor = const Color(0xFF1E1E1E).withValues(alpha: 0.5);
      borderColor = Colors.white.withValues(alpha: 0.05);
      textColor = Colors.white38;
    }

    return GestureDetector(
      onTap: isAnswering ? null : () => _onAnswer(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: isSelected || isCorrect ? 2 : 1.5),
          boxShadow: isSelected || isCorrect
              ? [
                  BoxShadow(
                    color: (isCorrect ? const Color(0xFF4CAF50) : orange).withValues(alpha: 0.15),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ]
              : [],
        ),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            color: textColor,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: iconColor, size: 22),
                const SizedBox(width: 8),
              ],
              Text(text),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimerPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  _TimerPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 6;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _TimerPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
