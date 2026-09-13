import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'sign_screen.dart';

class IpaFile {
  final String path;
  final String name;
  final int size;
  final DateTime modified;
  IpaFile({
    required this.path,
    required this.name,
    required this.size,
    required this.modified,
  });
}

class MyIpaTab extends StatefulWidget {
  const MyIpaTab({super.key});

  @override
  State<MyIpaTab> createState() => _MyIpaTabState();
}

class _MyIpaTabState extends State<MyIpaTab> {
  List<IpaFile> _files = [];
  bool _scanning = false;

  @override
  void initState() {
    super.initState();
    _requestPermissionAndScan();
  }

  Future<void> _requestPermissionAndScan() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      status = await Permission.storage.request();
    }
    if (Platform.isAndroid) {
      final sdk = await _getSdkInt();
      if (sdk >= 30) {
        final manage = await Permission.manageExternalStorage.status;
        if (!manage.isGranted) {
          await Permission.manageExternalStorage.request();
        }
      }
    }
    _scanFiles();
  }

  Future<int> _getSdkInt() async {
    if (!Platform.isAndroid) return 0;
    return 34;
  }

  Future<void> _scanFiles() async {
    setState(() => _scanning = true);
    final List<IpaFile> found = [];
    final Set<String> seen = {};

    // 扫描目录列表（硬编码常见下载目录）
    final List<String> dirs = [
      '/storage/emulated/0/Download',
      '/storage/emulated/0/Downloads',
      '/storage/emulated/0',
      '/sdcard/Download',
      '/sdcard',
    ];
    try {
      final appDoc = await getApplicationDocumentsDirectory();
      dirs.add(appDoc.path);
    } catch (_) {}
    try {
      final ext = await getExternalStorageDirectory();
      if (ext != null) dirs.add(ext.path);
    } catch (_) {}

    for (var dir in dirs) {
      try {
        final d = Directory(dir);
        if (!await d.exists()) continue;
        await for (var entity in d.list(recursive: false, followLinks: false)) {
          if (entity is File && entity.path.toLowerCase().endsWith('.ipa')) {
            if (seen.contains(entity.path)) continue;
            seen.add(entity.path);
            try {
              final stat = await entity.stat();
              found.add(IpaFile(
                path: entity.path,
                name: entity.path.split('/').last,
                size: stat.size,
                modified: stat.modified,
              ));
            } catch (_) {}
          }
        }
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() {
      _files = found;
      _scanning = false;
    });
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
  }

  Future<void> _deleteFile(IpaFile file) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('删除文件'),
        content: Text('确定删除 ${file.name} 吗？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('删除', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await File(file.path).delete();
        _scanFiles();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('删除失败: $e')));
        }
      }
    }
  }

  void _signIpa(IpaFile file) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SignScreen(ipaPath: file.path, ipaName: file.name),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
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
                  '我的IPA',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '本地IPA文件管理与签名',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.8), fontSize: 13),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _scanning ? null : _scanFiles,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('扫描文件'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['ipa'],
                    );
                    if (result != null && result.files.single.path != null) {
                      _scanFiles();
                    }
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('导入IPA'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _scanning
                ? const Center(child: CircularProgressIndicator())
                : _files.isEmpty
                    ? const Center(
                        child: Text('未找到IPA文件\n从浏览器下载的IPA会出现在这里',
                            textAlign: TextAlign.center))
                    : ListView.builder(
                        itemCount: _files.length,
                        itemBuilder: (context, index) {
                          final f = _files[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            child: ListTile(
                              leading: const Icon(Icons.android,
                                  color: Color(0xFF667EEA), size: 36),
                              title: Text(f.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                  '${_formatSize(f.size)}  ·  ${f.modified.toString().substring(0, 16)}'),
                              trailing: PopupMenuButton<String>(
                                onSelected: (v) {
                                  if (v == 'sign') _signIpa(f);
                                  if (v == 'delete') _deleteFile(f);
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                      value: 'sign', child: Text('签名此IPA')),
                                  PopupMenuItem(
                                      value: 'delete',
                                      child: Text('删除',
                                          style: TextStyle(color: Colors.red))),
                                ],
                              ),
                              onTap: () => _signIpa(f),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
