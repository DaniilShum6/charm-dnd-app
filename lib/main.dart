import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const CharmApp());

const green = Color(0xFF48C56F);
const bg = Color(0xFFF1F1F1);
const text = Color(0xFF111111);

class CharmApp extends StatelessWidget {
  const CharmApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Charm',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: bg,
        colorScheme: ColorScheme.fromSeed(seedColor: green),
      ),
      home: const CharmRoot(),
    );
  }
}

class CharmRoot extends StatefulWidget {
  const CharmRoot({super.key});
  @override
  State<CharmRoot> createState() => _CharmRootState();
}

class _CharmRootState extends State<CharmRoot> {
  List<Map<String, dynamic>> chars = [];
  int selected = -1;
  int tab = 0;
  final rnd = Random();

  @override
  void initState() {
    super.initState();
    load();
  }

  Map<String, dynamic> newChar([String name = 'Новый персонаж']) => {
        'name': name,
        'level': 1,
        'stats': List.generate(6, (i) => {'name': 'назв.', 'value': 10}),
        'currency': {'Золото': 1000, 'Серебро': 1000, 'Бронза': 1000},
        'items': [
          {'name': 'Название предмета', 'type': 'Тип предмета', 'desc': 'Описание предмета'}
        ],
        'abilities': [
          {'name': 'Название способности', 'type': 'Тип способности', 'desc': 'Описание способности'}
        ],
        'dice': {'4': 1, '6': 1, '8': 1, '10': 1, '12': 1, '20': 1},
      };

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString('charm_data');
    setState(() {
      chars = raw == null ? [] : (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      selected = chars.isEmpty ? -1 : p.getInt('selected')?.clamp(0, chars.length - 1) ?? 0;
    });
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('charm_data', jsonEncode(chars));
    await p.setInt('selected', selected < 0 ? 0 : selected);
  }

  void update(VoidCallback fn) { setState(fn); save(); }

  @override
  Widget build(BuildContext context) {
    if (selected < 0) return picker();
    final c = chars[selected];
    final screens = [home(c), backpack(c), dice(c), abilities(c), more(c)];
    return Scaffold(
      body: Stack(children: [
        gradientBg(),
        SafeArea(child: screens[tab]),
      ]),
      bottomNavigationBar: bottomBar(),
    );
  }

  Widget picker() => Scaffold(
        body: Stack(children: [
          gradientBg(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 70, 24, 20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const Text('Создай своего персонажа\nдля днд прямо в телефоне', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 28)),
                const SizedBox(height: 52),
                const Text('Charm', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 72, fontWeight: FontWeight.w900)),
                const Spacer(),
                ...chars.asMap().entries.map((e) => bigListTile(Icons.person, e.value['name'], 'Открыть лист', () => update(() {selected=e.key;}))),
                bigListTile(Icons.add, 'Создать нового персонажа', 'Новый лист персонажа', () async {
                  update(() { chars.add(newChar('Новый персонаж')); selected = chars.length - 1; });
                }),
              ]),
            ),
          )
        ]),
      );

  Widget home(Map<String, dynamic> c) => ListView(padding: const EdgeInsets.fromLTRB(24, 18, 24, 110), children: [
        topChips(c, showSearch: false),
        const SizedBox(height: 22),
        editHeader(c),
        const SizedBox(height: 24),
        GridView.count(crossAxisCount: 3, mainAxisSpacing: 18, crossAxisSpacing: 18, childAspectRatio: .82, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), children: [
          for (int i = 0; i < c['stats'].length; i++) statCard(c['stats'][i], () => editStat(c, i)),
          addCard(() => update(() => c['stats'].add({'name':'назв.', 'value':10}))),
        ]),
        const SizedBox(height: 26),
        sectionTile('Валюта', 'Редактирование баланса', Icons.paid, () => currencyDialog(c)),
        sectionTile('Способности', 'Редактирование способностей', Icons.auto_awesome, () => setState(() => tab = 3)),
      ]);

  Widget backpack(Map<String, dynamic> c) => ListView(padding: const EdgeInsets.fromLTRB(24, 18, 24, 110), children: [
        topChips(c, active: 'Рюкзак'),
        const SizedBox(height: 26),
        searchField(),
        const SizedBox(height: 18),
        for (int i=0;i<c['items'].length;i++) itemTile(c['items'][i], true, () => editItem(c, i), () => update(()=>c['items'].removeAt(i))),
        itemTile({'name':'Пусто','type':'Тип предмета'}, false, () => editItem(c, -1), null),
      ]);

  Widget abilities(Map<String, dynamic> c) => ListView(padding: const EdgeInsets.fromLTRB(24, 18, 24, 110), children: [
        topChips(c, active: 'Способности'),
        const SizedBox(height: 26),
        for (int i=0;i<c['abilities'].length;i++) itemTile(c['abilities'][i], true, () => editAbility(c, i), () => update(()=>c['abilities'].removeAt(i))),
        itemTile({'name':'Пусто','type':'Тип способности'}, false, () => editAbility(c, -1), null),
      ]);

  Widget dice(Map<String, dynamic> c) => ListView(padding: const EdgeInsets.fromLTRB(24, 18, 24, 110), children: [
        topChips(c, active: 'Кубики', showSearch: false),
        const SizedBox(height: 34),
        const Text('Кубики', style: TextStyle(color: Colors.white, fontSize: 58, fontWeight: FontWeight.w900)),
        const SizedBox(height: 34),
        GridView.count(crossAxisCount: 3, mainAxisSpacing: 18, crossAxisSpacing: 18, childAspectRatio: .82, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), children: [
          for (final d in [4,6,8,10,12,20]) diceCard(c, d),
        ]),
      ]);

  Widget more(Map<String, dynamic> c) => ListView(padding: const EdgeInsets.fromLTRB(24, 18, 24, 110), children: [
        topChips(c, active: 'Меню'),
        const SizedBox(height: 26),
        bigListTile(Icons.switch_account, 'Сменить персонажа', 'Вернуться к списку листов', () => update(()=>selected=-1)),
        bigListTile(Icons.delete_outline, 'Удалить персонажа', 'Удалить текущий лист', () { update(() { chars.removeAt(selected); selected = chars.isEmpty ? -1 : 0; }); }),
        sectionTile('Рюкзак', 'Предметы и поиск', Icons.backpack, () => setState(()=>tab=1)),
        sectionTile('Кубики', 'Быстрые броски', Icons.casino, () => setState(()=>tab=2)),
        sectionTile('Валюта', 'Редактирование баланса', Icons.paid, () => currencyDialog(c)),
      ]);

  Widget gradientBg() => Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.centerRight, colors: [green, Color(0xFF81D99B), bg], stops: [.0,.36,.78])));

  Widget topChips(Map c, {String active='Главная', bool showSearch=true}) => SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
    pill('${c['level']} уровень', trailing: Row(children:[miniBtn(Icons.add,()=>update(()=>c['level']++)), const SizedBox(width:5), miniBtn(Icons.remove,()=>update(()=>c['level']=max(1,c['level']-1)))])),
    pill('Главная', onTap:()=>setState(()=>tab=0), selected: active=='Главная'),
    pill('Рюкзак', onTap:()=>setState(()=>tab=1), selected: active=='Рюкзак'),
    pill('Кубики', onTap:()=>setState(()=>tab=2), selected: active=='Кубики'),
    if (showSearch) pill('Поиск', onTap:()=>setState(()=>tab=1)),
  ]));

  Widget pill(String t, {Widget? trailing, VoidCallback? onTap, bool selected=false}) => Padding(padding: const EdgeInsets.only(right:12), child: InkWell(onTap:onTap, borderRadius: BorderRadius.circular(26), child: Container(padding: const EdgeInsets.symmetric(horizontal:18, vertical:10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: selected ? [shadow()] : []), child: Row(children:[Text(t, style: const TextStyle(fontSize:20, color:text)), if(trailing!=null) ...[const SizedBox(width:10), trailing]]))));
  Widget miniBtn(IconData i, VoidCallback onTap) => InkWell(onTap:onTap, child: CircleAvatar(radius:14, backgroundColor: green, child: Icon(i, color:Colors.white, size:20)));
  BoxShadow shadow() => BoxShadow(color: Colors.black.withOpacity(.12), blurRadius: 18, offset: const Offset(0, 8));

  Widget editHeader(Map<String,dynamic> c) => InkWell(onTap:()=>editText('Имя персонажа', c['name'], (v)=>update(()=>c['name']=v)), child: card(Padding(padding: const EdgeInsets.all(22), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(c['name'], style: const TextStyle(fontSize:34, fontWeight: FontWeight.w900)), const SizedBox(height:6), const Text('имя персонажа', style: TextStyle(fontSize:22, color: green))]))));

  Widget statCard(Map s, VoidCallback onTap) => InkWell(onTap:onTap, borderRadius: BorderRadius.circular(24), child: card(Padding(padding: const EdgeInsets.all(12), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(s['name'], maxLines:1, style: const TextStyle(fontSize:23)), Text('${s['value']}', style: const TextStyle(fontSize:72, fontWeight: FontWeight.w300, color: green)), Row(mainAxisAlignment: MainAxisAlignment.center, children:[miniSquare(Icons.add,()=>update(()=>s['value']++)), const SizedBox(width:8), miniSquare(Icons.remove,()=>update(()=>s['value']--))])]))));
  Widget miniSquare(IconData i, VoidCallback onTap) => InkWell(onTap:onTap, child: Container(width:34,height:34, decoration: BoxDecoration(color:green,borderRadius: BorderRadius.circular(10)), child: Icon(i,color:Colors.white,size:26)));
  Widget addCard(VoidCallback onTap) => InkWell(onTap:onTap, child: card(const Center(child: Icon(Icons.add, color: green, size:72))));

  Widget card(Widget child) => Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26), boxShadow:[BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 14)]), child: child);

  Widget sectionTile(String title, String sub, IconData icon, VoidCallback onTap) => Padding(padding: const EdgeInsets.only(bottom:22), child: InkWell(onTap:onTap, child: card(Padding(padding: const EdgeInsets.all(22), child: Row(children:[Icon(icon,color:green,size:36), const SizedBox(width:16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[Text(title, style: const TextStyle(fontSize:34,fontWeight: FontWeight.w900)), Text(sub, style: const TextStyle(fontSize:22,color:green))]))])))));

  Widget bigListTile(IconData icon, String title, String sub, VoidCallback onTap) => Padding(padding: const EdgeInsets.only(bottom:18), child: InkWell(onTap:onTap, child: card(Padding(padding: const EdgeInsets.all(18), child: Row(children:[CircleAvatar(radius:28, backgroundColor: green, child: Icon(icon, color:Colors.white, size:34)), const SizedBox(width:20), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[Text(title, style: const TextStyle(fontSize:28, fontWeight: FontWeight.w900)), Text(sub, style: const TextStyle(fontSize:18, color:green))]))])))));

  Widget itemTile(Map item, bool exists, VoidCallback onTap, VoidCallback? remove) => Padding(padding: const EdgeInsets.only(bottom:18), child: InkWell(onTap:onTap, child: card(Padding(padding: const EdgeInsets.all(22), child: Row(children:[CircleAvatar(radius:31, backgroundColor: green, child: Icon(exists?Icons.remove:Icons.add, color:Colors.white, size:38)), const SizedBox(width:22), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[Text(item['name'], maxLines:1, overflow:TextOverflow.ellipsis, style: const TextStyle(fontSize:33,fontWeight:FontWeight.w900)), Text(item['type'], style: const TextStyle(fontSize:22,color:green))])), if(remove!=null) IconButton(onPressed:remove, icon: const Icon(Icons.delete_outline))])))));

  Widget searchField() => card(const TextField(decoration: InputDecoration(prefixIcon: Icon(Icons.search, color: green), hintText: 'Поиск предметов', border: InputBorder.none, contentPadding: EdgeInsets.all(20)), style: TextStyle(fontSize:22)));

  Widget diceCard(Map<String,dynamic> c, int d) { final key='$d'; return InkWell(onTap:()=>update(()=>c['dice'][key]=rnd.nextInt(d)+1), child: card(Column(mainAxisAlignment: MainAxisAlignment.center, children:[Text('д$d', style: const TextStyle(fontSize:24)), Text('${c['dice'][key] ?? 1}', style: const TextStyle(fontSize:76, fontWeight: FontWeight.w300, color: green)), const Icon(Icons.touch_app, color: green)]))); }

  Widget bottomBar() => SafeArea(top:false, child: Container(height:82, margin: const EdgeInsets.all(12), padding: const EdgeInsets.symmetric(horizontal:8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow:[shadow()]), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children:[nav(0,Icons.home,'Главная'),nav(1,Icons.backpack,'Рюкзак'),nav(2,Icons.casino,'Кубики'),nav(3,Icons.auto_awesome,'Способ.'),nav(4,Icons.menu,'Ещё')])));
  Widget nav(int i, IconData icon, String label) => InkWell(onTap:()=>setState(()=>tab=i), borderRadius: BorderRadius.circular(20), child: Padding(padding: const EdgeInsets.symmetric(horizontal:6, vertical:8), child: Column(mainAxisSize: MainAxisSize.min, children:[Icon(icon, color: tab==i?green:Colors.black45, size:28), Text(label, style: TextStyle(color: tab==i?green:Colors.black54, fontSize:12, fontWeight: FontWeight.w700))])));

  Future<void> editText(String title, String old, ValueChanged<String> done) async { final ctl=TextEditingController(text: old); final v=await showDialog<String>(context: context, builder:(_)=>AlertDialog(title:Text(title), content: TextField(controller:ctl, autofocus:true), actions:[TextButton(onPressed:()=>Navigator.pop(context), child: const Text('Отмена')), FilledButton(onPressed:()=>Navigator.pop(context, ctl.text), child: const Text('Сохранить'))])); if(v!=null && v.trim().isNotEmpty) done(v.trim()); }

  Future<void> editStat(Map c, int i) async { final s=c['stats'][i]; final name=TextEditingController(text:s['name']); final val=TextEditingController(text:'${s['value']}'); await showDialog(context:context,builder:(_)=>AlertDialog(title:const Text('Характеристика'), content:Column(mainAxisSize:MainAxisSize.min, children:[TextField(controller:name, decoration: const InputDecoration(labelText:'Название')), TextField(controller:val, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText:'Значение'))]), actions:[TextButton(onPressed:()=>Navigator.pop(context), child:const Text('Отмена')), FilledButton(onPressed:(){update((){s['name']=name.text; s['value']=int.tryParse(val.text)??s['value'];}); Navigator.pop(context);}, child:const Text('Сохранить'))])); }

  Future<void> editItem(Map c, int i) => editEntity(c, i, 'items', 'Название предмета', 'Тип предмета', 'Описание предмета');
  Future<void> editAbility(Map c, int i) => editEntity(c, i, 'abilities', 'Название способности', 'Тип способности', 'Описание способности');
  Future<void> editEntity(Map c, int i, String key, String n, String t, String d) async { final isNew=i<0; final e=isNew?{'name':'','type':'','desc':''}:c[key][i]; final name=TextEditingController(text:e['name']); final type=TextEditingController(text:e['type']); final desc=TextEditingController(text:e['desc']??''); await showModalBottomSheet(context: context, isScrollControlled:true, backgroundColor: Colors.transparent, builder:(_)=>Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom), child: Container(margin: const EdgeInsets.all(18), padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)), child: Column(mainAxisSize:MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children:[Text(n, style: const TextStyle(fontSize:32,fontWeight:FontWeight.w900)), TextField(controller:name, decoration: InputDecoration(labelText:n)), TextField(controller:type, decoration: InputDecoration(labelText:t)), TextField(controller:desc, maxLines:5, decoration: InputDecoration(labelText:d)), const SizedBox(height:14), SizedBox(width:double.infinity, child: FilledButton(onPressed:(){update((){final m={'name':name.text.isEmpty?n:name.text,'type':type.text.isEmpty?t:type.text,'desc':desc.text}; if(isNew)c[key].add(m); else c[key][i]=m;}); Navigator.pop(context);}, child: const Text('Сохранить')))])))); }

  Future<void> currencyDialog(Map<String,dynamic> c) async { await showDialog(context: context, builder:(_)=>Dialog(backgroundColor:Colors.transparent, child: Container(padding: const EdgeInsets.all(28), decoration: BoxDecoration(color:Colors.white, borderRadius: BorderRadius.circular(34), boxShadow:[shadow()]), child: Column(mainAxisSize:MainAxisSize.min, children:[const Text('Валюта', style: TextStyle(fontSize:46,fontWeight:FontWeight.w900)), const Text('Редактирование баланса', style: TextStyle(fontSize:20,color:green)), const SizedBox(height:18), for(final k in ['Золото','Серебро','Бронза']) currencyRow(c,k)])))); }
  Widget currencyRow(Map c, String k) => Container(margin: const EdgeInsets.only(bottom:14), padding: const EdgeInsets.symmetric(horizontal:22, vertical:12), decoration: BoxDecoration(color:green, borderRadius: BorderRadius.circular(24)), child: Row(children:[Expanded(child:InkWell(onTap:()=>editText(k, '${c['currency'][k]}', (v)=>update(()=>c['currency'][k]=int.tryParse(v)??c['currency'][k])), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[Text(k, style: const TextStyle(color:Colors.white,fontSize:19)), Text('${c['currency'][k]}', style: const TextStyle(color:Colors.white,fontSize:40,fontWeight:FontWeight.w300))]))), CircleAvatar(backgroundColor:Colors.white, child: IconButton(icon:const Icon(Icons.add,color:green), onPressed:()=>update(()=>c['currency'][k]++))), const SizedBox(width:10), CircleAvatar(backgroundColor:Colors.white, child: IconButton(icon:const Icon(Icons.remove,color:green), onPressed:()=>update(()=>c['currency'][k]=max(0,c['currency'][k]-1))))]));
}
