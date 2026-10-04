import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/user_data_service.dart';

class EmbyScreen extends StatefulWidget {
  const EmbyScreen({super.key});
  @override
  State<EmbyScreen> createState() => _EmbyScreenState();
}

class _EmbyScreenState extends State<EmbyScreen> {
  bool _loading = true;
  String? _error;
  String? _source;
  String? _selectedView;
  List<Map<String, dynamic>> _sources = [];
  List<Map<String, dynamic>> _views = [];
  List<Map<String, dynamic>> _items = [];

  Future<Map<String, dynamic>> _get(String path) async {
    final base = (await UserDataService.getServerUrl() ??
            UserDataService.defaultServerUrl)
        .replaceAll(RegExp(r'/+$'), '');
    final cookies = await UserDataService.getCookies();
    final response = await http.get(Uri.parse('$base$path'), headers: {
      if (cookies != null) 'Cookie': cookies
    }).timeout(const Duration(seconds: 30));
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300)
      throw Exception(data['error']?.toString() ?? 'Emby请求失败');
    return data;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final sourceData = await _get('/api/emby/sources');
      _sources = List<Map<String, dynamic>>.from(sourceData['sources'] ?? []);
      _source ??=
          _sources.isNotEmpty ? _sources.first['key']?.toString() : null;
      final suffix = _source == null
          ? ''
          : '?embyKey=${Uri.encodeQueryComponent(_source!)}';
      final viewData = await _get('/api/emby/views$suffix');
      _views = List<Map<String, dynamic>>.from(viewData['views'] ?? []);
      final parent = _selectedView == null
          ? ''
          : '&parentId=${Uri.encodeQueryComponent(_selectedView!)}';
      final itemData = await _get(
          '/api/emby/list?page=1&pageSize=40&sortBy=SortName&sortOrder=Ascending$suffix$parent');
      _items = List<Map<String, dynamic>>.from(itemData['list'] ?? []);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(children: [
                    Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(child: Text(_error!)))
                  ])
                : CustomScrollView(slivers: [
                    SliverToBoxAdapter(child: _header()),
                    if (_views.isNotEmpty)
                      SliverToBoxAdapter(child: _categories()),
                    if (_items.isEmpty)
                      const SliverFillRemaining(
                          child: Center(child: Text('暂无 Emby 内容')))
                    else
                      SliverPadding(
                        padding: const EdgeInsets.all(12),
                        sliver: SliverGrid(
                          delegate: SliverChildBuilderDelegate(
                              (context, index) => _card(_items[index]),
                              childCount: _items.length),
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 180,
                                  childAspectRatio: .62,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 16),
                        ),
                      ),
                  ]),
      );

  Widget _header() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Row(children: [
          const Icon(Icons.video_library, color: Color(0xFF27ae60), size: 28),
          const SizedBox(width: 10),
          const Text('Emby',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
          const Spacer(),
          if (_sources.length > 1)
            DropdownButton<String>(
                value: _source,
                items: _sources
                    .map((s) => DropdownMenuItem(
                        value: s['key']?.toString(),
                        child: Text(s['name']?.toString() ?? 'Emby')))
                    .toList(),
                onChanged: (v) {
                  _source = v;
                  _selectedView = null;
                  _load();
                }),
        ]),
      );

  Widget _categories() => SizedBox(
        height: 52,
        child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              _chip('全部', null),
              ..._views.map((v) =>
                  _chip(v['name']?.toString() ?? '媒体库', v['id']?.toString()))
            ]),
      );

  Widget _chip(String label, String? value) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: ChoiceChip(
            label: Text(label),
            selected: _selectedView == value,
            onSelected: (_) {
              _selectedView = value;
              _load();
            }),
      );

  Widget _card(Map<String, dynamic> item) => InkWell(
        onTap: () {},
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(item['poster']?.toString() ?? '',
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.movie, size: 42))))),
          const SizedBox(height: 6),
          Text(item['title']?.toString() ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(item['year']?.toString() ?? '',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        ]),
      );
}
