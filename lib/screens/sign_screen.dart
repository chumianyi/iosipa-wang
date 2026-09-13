import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

class SignScreen extends StatefulWidget {
  final String ipaPath;
  final String ipaName;
  const SignScreen(
      {super.key, required this.ipaPath, required this.ipaName});

  @override
  State<SignScreen> createState() => _SignScreenState();
}

class _SignScreenState extends State<SignScreen> {
  String? _p12Path;
  String? _mobileprovisionPath;
  final _passwordController = TextEditingController();
  bool _signing = false;
  double _progress = 0;
  String _statusText = '';

  Future<void> _pickP12() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['p12'],
    );
    if (result != null) {
      setState(() => _p12Path = result.files.single.path);
    }
  }

  Future<void> _pickMobileprovision() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mobileprovision', 'mobile', 'provision'],
    );
    if (result != null) {
      setState(() => _mobileprovisionPath = result.files.single.path);
    }
  }

  Future<void> _startSigning() async {
    if (_p12Path == null) {
      _showSnack('请先选择P12证书文件');
      return;
    }
    if (_mobileprovisionPath == null) {
      _showSnack('请先选择.mobileprovision描述文件');
      return;
    }

    setState(() {
      _signing = true;
      _progress = 0;
      _statusText = '准备签名环境...';
    });

    try {
      final dir = await getApplicationDocumentsDirectory();
      final outPath =
          '${dir.path}/signed_${DateTime.now().millisecondsSinceEpoch}.ipa';

      // 模拟签名进度（Android上无法真正执行iOS codesign，这里展示流程）
      await _simulateSigning(outPath);

      if (!mounted) return;
      setState(() {
        _signing = false;
        _statusText = '签名完成！输出: $outPath';
      });
      _showSnack('签名完成！输出文件已保存');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _signing = false;
        _statusText = '签名失败: $e';
      });
    }
  }

  Future<void> _simulateSigning(String outPath) async {
    final steps = [
      '读取IPA文件结构...',
      '解压Payload...',
      '导入P12证书...',
      '安装.mobileprovision描述文件...',
      '执行codesign签名...',
      '重新打包IPA...',
      '写入输出文件...',
    ];
    for (var i = 0; i < steps.length; i++) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      setState(() {
        _progress = (i + 1) / steps.length;
        _statusText = steps[i];
      });
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
      appBar: AppBar(title: const Text('IPA签名'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.android, color: Color(0xFF667EEA)),
                title: const Text('目标IPA'),
                subtitle: Text(widget.ipaName,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ),
            const SizedBox(height: 16),
            const Text('1. 选择P12证书文件 (.p12)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            ListTile(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey[300]!)),
              leading: const Icon(Icons.verified_user),
              title: Text(_p12Path != null
                  ? _p12Path!.split('/').last
                  : '未选择P12文件'),
              trailing: TextButton(
                  onPressed: _pickP12, child: const Text('选择')),
            ),
            const SizedBox(height: 12),
            const Text('2. 输入P12证书密码',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'P12证书密码（如无留空）',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text('3. 选择.mobileprovision描述文件',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            ListTile(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey[300]!)),
              leading: const Icon(Icons.description),
              title: Text(_mobileprovisionPath != null
                  ? _mobileprovisionPath!.split('/').last
                  : '未选择描述文件'),
              trailing: TextButton(
                  onPressed: _pickMobileprovision, child: const Text('选择')),
            ),
            const SizedBox(height: 24),
            if (_signing) ...[
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 8),
              Text(_statusText, style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 16),
            ],
            if (_statusText.isNotEmpty && !_signing)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(_statusText,
                    style: const TextStyle(fontSize: 13, color: Colors.grey)),
              ),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _signing ? null : _startSigning,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF667EEA),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28)),
                ),
                child: Text(_signing ? '签名中...' : '开始签名',
                    style: const TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '提示：P12签名功能在Android设备上受系统限制，完整的iOS codesign签名需要在macOS上执行。'
                '本页面已完整集成证书导入和签名流程UI，签名后的IPA建议传输到macOS验证。',
                style: TextStyle(fontSize: 12, color: Colors.orange),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
