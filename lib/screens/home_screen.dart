import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/api_config.dart';
import '../config/constant.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';
import 'game_screen.dart';
import 'leaderboard_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;
  Map<String, dynamic>? _profileData;
  bool _isLoadingProfile = true;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
    _fetchProfile();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    try {
      final api = ApiService();
      final response = await api.get('/api/user/profile');
      if (mounted) {
        final data = response.data['data'] as Map<String, dynamic>?;
        setState(() {
          _profileData = data;
          final avatar = data?['user']?['avatar'] as String?;
          _avatarUrl = ApiConfig.avatarUrl(avatar);
          _isLoadingProfile = false;
        });
        final username = data?['user']?['username'] as String?;
        final points = data?['user']?['points'] as int?;
        if (username != null) {
          WebSocketService.instance.sendRegister(username, points ?? 0);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  String _getTierIcon(String tierName) {
    for (final tier in AppConstants.rankTiers) {
      if (tier['name'] == tierName) return tier['icon'] as String;
    }
    return '🌱';
  }

  String _getNextTier(String currentTier) {
    final tiers = AppConstants.rankTiers;
    for (int i = 0; i < tiers.length - 1; i++) {
      if (tiers[i]['name'] == currentTier) return tiers[i + 1]['name'] as String;
    }
    return currentTier;
  }

  int _getNextTierPoints(String currentTier) {
    final tiers = AppConstants.rankTiers;
    for (int i = 0; i < tiers.length - 1; i++) {
      if (tiers[i]['name'] == currentTier) return tiers[i + 1]['minPoints'] as int;
    }
    return 1500;
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
      final day = dt.day;
      final hour = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '$day ${months[dt.month - 1]}, $hour:$min';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final tierIcon = _getTierIcon(user.tier);
    final nextTier = _getNextTier(user.tier);
    final nextPoints = _getNextTierPoints(user.tier);
    final progress = user.tier == 'Legend'
        ? 1.0
        : (user.points / nextPoints).clamp(0.0, 1.0);
    final stats = _profileData?['stats'] as Map<String, dynamic>?;
    final totalGames = stats?['total_games'] as int? ?? 0;
    final totalScore = stats?['total_score'] as int? ?? 0;
    final recentGames = _profileData?['recent_games'] as List<dynamic>? ?? [];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D0D0D), Color(0xFF121212)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(user, tierIcon, progress, nextTier, nextPoints),
              Expanded(
                child: FadeTransition(
                  opacity: _fadeIn,
                  child: SlideTransition(
                    position: _slideUp,
                    child: RefreshIndicator(
                      onRefresh: _fetchProfile,
                      color: const Color(0xFFFF6B00),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        children: [
                          _buildActionButtons(context),
                          const SizedBox(height: 20),
                          _buildStatsRow(totalGames, totalScore),
                          const SizedBox(height: 20),
                          _buildRecentGames(context, recentGames),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(User user, String tierIcon, double progress, String nextTier, int nextPoints) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 220,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFFF6B00).withValues(alpha: 0.2),
                const Color(0xFFFF8F00).withValues(alpha: 0.06),
                const Color(0xFF121212),
              ],
            ),
            borderRadius: BorderRadius.vertical(
              bottom: Radius.elliptical(MediaQuery.of(context).size.width, 90),
            ),
          ),
          child: Stack(
            children: [
              Positioned(top: -30, right: -30,
                child: Container(
                  width: 180, height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      const Color(0xFFFF6B00).withValues(alpha: 0.06),
                      Colors.transparent,
                    ]),
                  ),
                ),
              ),
              Positioned(top: 60, left: -40,
                child: Transform.rotate(angle: -0.4,
                  child: Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFFF6B00).withValues(alpha: 0.05), width: 2),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 8, left: 16,
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderboardScreen()));
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.leaderboard_rounded, color: Colors.white70, size: 22),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.settings_rounded, color: Colors.white70, size: 22),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 0, left: 20, right: 20,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E1E1E), Color(0xFF252525)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFF6B00).withValues(alpha: 0.1)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6B00).withValues(alpha: 0.08),
                  blurRadius: 30, offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    gradient: _avatarUrl != null && _avatarUrl!.isNotEmpty
                        ? null
                        : LinearGradient(colors: [
                            const Color(0xFFFF6B00).withValues(alpha: 0.2),
                            const Color(0xFFFF8F00).withValues(alpha: 0.1),
                          ]),
                    borderRadius: BorderRadius.circular(16),
                    image: _avatarUrl != null && _avatarUrl!.isNotEmpty
                        ? DecorationImage(image: NetworkImage(_avatarUrl!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: _avatarUrl != null && _avatarUrl!.isNotEmpty
                      ? null
                      : Center(child: Text(tierIcon, style: const TextStyle(fontSize: 28))),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.username,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6B00).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(user.tier,
                              style: TextStyle(color: const Color(0xFFFF6B00).withValues(alpha: 0.9), fontSize: 11, fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(width: 8),
                          Text('${user.points} Poin',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
                        ],
                      ),
                      if (user.tier != 'Legend') ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 800),
                            tween: Tween(begin: 0, end: progress),
                            builder: (_, v, __) => LinearProgressIndicator(
                              value: v, minHeight: 5,
                              backgroundColor: const Color(0xFF333333),
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF6B00)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text('$nextTier ($nextPoints poin)',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 11)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GameScreen())),
              child: Container(
                height: 72,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFFFF6B00), const Color(0xFFFF8F00)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6B00).withValues(alpha: 0.3),
                      blurRadius: 20, offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32),
                    SizedBox(width: 8),
                    Text('Mulai Bermain',
                      style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderboardScreen())),
            child: Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.emoji_events_rounded, color: const Color(0xFFFF8F00), size: 22),
                  const SizedBox(height: 2),
                  Text('Rank',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(int totalGames, int totalScore) {
    return Row(
      children: [
        Expanded(child: _buildStatCard(
          icon: Icons.sports_esports_rounded, label: 'Game Dimainkan', value: '$totalGames',
          color: const Color(0xFFFF6B00),),
        ),
        const SizedBox(width: 10),
        Expanded(child: _buildStatCard(
          icon: Icons.stars_rounded, label: 'Total Poin', value: '$totalScore',
          color: const Color(0xFFFF8F00),),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon, required String label, required String value, required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                  style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
                Text(label,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentGames(BuildContext context, List<dynamic> games) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF42A5F5).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.history_rounded, color: Color(0xFF42A5F5), size: 16),
            ),
            const SizedBox(width: 8),
            const Text('Riwayat Game',
              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
            const Spacer(),
            if (_isLoadingProfile)
              SizedBox(width: 14, height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white.withValues(alpha: 0.3))),
          ],
        ),
        const SizedBox(height: 12),
        if (games.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
            ),
            child: Column(
              children: [
                Icon(Icons.sports_esports_outlined, size: 36, color: Colors.grey.shade700),
                const SizedBox(height: 8),
                Text('Belum ada riwayat game',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              ],
            ),
          )
        else
          ...games.map((g) => _buildGameItem(g as Map<String, dynamic>)),
      ],
    );
  }

  Widget _buildGameItem(Map<String, dynamic> game) {
    final score = game['score'] as int;
    final correct = game['correct_count'] as int;
    final wrong = game['wrong_count'] as int;
    final total = game['total_questions'] as int;
    final accuracy = total > 0 ? (correct / total * 100).round() : 0;
    final date = _formatDate(game['created_at'] as String?);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: score > 0
                      ? [const Color(0xFFFF6B00).withValues(alpha: 0.2), const Color(0xFFFF8F00).withValues(alpha: 0.1)]
                      : [Colors.red.withValues(alpha: 0.15), Colors.red.withValues(alpha: 0.05)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Icon(
                  score > 0 ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: score > 0 ? const Color(0xFFFF6B00) : Colors.red.shade400,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('$score Poin',
                        style: TextStyle(
                          color: score > 0 ? const Color(0xFFFF6B00) : Colors.red.shade400,
                          fontSize: 15, fontWeight: FontWeight.bold,
                        )),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: accuracy >= 70
                              ? const Color(0xFF4CAF50).withValues(alpha: 0.15)
                              : Colors.red.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('$accuracy%',
                          style: TextStyle(
                            color: accuracy >= 70 ? const Color(0xFF4CAF50) : Colors.red.shade400,
                            fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('$correct benar · $wrong salah — $total soal',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 12)),
                ],
              ),
            ),
            Text(date,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
