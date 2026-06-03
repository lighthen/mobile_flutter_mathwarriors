import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/api_config.dart';
import '../config/constant.dart';
import '../providers/notification_provider.dart';
import '../services/api_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>>? _entries;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _api.get('/api/leaderboard');
      final data = response.data['data'];
      setState(() {
        _entries = (data['leaderboard'] as List)
            .cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _getTierIcon(String tierName) {
    for (final tier in AppConstants.rankTiers) {
      if (tier['name'] == tierName) return tier['icon'] as String;
    }
    return '🌱';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Peringkat'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 48, color: Colors.grey.shade600),
            const SizedBox(height: 12),
            Text(
              'Gagal memuat peringkat',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchLeaderboard,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (_entries == null || _entries!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_outlined, size: 48, color: Colors.grey.shade600),
            const SizedBox(height: 12),
            Text(
              'Belum ada data peringkat',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    final topThree = _entries!.take(3).toList();
    final rest = _entries!.skip(3).toList();

    return RefreshIndicator(
      onRefresh: _fetchLeaderboard,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildBeatenBanner(),
          if (topThree.isNotEmpty) ...[
            _buildPodium(topThree),
            const SizedBox(height: 24),
          ],
          if (topThree.isNotEmpty)
            _buildTopCard(topThree[0], 1, true),
          if (topThree.length >= 2) ...[
            const SizedBox(height: 8),
            _buildTopCard(topThree[1], 2, false),
          ],
          if (topThree.length >= 3) ...[
            const SizedBox(height: 8),
            _buildTopCard(topThree[2], 3, false),
          ],
          if (rest.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(color: Color(0xFF333333)),
            ),
            ...rest.map((e) => _buildListCard(e)),
          ],
        ],
      ),
    );
  }

  Widget _buildBeatenBanner() {
    return Consumer<NotificationProvider>(
      builder: (context, notif, _) {
        final beatenBy = notif.lastBeatenBy;
        if (beatenBy == null) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF3D00), Color(0xFFFF6B00)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF3D00).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Skor Terlewati!',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$beatenBy melewati skor kamu. Ayo main lagi!',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => notif.clearBeatenIndicator(),
                  child: Icon(
                    Icons.close,
                    color: Colors.white.withValues(alpha: 0.7),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPodium(List<Map<String, dynamic>> topThree) {
    return Column(
      children: [
        Text(
          '🏆',
          style: TextStyle(fontSize: 40, color: const Color(0xFFFF6B00)),
        ),
        const SizedBox(height: 4),
        Text(
          'TOP ${topThree.length}',
          style: const TextStyle(
            color: Color(0xFFFF6B00),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildTopCard(Map<String, dynamic> entry, int rank, bool isFirst) {
    final tierIcon = _getTierIcon(entry['tier'] as String);
    final avatarUrl = ApiConfig.avatarUrl(entry['avatar'] as String?);
    final hasAvatar = avatarUrl.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isFirst
            ? LinearGradient(
                colors: [
                  const Color(0xFFFF6B00).withValues(alpha: 0.15),
                  const Color(0xFFFF8F00).withValues(alpha: 0.05),
                ],
              )
            : null,
        color: isFirst ? null : const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFirst
              ? const Color(0xFFFF6B00).withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '#$rank',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isFirst ? const Color(0xFFFF6B00) : Colors.white70,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: hasAvatar ? null : const Color(0xFF333333),
              borderRadius: BorderRadius.circular(12),
              image: hasAvatar ? DecorationImage(
                image: NetworkImage(avatarUrl), fit: BoxFit.cover,
              ) : null,
            ),
            child: hasAvatar ? null : Center(
              child: Text(tierIcon, style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry['username'] as String,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                Text(
                  entry['tier'] as String,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${entry['points']}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isFirst ? const Color(0xFFFF6B00) : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListCard(Map<String, dynamic> entry) {
    final rank = entry['rank'] as int;
    final tierIcon = _getTierIcon(entry['tier'] as String);
    final avatarUrl = ApiConfig.avatarUrl(entry['avatar'] as String?);
    final hasAvatar = avatarUrl.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: Text(
                '#$rank',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: hasAvatar ? null : const Color(0xFF333333),
                borderRadius: BorderRadius.circular(8),
                image: hasAvatar ? DecorationImage(
                  image: NetworkImage(avatarUrl), fit: BoxFit.cover,
                ) : null,
              ),
              child: hasAvatar ? null : Center(
                child: Text(tierIcon, style: const TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                entry['username'] as String,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
            Text(
              '${entry['points']}',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
