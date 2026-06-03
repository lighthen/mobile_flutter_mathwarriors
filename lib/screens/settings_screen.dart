import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../config/api_config.dart';
import '../config/constant.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../services/api_service.dart';
import '../services/navigation_service.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;
  Map<String, dynamic>? _profileData;
  bool _isLoadingProfile = true;
  String? _avatarUrl;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
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
      final data = response.data['data'] as Map<String, dynamic>?;
      setState(() {
        _profileData = data;
        final avatar = data?['user']?['avatar'] as String?;
        _avatarUrl = ApiConfig.avatarUrl(avatar);
        _isLoadingProfile = false;
      });
    } catch (_) {
      setState(() => _isLoadingProfile = false);
    }
  }

  void _showChangePasswordSheet() {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;
    bool obscureOld = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          height: MediaQuery.of(ctx).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              24, 12, 24, MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Form(
              key: formKey,
              child: ListView(
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B00).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.lock_rounded, color: Color(0xFFFF6B00), size: 22),
                      ),
                      const SizedBox(width: 14),
                      const Text(
                        'Ganti Password',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  _buildSheetField(
                    controller: oldCtrl,
                    label: 'Password Lama',
                    icon: Icons.lock_outline,
                    obscure: obscureOld,
                    onToggle: () => setSheetState(() => obscureOld = !obscureOld),
                    validator: (v) => v?.isEmpty == true ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildSheetField(
                    controller: newCtrl,
                    label: 'Password Baru',
                    icon: Icons.lock_open,
                    obscure: obscureNew,
                    onToggle: () => setSheetState(() => obscureNew = !obscureNew),
                    validator: (v) => v != null && v.length < 6 ? 'Minimal 6 karakter' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildSheetField(
                    controller: confirmCtrl,
                    label: 'Konfirmasi Password Baru',
                    icon: Icons.check_circle_outline,
                    obscure: obscureConfirm,
                    onToggle: () => setSheetState(() => obscureConfirm = !obscureConfirm),
                    validator: (v) => v != newCtrl.text ? 'Password tidak cocok' : null,
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : () async {
                        if (!formKey.currentState!.validate()) return;
                        setSheetState(() => isLoading = true);
                        try {
                          final api = ApiService();
                          await api.post('/api/user/change-password', data: {
                            'old_password': oldCtrl.text,
                            'new_password': newCtrl.text,
                          });
                          NavigationService.showSuccess('Password berhasil diubah');
                          Navigator.pop(ctx);
                        } catch (e) {
                          NavigationService.showError(
                            e.toString().replaceFirst('Exception: ', ''),
                          );
                        } finally {
                          setSheetState(() => isLoading = false);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B00),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 22, height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                            )
                          : const Text('Simpan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showChangeUsernameSheet() {
    final ctrl = TextEditingController(text: _profileData?['user']?['username'] ?? '');
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          height: 280,
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B00).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.person_rounded, color: Color(0xFFFF6B00), size: 22),
                      ),
                      const SizedBox(width: 14),
                      const Text('Ganti Username',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: ctrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Username Baru',
                      prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF9E9E9E), size: 20),
                      filled: true, fillColor: const Color(0xFF252525),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFFF6B00), width: 1.5)),
                      labelStyle: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().length < 3) return 'Minimal 3 karakter';
                      if (v.trim().length > 20) return 'Maksimal 20 karakter';
                      if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v.trim())) return 'Hanya huruf, angka, dan underscore';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity, height: 52,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : () async {
                        if (!formKey.currentState!.validate()) return;
                        setSheetState(() => isLoading = true);
                        try {
                          final api = ApiService();
                          final res = await api.post('/api/user/change-username', data: {
                            'username': ctrl.text.trim(),
                          });
                          final newUsername = res.data['data']['username'] as String;
                          final auth = context.read<AuthProvider>();
                          if (auth.user != null) {
                            auth.updateUser(User(
                              id: auth.user!.id, username: newUsername,
                              tier: auth.user!.tier, points: auth.user!.points,
                            ));
                          }
                          setState(() {
                            final u = _profileData?['user'];
                            if (u != null) u['username'] = newUsername;
                          });
                          NavigationService.showSuccess('Username berhasil diubah');
                          Navigator.pop(ctx);
                        } catch (e) {
                          NavigationService.showError(e.toString().replaceFirst('Exception: ', ''));
                        } finally {
                          setSheetState(() => isLoading = false);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B00), foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
                      child: isLoading
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                          : const Text('Simpan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUploadAvatar() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              const Text('Ubah Foto Profil',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx, ImageSource.camera),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF252525),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.camera_alt_rounded, color: Color(0xFFFF6B00), size: 32),
                            SizedBox(height: 8),
                            Text('Kamera', style: TextStyle(color: Colors.white, fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF252525),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.photo_library_rounded, color: Color(0xFFFF6B00), size: 32),
                            SizedBox(height: 8),
                            Text('Galeri', style: TextStyle(color: Colors.white, fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    try {
      final XFile? picked = await _picker.pickImage(
        source: source, maxWidth: 512, maxHeight: 512, imageQuality: 80);
      if (picked == null) return;

      final api = ApiService();
      final response = await api.uploadFile('/api/user/upload-avatar', picked.path, 'avatar');
      final data = response.data['data'];
      if (data != null) {
        final avatarUrl = data['avatar_url'] as String?;
        setState(() => _avatarUrl = avatarUrl);
        NavigationService.showSuccess('Foto profil berhasil diubah');
        _fetchProfile();
      }
    } catch (e) {
      NavigationService.showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Widget _buildSheetField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool obscure,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF9E9E9E), size: 20),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility,
              color: const Color(0xFF9E9E9E), size: 20),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: const Color(0xFF252525),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFF6B00), width: 1.5),
        ),
        labelStyle: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: validator,
    );
  }

  Future<bool> _confirmDelete() async {
    final pwCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFFF6B00), size: 24),
            SizedBox(width: 10),
            Text('Hapus Akun', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Semua data akan hilang permanen.\nYakin ingin melanjutkan?',
              style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: pwCtrl,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Masukkan password',
                hintStyle: const TextStyle(color: Color(0xFF555555)),
                filled: true,
                fillColor: const Color(0xFF252525),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF9E9E9E))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade800.withValues(alpha: 0.8),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('Hapus', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (result == true && pwCtrl.text.isNotEmpty) {
      try {
        final api = ApiService();
        await api.post('/api/user/delete-account', data: {'password': pwCtrl.text});
        if (mounted) {
          context.read<AuthProvider>().logout();
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
          NavigationService.showSuccess('Akun berhasil dihapus');
        }
      } catch (e) {
        NavigationService.showError(e.toString().replaceFirst('Exception: ', ''));
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    if (user == null) return const SizedBox.shrink();

    final stats = _profileData?['stats'] as Map<String, dynamic>?;
    final totalGames = stats?['total_games'] as int? ?? 0;
    final totalScore = stats?['total_score'] as int? ?? 0;

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
              _buildHeader(context, user),
              Expanded(
                child: FadeTransition(
                  opacity: _fadeIn,
                  child: SlideTransition(
                    position: _slideUp,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      children: [
                        _buildStatsSection(totalGames, totalScore),
                        const SizedBox(height: 20),
                        _buildSettingsSection(context),
                        const SizedBox(height: 20),
                        _buildMenuSection(context, auth),
                      ],
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

  Widget _buildHeader(BuildContext context, User user) {
    final tierIcon = _getTierIcon(user.tier);
    final hasAvatar = _avatarUrl != null && _avatarUrl!.isNotEmpty;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 200,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFFF6B00).withValues(alpha: 0.25),
                const Color(0xFFFF8F00).withValues(alpha: 0.08),
                const Color(0xFF121212),
              ],
            ),
            borderRadius: BorderRadius.vertical(
              bottom: Radius.elliptical(MediaQuery.of(context).size.width, 80),
            ),
          ),
          child: Stack(
            children: [
              Positioned(top: -20, right: -20,
                child: Container(width: 160, height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      const Color(0xFFFF6B00).withValues(alpha: 0.08), Colors.transparent,
                    ]),
                  ),
                ),
              ),
              Positioned(bottom: 40, left: -30,
                child: Transform.rotate(angle: -0.3,
                  child: Container(width: 100, height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFFF6B00).withValues(alpha: 0.06), width: 2),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(left: 16, top: 8,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_rounded, color: Colors.white70, size: 22),
            ),
          ),
        ),
        Positioned(bottom: 0, left: 24, right: 24,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF1E1E1E), Color(0xFF252525)]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFF6B00).withValues(alpha: 0.12)),
              boxShadow: [
                BoxShadow(color: const Color(0xFFFF6B00).withValues(alpha: 0.08), blurRadius: 30, offset: const Offset(0, 8)),
              ],
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _pickAndUploadAvatar,
                  child: Stack(
                    children: [
                      Container(
                        width: 60, height: 60,
                        decoration: BoxDecoration(
                          gradient: hasAvatar ? null : LinearGradient(colors: [
                            const Color(0xFFFF6B00).withValues(alpha: 0.2),
                            const Color(0xFFFF8F00).withValues(alpha: 0.1),
                          ]),
                          borderRadius: BorderRadius.circular(18),
                          image: hasAvatar ? DecorationImage(
                            image: NetworkImage(_avatarUrl!), fit: BoxFit.cover,
                          ) : null,
                        ),
                        child: hasAvatar ? null : Center(child: Text(tierIcon, style: const TextStyle(fontSize: 28))),
                      ),
                      Positioned(bottom: -1, right: -1,
                        child: Container(
                          width: 24, height: 24,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B00),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF1E1E1E), width: 2),
                          ),
                          child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.username,
                        style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text('${user.tier} — ${user.points} Poin',
                        style: TextStyle(color: const Color(0xFFFF6B00).withValues(alpha: 0.8), fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _pickAndUploadAvatar,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B00).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.camera_alt_rounded, color: Color(0xFFFF6B00), size: 14),
                        const SizedBox(width: 4),
                        Text('Foto',
                          style: TextStyle(color: const Color(0xFFFF6B00).withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection(int totalGames, int totalScore) {
    final stats = [
      {'icon': Icons.sports_esports_rounded, 'label': 'Game', 'value': '$totalGames', 'color': const Color(0xFFFF6B00)},
      {'icon': Icons.stars_rounded, 'label': 'Total Poin', 'value': '$totalScore', 'color': const Color(0xFFFF8F00)},
      {'icon': Icons.emoji_events_rounded, 'label': 'Peringkat', 'value': '${_profileData?['user']?['tier'] ?? '-'}', 'color': const Color(0xFF4CAF50)},
      {'icon': Icons.calendar_today_rounded, 'label': 'Bergabung', 'value': _formatDate(_profileData?['user']?['created_at']), 'color': const Color(0xFF42A5F5)},
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_rounded, color: Colors.white70, size: 16),
              const SizedBox(width: 8),
              const Text(
                'Statistik',
                style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              if (_isLoadingProfile)
                SizedBox(
                  width: 14, height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.6,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: stats.length,
            itemBuilder: (_, i) => _buildStatCard(
              icon: stats[i]['icon'] as IconData,
              label: stats[i]['label'] as String,
              value: stats[i]['value'] as String,
              color: stats[i]['color'] as Color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    final items = [
      {
        'icon': Icons.volume_up_rounded,
        'label': 'Efek Suara',
        'value': settings.soundEnabled,
        'onToggle': () => settings.toggleSound(),
      },
      {
        'icon': Icons.vibration_rounded,
        'label': 'Getar',
        'value': settings.vibrationEnabled,
        'onToggle': () => settings.toggleVibration(),
      },
      {
        'icon': Icons.notifications_rounded,
        'label': 'Notifikasi',
        'value': settings.notificationsEnabled,
        'onToggle': () => settings.toggleNotifications(),
      },
    ];

    return Column(
      children: [
        Row(
          children: [
            const Icon(Icons.settings_rounded, color: Colors.white70, size: 16),
            const SizedBox(width: 8),
            const Text(
              'Pengaturan Game',
              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...items.map((item) => _buildSettingsToggle(item)),
      ],
    );
  }

  Widget _buildSettingsToggle(Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
        ),
        child: SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B00).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item['icon'] as IconData, color: const Color(0xFFFF6B00), size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                item['label'] as String,
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
            ],
          ),
          value: item['value'] as bool,
          onChanged: (_) => (item['onToggle'] as VoidCallback)(),
          activeThumbColor: const Color(0xFFFF6B00),
          inactiveThumbColor: Colors.grey.shade700,
          inactiveTrackColor: Colors.grey.shade900,
        ),
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context, AuthProvider auth) {
    final menuItems = [
      {
        'icon': Icons.person_rounded,
        'label': 'Ganti Username',
        'subtitle': _profileData?['user']?['username'] ?? '-',
        'color': const Color(0xFFFF6B00),
        'onTap': _showChangeUsernameSheet,
      },
      {
        'icon': Icons.lock_rounded,
        'label': 'Ganti Password',
        'subtitle': 'Perbarui password akun',
        'color': const Color(0xFFFF6B00),
        'onTap': _showChangePasswordSheet,
      },
      {
        'icon': Icons.info_outline_rounded,
        'label': 'Tentang Aplikasi',
        'subtitle': 'MathWarriors v1.0.0',
        'color': const Color(0xFF42A5F5),
        'onTap': () => _showAbout(),
      },
      {
        'icon': Icons.logout_rounded,
        'label': 'Keluar',
        'subtitle': 'Logout dari akun',
        'color': Colors.white54,
        'onTap': () async {
          await auth.logout();
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          }
        },
      },
      {
        'icon': Icons.delete_forever_rounded,
        'label': 'Hapus Akun',
        'subtitle': 'Semua data akan hilang',
        'color': Colors.red.shade400,
        'onTap': _confirmDelete,
      },
    ];

    return Column(
      children: [
        Row(
          children: [
            const Icon(Icons.tune_rounded, color: Colors.white70, size: 16),
            const SizedBox(width: 8),
            const Text(
              'Pengaturan',
              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...menuItems.map((item) => _buildMenuItem(item)),
      ],
    );
  }

  Widget _buildMenuItem(Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: item['onTap'] as VoidCallback,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.03),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: (item['color'] as Color).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    item['icon'] as IconData,
                    color: item['color'] as Color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['label'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        item['subtitle'] as String,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.35),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withValues(alpha: 0.2),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/images/logo.jpeg',
                width: 72, height: 72,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'MathWarriors',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'v1.0.0',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13),
            ),
            const SizedBox(height: 12),
            Text(
              'Asah kemampuan matematikamu\ndan naikkan peringkatmu!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF252525),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _aboutStat('🏆', '6', 'Tier'),
                  Container(width: 1, height: 30, color: const Color(0xFF333333)),
                  _aboutStat('📝', '10', 'Soal/Game'),
                  Container(width: 1, height: 30, color: const Color(0xFF333333)),
                  _aboutStat('⏱️', '15s', 'Per Soal'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Tutup', style: TextStyle(color: Color(0xFFFF6B00))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _aboutStat(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11)),
      ],
    );
  }

  String _getTierIcon(String tierName) {
    for (final tier in AppConstants.rankTiers) {
      if (tier['name'] == tierName) return tier['icon'] as String;
    }
    return '🌱';
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final dt = DateTime.parse(dateStr);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return '-';
    }
  }
}
