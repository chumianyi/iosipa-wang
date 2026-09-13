import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/app_models.dart';
import 'login_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  UserInfo? _userInfo;
  bool _loading = true;
  bool _signingIn = false;
  String? _signResult;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final info = await ApiService().fetchUserInfo();
    if (!mounted) return;
    setState(() {
      _userInfo = info;
      _loading = false;
    });
  }

  Future<void> _doSignIn() async {
    setState(() {
      _signingIn = true;
      _signResult = null;
    });
    final result = await ApiService().signIn();
    if (!mounted) return;
    setState(() {
      _signingIn = false;
      if (result['success'] == true) {
        _signResult = '✅ ${result['message']}';
        _loadUserInfo();
      } else if (result['message'] == '__NOT_LOGGED_IN__') {
        _forceLogout();
      } else {
        _signResult = 'ℹ️ ${result['message']}';
      }
    });
  }

  void _forceLogout() {
    ApiService().logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Future<void> _showLogoutConfirm() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出当前账号吗？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('退出', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) _forceLogout();
  }

  @override
  Widget build(BuildContext context) {
    final email = _userInfo?.email ?? ApiService().savedEmail;
    final points = _userInfo?.points ?? 0;

    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '我的',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  email.isEmpty ? '已登录' : email,
                  style:
                      TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        // 积分卡片
                        Card(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStat('剩余积分', points.toString(),
                                    Icons.stars),
                                Container(
                                  width: 1, height: 40, color: Colors.grey[300],
                                ),
                                _buildStat('账号', email.split('@').first,
                                    Icons.account_circle),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        // 签到大按钮
                        Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF667EEA).withOpacity(0.3),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(90),
                              onTap: _signingIn ? null : _doSignIn,
                              child: Center(
                                child: _signingIn
                                    ? const CircularProgressIndicator(
                                        color: Colors.white)
                                    : const Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.fingerprint,
                                              color: Colors.white, size: 40),
                                          SizedBox(height: 8),
                                          Text(
                                            '一键签到',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),
                        if (_signResult != null)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(_signResult!,
                                style: const TextStyle(fontSize: 15)),
                          ),
                        const SizedBox(height: 40),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton(
                              onPressed: _showLogoutConfirm,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('退出登录'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF667EEA), size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
