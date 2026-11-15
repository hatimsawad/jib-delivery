// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const jibRed = Color(0xFFE31E24);
const supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://emvleaghjsmzjmzgguvu.supabase.co');
const supabasePublishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY', defaultValue: 'sb_publishable_6rD4poWuBH0TzK2HBFQFTg_4wOFnsX6');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, publishableKey: supabasePublishableKey);
  runApp(const JibMerchantApp());
}

final db = Supabase.instance.client;

class JibMerchantApp extends StatelessWidget {
  const JibMerchantApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'JIB التاجر', debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: jibRed, primary: jibRed), scaffoldBackgroundColor: const Color(0xFFF8F8F6)),
    home: const Directionality(textDirection: TextDirection.rtl, child: MerchantGate()),
  );
}

class MerchantGate extends StatelessWidget {
  const MerchantGate({super.key});
  @override
  Widget build(BuildContext context) => StreamBuilder<AuthState>(
    stream: db.auth.onAuthStateChange,
    builder: (context, snapshot) => db.auth.currentSession == null ? const MerchantLogin() : const MerchantHome(),
  );
}

class MerchantLogin extends StatefulWidget {
  const MerchantLogin({super.key});
  @override
  State<MerchantLogin> createState() => _MerchantLoginState();
}

class _MerchantLoginState extends State<MerchantLogin> {
  final email = TextEditingController(), password = TextEditingController();
  bool busy = false;
  String? error;
  @override
  void dispose() { email.dispose(); password.dispose(); super.dispose(); }
  Future<void> submit() async {
    setState(() { busy = true; error = null; });
    try {
      await db.auth.signInWithPassword(email: email.text.trim(), password: password.text);
    } on AuthException catch (e) { if (mounted) setState(() => error = e.message); }
      catch (_) { if (mounted) setState(() => error = 'تعذر الاتصال. حاول مجدداً.'); }
    finally { if (mounted) setState(() => busy = false); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 440), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    const CircleAvatar(radius: 38, backgroundColor: jibRed, child: Text('J', style: TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w900))),
    const SizedBox(height: 18), const Text('JIB · فضاء التاجر', textAlign: TextAlign.center, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
    const Text('سجّل الدخول لإدارة متجرك وطلباتك', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
    const SizedBox(height: 28), TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'البريد الإلكتروني', border: OutlineInputBorder())),
    const SizedBox(height: 12), TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'كلمة المرور', border: OutlineInputBorder())),
    if (error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(error!, style: const TextStyle(color: jibRed))),
    const SizedBox(height: 18), FilledButton(onPressed: busy ? null : submit, style: FilledButton.styleFrom(backgroundColor: jibRed, padding: const EdgeInsets.all(15)), child: Text(busy ? 'يرجى الانتظار...' : 'تسجيل الدخول')),
  ])))));
}

class MerchantHome extends StatefulWidget {
  const MerchantHome({super.key});
  @override
  State<MerchantHome> createState() => _MerchantHomeState();
}

class _MerchantHomeState extends State<MerchantHome> {
  Map<String, dynamic>? store;
  List<Map<String, dynamic>> products = [], orders = [];
  bool loading = true;
  String? error;
  @override
  void initState() { super.initState(); load(); }

  Future<void> load() async {
    setState(() { loading = true; error = null; });
    try {
      final uid = db.auth.currentUser!.id;
      final stores = await db.from('stores').select().eq('owner_id', uid).limit(1);
      if (stores.isNotEmpty) {
        store = Map<String, dynamic>.from(stores.first);
        final sid = store!['id'];
        final p = await db.from('products').select().eq('store_id', sid).order('created_at', ascending: false);
        products = p.map((e) => Map<String, dynamic>.from(e)).toList();
        final o = await db.from('orders').select('id,status,total_mad,created_at,customer_note').eq('store_id', sid).order('created_at', ascending: false).limit(50);
        orders = o.map((e) => Map<String, dynamic>.from(e)).toList();
      } else { store = null; products = []; orders = []; }
    } catch (_) { error = 'تعذر تحميل بيانات المتجر. تأكد من أن حسابك مرتبط بمتجر في JIB.'; }
    if (mounted) setState(() => loading = false);
  }

  Future<void> toggleOpen(bool value) async {
    if (store == null) return;
    try {
      await db.from('stores').update({'is_open': value}).eq('id', store!['id']);
      await load();
    } catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر تحديث حالة المتجر'))); }
  }

  Future<void> editProduct([Map<String, dynamic>? product]) async {
    final name = TextEditingController(text: product?['name']?.toString() ?? '');
    final description = TextEditingController(text: product?['description']?.toString() ?? '');
    final price = TextEditingController(text: product?['price_mad']?.toString() ?? '');
    final ok = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: Text(product == null ? 'إضافة منتج' : 'تعديل المنتج'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, decoration: const InputDecoration(labelText: 'اسم المنتج')),
        TextField(controller: description, decoration: const InputDecoration(labelText: 'الوصف')),
        TextField(controller: price, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'الثمن بالدرهم')),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('حفظ'))],
    ));
    if (ok == true && name.text.trim().isNotEmpty && (double.tryParse(price.text.replaceAll(',', '.')) ?? 0) > 0) {
      final values = {'name': name.text.trim(), 'description': description.text.trim(), 'price_mad': double.parse(price.text.replaceAll(',', '.')), 'is_available': product?['is_available'] ?? true};
      try {
        if (product == null) { values['store_id'] = store!['id']; await db.from('products').insert(values); }
        else { await db.from('products').update(values).eq('id', product['id']); }
        await load();
      } catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر حفظ المنتج. تحقق من صلاحيات المتجر.'))); }
    }
    name.dispose(); description.dispose(); price.dispose();
  }

  Future<void> setAvailable(Map<String, dynamic> p, bool value) async {
    await db.from('products').update({'is_available': value}).eq('id', p['id']);
    await load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('جيب · التاجر', style: TextStyle(fontWeight: FontWeight.w900)), actions: [
      IconButton(onPressed: load, icon: const Icon(Icons.refresh)),
      IconButton(onPressed: () => db.auth.signOut(), icon: const Icon(Icons.logout)),
    ]),
    floatingActionButton: store == null ? null : FloatingActionButton.extended(onPressed: () => editProduct(), backgroundColor: jibRed, foregroundColor: Colors.white, icon: const Icon(Icons.add), label: const Text('منتج جديد')),
    body: loading ? const Center(child: CircularProgressIndicator()) : error != null ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(error!, textAlign: TextAlign.center))) : store == null ? const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('لا يوجد متجر مرتبط بهذا الحساب بعد. اطلب من إدارة JIB ربط حساب التاجر بمتجرك.', textAlign: TextAlign.center))) : RefreshIndicator(onRefresh: load, child: ListView(padding: const EdgeInsets.all(16), children: [
      Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: jibRed, borderRadius: BorderRadius.circular(20)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('متجرك على JIB', style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 6), Text(store!['name']?.toString() ?? 'متجري', style: const TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900)),
        SwitchListTile(contentPadding: EdgeInsets.zero, value: store!['is_open'] == true, onChanged: toggleOpen, title: const Text('المتجر مفتوح لاستقبال الطلبات', style: TextStyle(color: Colors.white)), activeColor: Colors.white, activeTrackColor: Colors.green),
      ])),
      const SizedBox(height: 18), Row(children: [
        Expanded(child: _Metric(title: 'الطلبات', value: '${orders.length}')),
        const SizedBox(width: 10), Expanded(child: _Metric(title: 'المنتجات', value: '${products.length}')),
      ]),
      const SizedBox(height: 20), const Text('الطلبات الأخيرة', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
      if (orders.isEmpty) const Card(child: ListTile(title: Text('لا توجد طلبات بعد'), subtitle: Text('ستظهر طلبات زبنائك هنا.')))
      else ...orders.take(10).map((o) => Card(child: ListTile(leading: const Icon(Icons.receipt_long), title: Text('طلب #${o['id'].toString().substring(0, 8)}'), subtitle: Text('${o['status']} · ${o['created_at'].toString().substring(0, 10)}'), trailing: Text('${o['total_mad']} د.م', style: const TextStyle(fontWeight: FontWeight.bold))))),
      const SizedBox(height: 20), const Text('المنتجات', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
      if (products.isEmpty) const Card(child: ListTile(title: Text('أضف أول منتج لمتجرك'), subtitle: Text('استعمل زر «منتج جديد» أسفل الشاشة.')))
      else ...products.map((p) => Card(child: ListTile(
        leading: const Icon(Icons.inventory_2_outlined), title: Text(p['name'].toString()), subtitle: Text('${p['price_mad']} د.م'),
        trailing: PopupMenuButton<String>(onSelected: (v) { if (v == 'edit') editProduct(p); if (v == 'available') setAvailable(p, !(p['is_available'] == true)); }, itemBuilder: (_) => [
          const PopupMenuItem(value: 'edit', child: Text('تعديل')), PopupMenuItem(value: 'available', child: Text(p['is_available'] == true ? 'إيقاف التوفر' : 'تفعيل التوفر')),
        ]),
      ))),
      const SizedBox(height: 80),
    ])),
  );
}

class _Metric extends StatelessWidget {
  final String title, value;
  const _Metric({required this.title, required this.value});
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title, style: const TextStyle(color: Colors.black54)), const SizedBox(height: 8), Text(value, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
  ])));
}
