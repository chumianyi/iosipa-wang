import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/app_models.dart';
import '../services/api_service.dart';

class DetailScreen extends StatefulWidget {
  final String appId;
  final String appName;
  const DetailScreen({super.key, required this.appId, required this.appName});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  AppDetail? _detail;
  bool _loading = true;
  bool _downloading = false;
  bool _installing = false;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    final detail = await ApiService().fetchAppDetail(widget.appId);
    if (!mounted) return;
    setState(() {
      _detail = detail;
      _loading = false;
    });
  }

  Future<void> _downloadIpa() async {
    setState(() => _downloading = true);
    final result = await ApiService().getDownloadLink(widget.appId);
    if (!mounted) return;
    setState(() => _downloading = false);

    if (result['message'] == '__NOT_LOGGED_IN__') {
      _showSnack('登录已过期，请重新登录');
      return;
    }
    if (result['success'] == true) {
      final link = result['link'].toString();
      if (link.isNotEmpty) {
        final uri = Uri.parse(link);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          _showSnack('已在浏览器中打开下载链接');
        } else {
          await Clipboard.setData(ClipboardData(text: link));
          _showSnack('无法打开浏览器，链接已复制');
        }
      }
    } else {
      _showSnack(result['message'] ?? '获取下载链接失败');
    }
  }

  Future<void> _installIpa() async {
    setState(() => _installing = true);
    final result = await ApiService().getInstallPlist(widget.appId);
    if (!mounted) return;
    setState(() => _installing = false);

    if (result['message'] == '__NOT_LOGGED_IN__') {
      _showSnack('登录已过期，请重新登录');
      return;
    }
    if (result['success'] == true) {
      final link = result['link'].toString();
      if (link.isNotEmpty) {
        final itmsUrl = 'itms-services://?action=download-manifest&url=$link';
        // 安卓设备无法安装IPA：自动复制链接到剪贴板
        await Clipboard.setData(ClipboardData(text: link));
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('安卓设备无法安装IPA'),
            content: const Text(
                'IPA是iOS应用安装包，安卓设备无法直接安装。\n\n安装链接已自动复制到剪贴板，请在苹果(iOS)设备上打开此链接进行安装。'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('知道了')),
            ],
          ),
        );
      }
    } else {
      _showSnack(result['message'] ?? '获取安装链接失败');
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.appName), centerTitle: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _detail == null
              ? const Center(child: Text('加载失败'))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 头部
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                          ),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: CachedNetworkImage(
                                imageUrl: _detail!.iconUrl,
                                width: 72,
                                height: 72,
                                fit: BoxFit.cover,
                                placeholder: (_, __) =>
                                    Container(color: Colors.grey[200]),
                                errorWidget: (_, __, ___) =>
                                    const Icon(Icons.android, size: 40),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _detail!.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    [
                                      if (_detail!.version.isNotEmpty)
                                        'v${_detail!.version}',
                                      if (_detail!.size.isNotEmpty) _detail!.size,
                                      if (_detail!.iosVersion.isNotEmpty)
                                        _detail!.iosVersion,
                                    ].join('  ·  '),
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 截图
                      if (_detail!.screenshots.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
                          child: Text('应用截图',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                        SizedBox(
                          height: 320,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: _detail!.screenshots.length,
                            itemBuilder: (context, index) => Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: CachedNetworkImage(
                                  imageUrl: _detail!.screenshots[index],
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Container(
                                      width: 180, color: Colors.grey[200]),
                                  errorWidget: (_, __, ___) => Container(
                                      width: 180, color: Colors.grey[200]),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                      // 描述
                      if (_detail!.description.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
                          child: Text('应用介绍',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            _detail!.description,
                            style: const TextStyle(
                                fontSize: 14, height: 1.6, color: Colors.black87),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      // 按钮
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _downloading ? null : _downloadIpa,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF667EEA),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                ),
                                child: _downloading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Text('在浏览器中下载IPA',
                                        style: TextStyle(fontSize: 16)),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: OutlinedButton(
                                onPressed: _installing ? null : _installIpa,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF667EEA),
                                  side: const BorderSide(color: Color(0xFF667EEA)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                ),
                                child: _installing
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Text('在线安装 (iOS)',
                                        style: TextStyle(fontSize: 16)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
