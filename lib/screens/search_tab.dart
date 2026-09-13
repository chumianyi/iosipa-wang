import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_models.dart';
import '../services/api_service.dart';
import '../widgets/app_list_item.dart';

class SearchTab extends StatefulWidget {
  const SearchTab({super.key});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  final _searchController = TextEditingController();
  List<AppInfo> _results = [];
  bool _loading = false;
  bool _searched = false;
  List<String> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _history = prefs.getStringList('search_history') ?? [];
    });
  }

  Future<void> _saveHistory(String keyword) async {
    final prefs = await SharedPreferences.getInstance();
    final list = List<String>.from(_history);
    list.remove(keyword);
    list.insert(0, keyword);
    if (list.length > 10) list.removeRange(10, list.length);
    await prefs.setStringList('search_history', list);
    setState(() => _history = list);
  }

  Future<void> _doSearch(String keyword) async {
    if (keyword.trim().isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _searched = true;
    });
    await _saveHistory(keyword.trim());
    final results = await ApiService().searchApps(keyword.trim());
    if (!mounted) return;
    setState(() {
      _results = results;
      _loading = false;
    });
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
                  '搜索应用',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: _doSearch,
                  decoration: InputDecoration(
                    hintText: '输入应用名称搜索',
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_history.isNotEmpty && !_searched)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _history
                      .map((kw) => ActionChip(
                            label: Text(kw),
                            onPressed: () {
                              _searchController.text = kw;
                              _doSearch(kw);
                            },
                          ))
                      .toList(),
                ),
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : !_searched
                    ? const Center(child: Text('输入关键词搜索应用'))
                    : _results.isEmpty
                        ? const Center(child: Text('未找到相关应用'))
                        : ListView.builder(
                            itemCount: _results.length,
                            itemBuilder: (context, index) =>
                                AppListItem(app: _results[index]),
                          ),
          ),
        ],
      ),
    );
  }
}
