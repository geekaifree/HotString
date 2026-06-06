import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() => runApp(const HotStringApp());

class HotStringApp extends StatelessWidget {
  const HotStringApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: '热字符串工具', debugShowCheckedModeBanner: false,
    theme: ThemeData(colorSchemeSeed: Colors.purple, useMaterial3: true, brightness: Brightness.light),
    darkTheme: ThemeData(colorSchemeSeed: Colors.purple, useMaterial3: true, brightness: Brightness.dark),
    home: const HotStringHomePage(),
  );
}

class HotString {
  String id, abbr, full, category;
  int useCount;
  HotString({required this.id, required this.abbr, required this.full, this.category = '通用', this.useCount = 0});
  Map<String, dynamic> toJson() => {'id': id, 'abbr': abbr, 'full': full, 'category': category, 'useCount': useCount};
  factory HotString.fromJson(Map<String, dynamic> j) => HotString(id: j['id'], abbr: j['abbr'], full: j['full'], category: j['category'] ?? '通用', useCount: j['useCount'] ?? 0);
}

class HotStringHomePage extends StatefulWidget {
  const HotStringHomePage({super.key});
  @override
  State<HotStringHomePage> createState() => _HotStringHomePageState();
}

class _HotStringHomePageState extends State<HotStringHomePage> {
  List<HotString> _strings = [];
  String _category = '全部';
  final _inputCtrl = TextEditingController();
  String _preview = '';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final d = p.getString('hotstrings');
    if (d != null) setState(() => _strings = (json.decode(d) as List).map((e) => HotString.fromJson(e)).toList());
    else {
      _strings = [
        HotString(id: '1', abbr: '/em', full: 'user@example.com', category: '邮箱'),
        HotString(id: '2', abbr: '/addr', full: '北京市朝阳区xxx路xxx号', category: '地址'),
        HotString(id: '3', abbr: '/phone', full: '13800138000', category: '联系方式'),
        HotString(id: '4', abbr: '/date', full: '2024年1月15日', category: '日期'),
        HotString(id: '5', abbr: '/sign', full: '此致\n敬礼\n——张三', category: '签名'),
        HotString(id: '6', abbr: '/ty', full: '谢谢您的来信，我会尽快回复。', category: '模板'),
        HotString(id: '7', abbr: '/code', full: '```dart\nvoid main() {\n  print("Hello");\n}\n```', category: '代码'),
      ];
      _save();
    }
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('hotstrings', json.encode(_strings.map((e) => e.toJson()).toList()));
  }

  List<HotString> get _filtered => _category == '全部' ? _strings : _strings.where((s) => s.category == _category).toList();

  List<String> get _categories => ['全部', ...{..._strings.map((s) => s.category)}];

  void _expand() {
    final input = _inputCtrl.text;
    String result = input;
    for (final s in _strings) {
      if (result.contains(s.abbr)) {
        result = result.replaceAll(s.abbr, s.full);
        setState(() => s.useCount++);
      }
    }
    setState(() => _preview = result);
    _save();
  }

  void _add() {
    final abbrC = TextEditingController();
    final fullC = TextEditingController();
    final catC = TextEditingController(text: '通用');
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('添加热字符串'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: abbrC, decoration: const InputDecoration(labelText: '缩写 (如 /em)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.shortcut))),
        const SizedBox(height: 12),
        TextField(controller: fullC, decoration: const InputDecoration(labelText: '展开内容', border: OutlineInputBorder(), prefixIcon: Icon(Icons.text_fields)), maxLines: 4),
        const SizedBox(height: 12),
        TextField(controller: catC, decoration: const InputDecoration(labelText: '分类', border: OutlineInputBorder(), prefixIcon: Icon(Icons.category))),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        FilledButton(onPressed: () { if (abbrC.text.isNotEmpty && fullC.text.isNotEmpty) { setState(() => _strings.add(HotString(id: DateTime.now().millisecondsSinceEpoch.toString(), abbr: abbrC.text, full: fullC.text, category: catC.text))); _save(); } Navigator.pop(ctx); }, child: const Text('添加')),
      ],
    ));
  }

  void _edit(HotString s) {
    final abbrC = TextEditingController(text: s.abbr);
    final fullC = TextEditingController(text: s.full);
    final catC = TextEditingController(text: s.category);
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('编辑热字符串'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: abbrC, decoration: const InputDecoration(labelText: '缩写', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: fullC, decoration: const InputDecoration(labelText: '展开内容', border: OutlineInputBorder()), maxLines: 4),
        const SizedBox(height: 12),
        TextField(controller: catC, decoration: const InputDecoration(labelText: '分类', border: OutlineInputBorder())),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        FilledButton(onPressed: () { setState(() { s.abbr = abbrC.text; s.full = fullC.text; s.category = catC.text; }); _save(); Navigator.pop(ctx); }, child: const Text('保存')),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🔤 热字符串工具'), centerTitle: true, actions: [
        IconButton(icon: const Icon(Icons.add), onPressed: _add, tooltip: '添加'),
      ]),
      body: Column(children: [
        // 测试区域
        Card(margin: const EdgeInsets.all(12), child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('测试展开', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(controller: _inputCtrl, decoration: InputDecoration(hintText: '输入缩写，如 /em', border: const OutlineInputBorder(), suffixIcon: IconButton(icon: const Icon(Icons.play_arrow), onPressed: _expand)), onChanged: (_) => _expand()),
          if (_preview.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.green.shade200)), child: Text(_preview, style: const TextStyle(fontSize: 14)))),
        ]))),
        // 分类筛选
        SizedBox(height: 40, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12), children: _categories.map((c) => Padding(padding: const EdgeInsets.only(right: 6), child: FilterChip(label: Text(c, style: const TextStyle(fontSize: 12)), selected: _category == c, onSelected: (_) => setState(() => _category = c), visualDensity: VisualDensity.compact))).toList())),
        // 列表
        Expanded(child: _filtered.isEmpty ? const Center(child: Text('暂无热字符串', style: TextStyle(color: Colors.grey))) : ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 12), itemCount: _filtered.length, itemBuilder: (ctx, i) {
          final s = _filtered[i];
          return Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
            leading: Container(width: 48, height: 48, decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Center(child: Text(s.abbr, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple, fontSize: 12)))),
            title: Text(s.full, maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: Text('${s.category} • 使用 ${s.useCount} 次', style: const TextStyle(fontSize: 12)),
            trailing: PopupMenuButton(itemBuilder: (ctx) => [const PopupMenuItem(value: 'edit', child: Text('编辑')), const PopupMenuItem(value: 'copy', child: Text('复制')), const PopupMenuItem(value: 'delete', child: Text('删除', style: TextStyle(color: Colors.red)))], onSelected: (v) {
              if (v == 'edit') _edit(s);
              if (v == 'copy') ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已复制: ${s.full}'), behavior: SnackBarBehavior.floating));
              if (v == 'delete') { setState(() => _strings.removeWhere((x) => x.id == s.id)); _save(); }
            }),
          ));
        })),
      ]),
    );
  }
}
