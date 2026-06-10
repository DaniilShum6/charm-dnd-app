import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

void main() => runApp(const CharmApp());

const _uuid = Uuid();

class CharmApp extends StatelessWidget {
  const CharmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Charm DnD',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB783FF),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF121019),
        useMaterial3: true,
        cardTheme: CardThemeData(
          color: const Color(0xFF1D1728),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF271F35),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        ),
      ),
      home: const CharacterHome(),
    );
  }
}

class Character {
  String id;
  String name;
  int level;
  List<StatItem> stats;
  Map<String, int> currency;
  List<BackpackItem> backpack;
  List<AbilityItem> abilities;

  Character({
    required this.id,
    required this.name,
    required this.level,
    required this.stats,
    required this.currency,
    required this.backpack,
    required this.abilities,
  });

  factory Character.empty() => Character(
        id: _uuid.v4(),
        name: 'Новый герой',
        level: 1,
        stats: [
          StatItem('Сила', '10'),
          StatItem('Ловкость', '10'),
          StatItem('Телосложение', '10'),
          StatItem('Интеллект', '10'),
          StatItem('Мудрость', '10'),
          StatItem('Харизма', '10'),
        ],
        currency: {'Медь': 0, 'Серебро': 0, 'Электрум': 0, 'Золото': 0, 'Платина': 0},
        backpack: [],
        abilities: [],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'level': level,
        'stats': stats.map((e) => e.toJson()).toList(),
        'currency': currency,
        'backpack': backpack.map((e) => e.toJson()).toList(),
        'abilities': abilities.map((e) => e.toJson()).toList(),
      };

  factory Character.fromJson(Map<String, dynamic> json) => Character(
        id: json['id'] ?? _uuid.v4(),
        name: json['name'] ?? 'Герой',
        level: json['level'] ?? 1,
        stats: ((json['stats'] ?? []) as List).map((e) => StatItem.fromJson(Map<String, dynamic>.from(e))).toList(),
        currency: Map<String, int>.from(json['currency'] ?? {'Золото': 0}),
        backpack: ((json['backpack'] ?? []) as List).map((e) => BackpackItem.fromJson(Map<String, dynamic>.from(e))).toList(),
        abilities: ((json['abilities'] ?? []) as List).map((e) => AbilityItem.fromJson(Map<String, dynamic>.from(e))).toList(),
      );
}

class StatItem {
  String name;
  String value;
  StatItem(this.name, this.value);
  Map<String, dynamic> toJson() => {'name': name, 'value': value};
  factory StatItem.fromJson(Map<String, dynamic> json) => StatItem(json['name'] ?? '', json['value'] ?? '');
}

class BackpackItem {
  String name;
  String type;
  String note;
  BackpackItem({required this.name, required this.type, this.note = ''});
  Map<String, dynamic> toJson() => {'name': name, 'type': type, 'note': note};
  factory BackpackItem.fromJson(Map<String, dynamic> json) => BackpackItem(name: json['name'] ?? '', type: json['type'] ?? '', note: json['note'] ?? '');
}

class AbilityItem {
  String name;
  String type;
  String description;
  AbilityItem({required this.name, required this.type, required this.description});
  Map<String, dynamic> toJson() => {'name': name, 'type': type, 'description': description};
  factory AbilityItem.fromJson(Map<String, dynamic> json) => AbilityItem(name: json['name'] ?? '', type: json['type'] ?? '', description: json['description'] ?? '');
}

class CharacterHome extends StatefulWidget {
  const CharacterHome({super.key});
  @override
  State<CharacterHome> createState() => _CharacterHomeState();
}

class _CharacterHomeState extends State<CharacterHome> {
  final List<Character> _characters = [];
  int _selectedIndex = 0;
  int _tabIndex = 0;
  bool _loaded = false;

  Character get current => _characters[_selectedIndex];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('characters');
    if (raw != null) {
      final decoded = (jsonDecode(raw) as List).map((e) => Character.fromJson(Map<String, dynamic>.from(e))).toList();
      _characters.addAll(decoded);
    }
    if (_characters.isEmpty) _characters.add(Character.empty());
    setState(() => _loaded = true);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('characters', jsonEncode(_characters.map((e) => e.toJson()).toList()));
  }

  void _addCharacter() {
    setState(() {
      _characters.add(Character.empty());
      _selectedIndex = _characters.length - 1;
    });
    _save();
  }

  void _deleteCharacter() {
    if (_characters.length == 1) return;
    setState(() {
      _characters.removeAt(_selectedIndex);
      _selectedIndex = max(0, _selectedIndex - 1);
    });
    _save();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final screens = [
      CharacterScreen(character: current, onChanged: _save),
      CurrencyScreen(character: current, onChanged: _save),
      BackpackScreen(character: current, onChanged: _save),
      AbilityScreen(character: current, onChanged: _save),
      DiceScreen(),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Charm'),
        actions: [
          DropdownButton<int>(
            value: _selectedIndex,
            underline: const SizedBox.shrink(),
            items: [for (var i = 0; i < _characters.length; i++) DropdownMenuItem(value: i, child: Text(_characters[i].name))],
            onChanged: (v) => setState(() => _selectedIndex = v ?? 0),
          ),
          IconButton(onPressed: _addCharacter, icon: const Icon(Icons.add)),
          IconButton(onPressed: _deleteCharacter, icon: const Icon(Icons.delete_outline)),
        ],
      ),
      body: screens[_tabIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.person), label: 'Герой'),
          NavigationDestination(icon: Icon(Icons.paid), label: 'Валюта'),
          NavigationDestination(icon: Icon(Icons.backpack), label: 'Рюкзак'),
          NavigationDestination(icon: Icon(Icons.auto_awesome), label: 'Способности'),
          NavigationDestination(icon: Icon(Icons.casino), label: 'Кубики'),
        ],
      ),
    );
  }
}

class CharacterScreen extends StatefulWidget {
  final Character character;
  final VoidCallback onChanged;
  const CharacterScreen({super.key, required this.character, required this.onChanged});
  @override
  State<CharacterScreen> createState() => _CharacterScreenState();
}

class _CharacterScreenState extends State<CharacterScreen> {
  @override
  Widget build(BuildContext context) {
    final c = widget.character;
    return ListView(padding: const EdgeInsets.all(16), children: [
      _Card(child: Column(children: [
        TextFormField(initialValue: c.name, decoration: const InputDecoration(labelText: 'Имя персонажа'), onChanged: (v) { c.name = v; widget.onChanged(); setState(() {}); }),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: Text('Уровень: ${c.level}', style: Theme.of(context).textTheme.titleLarge)),
          IconButton(onPressed: () { setState(() => c.level = max(1, c.level - 1)); widget.onChanged(); }, icon: const Icon(Icons.remove_circle_outline)),
          IconButton(onPressed: () { setState(() => c.level++); widget.onChanged(); }, icon: const Icon(Icons.add_circle_outline)),
        ]),
      ])),
      const SizedBox(height: 12),
      Text('Характеристики', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8),
      for (final stat in c.stats) _Card(child: Row(children: [
        Expanded(child: TextFormField(initialValue: stat.name, decoration: const InputDecoration(labelText: 'Название'), onChanged: (v) { stat.name = v; widget.onChanged(); })),
        const SizedBox(width: 10),
        SizedBox(width: 100, child: TextFormField(initialValue: stat.value, decoration: const InputDecoration(labelText: 'Знач.'), onChanged: (v) { stat.value = v; widget.onChanged(); })),
        IconButton(onPressed: () { setState(() => c.stats.remove(stat)); widget.onChanged(); }, icon: const Icon(Icons.close)),
      ])),
      FilledButton.icon(onPressed: () { setState(() => c.stats.add(StatItem('Новая', '0'))); widget.onChanged(); }, icon: const Icon(Icons.add), label: const Text('Добавить характеристику')),
    ]);
  }
}

class CurrencyScreen extends StatefulWidget {
  final Character character;
  final VoidCallback onChanged;
  const CurrencyScreen({super.key, required this.character, required this.onChanged});
  @override
  State<CurrencyScreen> createState() => _CurrencyScreenState();
}
class _CurrencyScreenState extends State<CurrencyScreen> {
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
    for (final key in widget.character.currency.keys.toList()) _Card(child: Row(children: [
      Expanded(child: TextFormField(initialValue: key, decoration: const InputDecoration(labelText: 'Валюта'), onFieldSubmitted: (v) { final val = widget.character.currency.remove(key) ?? 0; widget.character.currency[v] = val; widget.onChanged(); setState(() {}); })),
      IconButton(onPressed: () => _change(key, -1), icon: const Icon(Icons.remove)),
      Text('${widget.character.currency[key]}', style: Theme.of(context).textTheme.headlineSmall),
      IconButton(onPressed: () => _change(key, 1), icon: const Icon(Icons.add)),
      IconButton(onPressed: () { setState(() => widget.character.currency.remove(key)); widget.onChanged(); }, icon: const Icon(Icons.close)),
    ])),
    FilledButton.icon(onPressed: () { setState(() => widget.character.currency['Новая валюта'] = 0); widget.onChanged(); }, icon: const Icon(Icons.add), label: const Text('Добавить валюту')),
  ]);
  void _change(String key, int delta) { setState(() => widget.character.currency[key] = max(0, (widget.character.currency[key] ?? 0) + delta)); widget.onChanged(); }
}

class BackpackScreen extends StatefulWidget {
  final Character character;
  final VoidCallback onChanged;
  const BackpackScreen({super.key, required this.character, required this.onChanged});
  @override
  State<BackpackScreen> createState() => _BackpackScreenState();
}
class _BackpackScreenState extends State<BackpackScreen> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final items = widget.character.backpack.where((e) => '${e.name} ${e.type} ${e.note}'.toLowerCase().contains(query.toLowerCase())).toList();
    return ListView(padding: const EdgeInsets.all(16), children: [
      TextField(decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Поиск предметов'), onChanged: (v) => setState(() => query = v)),
      const SizedBox(height: 12),
      for (final item in items) _Card(child: Column(children: [
        TextFormField(initialValue: item.name, decoration: const InputDecoration(labelText: 'Предмет'), onChanged: (v) { item.name = v; widget.onChanged(); }),
        const SizedBox(height: 8),
        TextFormField(initialValue: item.type, decoration: const InputDecoration(labelText: 'Тип'), onChanged: (v) { item.type = v; widget.onChanged(); }),
        const SizedBox(height: 8),
        TextFormField(initialValue: item.note, decoration: const InputDecoration(labelText: 'Описание / заметка'), onChanged: (v) { item.note = v; widget.onChanged(); }),
        Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: () { setState(() => widget.character.backpack.remove(item)); widget.onChanged(); }, icon: const Icon(Icons.delete), label: const Text('Удалить'))),
      ])),
      FilledButton.icon(onPressed: () { setState(() => widget.character.backpack.add(BackpackItem(name: 'Новый предмет', type: 'Тип'))); widget.onChanged(); }, icon: const Icon(Icons.add), label: const Text('Добавить предмет')),
    ]);
  }
}

class AbilityScreen extends StatefulWidget {
  final Character character;
  final VoidCallback onChanged;
  const AbilityScreen({super.key, required this.character, required this.onChanged});
  @override
  State<AbilityScreen> createState() => _AbilityScreenState();
}
class _AbilityScreenState extends State<AbilityScreen> {
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
    for (final ability in widget.character.abilities) _Card(child: Column(children: [
      TextFormField(initialValue: ability.name, decoration: const InputDecoration(labelText: 'Название способности'), onChanged: (v) { ability.name = v; widget.onChanged(); }),
      const SizedBox(height: 8),
      TextFormField(initialValue: ability.type, decoration: const InputDecoration(labelText: 'Тип'), onChanged: (v) { ability.type = v; widget.onChanged(); }),
      const SizedBox(height: 8),
      TextFormField(initialValue: ability.description, minLines: 2, maxLines: 5, decoration: const InputDecoration(labelText: 'Описание'), onChanged: (v) { ability.description = v; widget.onChanged(); }),
      Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: () { setState(() => widget.character.abilities.remove(ability)); widget.onChanged(); }, icon: const Icon(Icons.delete), label: const Text('Удалить'))),
    ])),
    FilledButton.icon(onPressed: () { setState(() => widget.character.abilities.add(AbilityItem(name: 'Новая способность', type: 'Активная', description: ''))); widget.onChanged(); }, icon: const Icon(Icons.add), label: const Text('Добавить способность')),
  ]);
}

class DiceScreen extends StatefulWidget {
  const DiceScreen({super.key});
  @override
  State<DiceScreen> createState() => _DiceScreenState();
}
class _DiceScreenState extends State<DiceScreen> {
  int sides = 20;
  int result = 1;
  final random = Random();
  final dice = [4, 6, 8, 10, 12, 20];
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(16), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    _Card(child: SizedBox(width: 260, height: 180, child: Center(child: Text('$result', style: const TextStyle(fontSize: 88, fontWeight: FontWeight.bold))))),
    const SizedBox(height: 20),
    Wrap(spacing: 10, runSpacing: 10, children: [for (final d in dice) ChoiceChip(label: Text('d$d'), selected: sides == d, onSelected: (_) => setState(() { sides = d; result = min(result, sides); }))]),
    const SizedBox(height: 20),
    FilledButton.icon(onPressed: () => setState(() => result = random.nextInt(sides) + 1), icon: const Icon(Icons.casino), label: Text('Бросить d$sides')),
  ])));
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) => Card(margin: const EdgeInsets.only(bottom: 12), child: Padding(padding: const EdgeInsets.all(14), child: child));
}
