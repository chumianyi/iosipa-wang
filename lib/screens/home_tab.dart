import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../services/api_service.dart';
import '../widgets/app_list_item.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  int _selectedCategory = 0;
  List<AppInfo> _apps = [];
  bool _loading = true;
  String? _error;

  static const List<Map<String, String>> _categories = [
    {'name': '推荐', 'path': '/'},
    {'name': '游戏', 'path': '/game.html'},
    {'name': '软件', 'path': '/soft.html'},
  ];

  @override
  void initState() {
    super.initState();
    _loadData(0);
  }

  Future<void> _loadData(int index) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final path = _categories[index]['path']!;
    final apps = await ApiService().fetchAppList(path);
    if (!mounted) return;
    setState(() {
      _apps = apps;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 48, 20, 12),
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
                  'iosipa.wang',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '每日更新 · 海量IPA资源',
                  style:
                      TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                ),
              ],
            ),
          ),
          // 分类Tab
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final selected = _selectedCategory == index;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: ChoiceChip(
                    label: Text(_categories[index]['name']!),
                    selected: selected,
                    onSelected: (_) {
                      setState(() => _selectedCategory = index);
                      _loadData(index);
                    },
                    selectedColor: const Color(0xFF667EEA),
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : Colors.black87,
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : _apps.isEmpty
                        ? const Center(child: Text('暂无数据，下拉重试'))
                        : RefreshIndicator(
                            onRefresh: () => _loadData(_selectedCategory),
                            child: ListView.builder(
                              itemCount: _apps.length,
                              itemBuilder: (context, index) =>
                                  AppListItem(app: _apps[index]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
