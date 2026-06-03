import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/settings_provider.dart';
import '../services/websocket_service.dart';
import 'game_screen.dart';

class GameResultScreen extends StatefulWidget {
  final int score;
  final int correctCount;
  final int wrongCount;
  final int totalQuestions;
  final Map<String, dynamic>? submissionResult;

  const GameResultScreen({
    super.key,
    required this.score,
    required this.correctCount,
    required this.wrongCount,
    required this.totalQuestions,
    this.submissionResult,
  });

  @override
  State<GameResultScreen> createState() => _GameResultScreenState();
}

class _GameResultScreenState extends State<GameResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _scoreAnim;

  @override
  void initState() {
    super.initState();
    _updateAuthUser();
    _sendNotification();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _scaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: const Interval(0.0, 0.5, curve: Curves.elasticOut)),
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: const Interval(0.3, 1.0, curve: Curves.easeIn)),
    );

    _scoreAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: const Interval(0.5, 1.0, curve: Curves.easeOutBack)),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _sendNotification() {
    final settings = context.read<SettingsProvider>();
    if (!settings.notificationsEnabled) return;

    final notificationProvider = context.read<NotificationProvider>();

    if (widget.submissionResult != null && widget.submissionResult!['user'] != null) {
      final userData = widget.submissionResult!['user'] as Map<String, dynamic>;
      final username = userData['username'] as String;
      final totalPoints = widget.submissionResult!['total_points'] as int? ?? widget.score;

      WebSocketService.instance.sendRegister(username, totalPoints);

      WebSocketService.instance.sendScoreUpdate(username, totalPoints);
    }

    notificationProvider.showGameCompleteNotification(
      score: widget.score,
      correctCount: widget.correctCount,
      totalQuestions: widget.totalQuestions,
    );
  }

  void _updateAuthUser() {
    final result = widget.submissionResult;
    if (result != null && result['user'] != null) {
      final auth = context.read<AuthProvider>();
      final userData = result['user'] as Map<String, dynamic>;
      auth.updateUser(User(
        id: userData['id'] as int,
        username: userData['username'] as String,
        tier: userData['tier'] as String,
        points: userData['points'] as int,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final accuracy = widget.totalQuestions > 0
        ? (widget.correctCount / widget.totalQuestions * 100).round()
        : 0;
    final grade = _getGrade(accuracy);
    final isPerfect = widget.correctCount == widget.totalQuestions;
    final isGood = accuracy >= 70;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.2,
              colors: [
                isPerfect
                    ? const Color(0xFFFF6B00).withValues(alpha: 0.3)
                    : isGood
                        ? const Color(0xFFFF6B00).withValues(alpha: 0.15)
                        : Colors.red.withValues(alpha: 0.1),
                const Color(0xFF121212),
                const Color(0xFF0D0D0D),
              ],
            ),
          ),
          child: SafeArea(
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const Spacer(flex: 1),
                      Transform.scale(
                        scale: _scaleAnim.value,
                        child: _buildHeader(grade, isPerfect),
                      ),
                      const SizedBox(height: 32),
                      FadeTransition(
                        opacity: _fadeAnim,
                        child: _buildScoreCircle(context, grade, accuracy, isPerfect),
                      ),
                      const SizedBox(height: 32),
                      FadeTransition(
                        opacity: _fadeAnim,
                        child: _buildStats(context),
                      ),
                      const Spacer(flex: 1),
                      FadeTransition(
                        opacity: _fadeAnim,
                        child: _buildActions(context, isPerfect),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  String _getGrade(int accuracy) {
    if (accuracy == 100) return 'Sempurna!';
    if (accuracy >= 80) return 'Luar Biasa!';
    if (accuracy >= 60) return 'Bagus!';
    if (accuracy >= 40) return 'Cukup';
    return 'Ayo Coba Lagi!';
  }

  Widget _buildHeader(String grade, bool isPerfect) {
    return Column(
      children: [
        Text(
          isPerfect ? '🎉' : '🏆',
          style: const TextStyle(fontSize: 48),
        ),
        const SizedBox(height: 8),
        Text(
          'Permainan Selesai!',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withValues(alpha: 0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          grade,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: isPerfect
                ? const Color(0xFFFF6B00)
                : Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildScoreCircle(BuildContext context, String grade, int accuracy, bool isPerfect) {
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: 3 * math.pi / 2,
          colors: [
            const Color(0xFFFF6B00).withValues(alpha: 0.2),
            const Color(0xFFFF8F00).withValues(alpha: 0.3),
            const Color(0xFFFF6B00).withValues(alpha: 0.2),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B00).withValues(alpha: isPerfect ? 0.3 : 0.1),
            blurRadius: 40,
            spreadRadius: 8,
          ),
        ],
      ),
      child: CustomPaint(
        painter: _ScoreCirclePainter(
          progress: _scoreAnim.value,
          accuracy: accuracy / 100.0,
          color: accuracy >= 70 ? const Color(0xFFFF6B00) : const Color(0xFFF44336),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${widget.score}',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Poin',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStats(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            icon: Icons.check_circle_rounded,
            label: 'Benar',
            value: '${widget.correctCount}',
            color: const Color(0xFF4CAF50),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withValues(alpha: 0.1),
          ),
          _buildStatItem(
            icon: Icons.cancel_rounded,
            label: 'Salah',
            value: '${widget.wrongCount}',
            color: const Color(0xFFF44336),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withValues(alpha: 0.1),
          ),
          _buildStatItem(
            icon: Icons.flag_rounded,
            label: 'Total',
            value: '${widget.totalQuestions}',
            color: const Color(0xFFFF8F00),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context, bool isPerfect) {
    return Column(
      children: [
        if (widget.submissionResult == null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Menyimpan skor...',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const GameScreen()),
              );
            },
            icon: const Icon(Icons.replay_rounded),
            label: Text(isPerfect ? 'Main Lagi' : 'Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B00),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.home_rounded),
            label: const Text('Kembali ke Beranda'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white70,
              side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: const TextStyle(fontSize: 15),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScoreCirclePainter extends CustomPainter {
  final double progress;
  final double accuracy;
  final Color color;

  _ScoreCirclePainter({
    required this.progress,
    required this.accuracy,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 12;

    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;

    canvas.drawCircle(center, radius, bgPaint);

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * accuracy * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScoreCirclePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.accuracy != accuracy;
}
