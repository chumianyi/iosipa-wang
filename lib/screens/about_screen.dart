import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('关于'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(
                      child: Text('88',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('iosipa.wang',
                      style: TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  const Text('版本 2.0.0',
                      style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildSectionTitle('使用的API接口'),
            const SizedBox(height: 8),
            _buildApiCard('登录', 'POST /user/api/login',
                '参数: userMail, userPass · 登录获取会话Cookie'),
            _buildApiCard('每日签到', 'POST /user/api/sign_in',
                '无表单参数，依赖Cookie会话'),
            _buildApiCard('首页推荐', 'GET /', 'HTML页面解析应用列表'),
            _buildApiCard('游戏分类', 'GET /game.html', 'HTML页面解析游戏列表'),
            _buildApiCard('软件分类', 'GET /soft.html', 'HTML页面解析软件列表'),
            _buildApiCard('搜索', 'GET /search.html?keyword=xxx',
                'HTML页面解析搜索结果'),
            _buildApiCard('应用详情', 'GET /application/{id}.html',
                'HTML页面解析图标/截图/描述'),
            _buildApiCard('下载IPA', 'POST /user/api/down_the_file',
                '参数: appId · 返回ipa_download_link'),
            _buildApiCard('在线安装', 'POST /user/api/install_the_ipa',
                '参数: appId · 返回plist_link (itms-services协议)'),
            const SizedBox(height: 24),
            _buildSectionTitle('免责声明'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '1. 本应用 iosipa.wang 仅为 88ipa.com 的第三方非官方客户端，与88ipa.com官方无任何隶属关系。\n\n'
                '2. 所有应用资源、内容、版权均归 88ipa.com 及其原作者所有。\n\n'
                '3. 本应用仅提供登录、签到、浏览、下载等便捷功能，不对应用内容的合法性、安全性、可用性承担任何责任。\n\n'
                '4. P12证书签名功能仅供学习研究使用，请勿用于未经授权的应用签名分发。\n\n'
                '5. 在线安装功能依赖苹果 itms-services 协议，仅可在iOS设备上使用。安卓设备无法安装IPA。\n\n'
                '6. 使用本应用产生的任何后果（包括但不限于账号封禁、积分损失、设备问题）由使用者自行承担。\n\n'
                '7. 如本应用侵犯了您的权益，请联系开发者下架。',
                style: TextStyle(fontSize: 13, height: 1.6),
              ),
            ),
            const SizedBox(height: 32),
            const Center(
              child: Text('Copyright © 2024 iosipa.wang',
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold));
  }

  Widget _buildApiCard(String name, String endpoint, String desc) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF667EEA).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(name,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF667EEA))),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(endpoint,
                      style: const TextStyle(
                          fontFamily: 'monospace', fontSize: 12),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(desc,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
