import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _url = 'https://ldgbyshgcifheditplnn.supabase.co';
const _key = 'sb_publishable_wvNMRZTBFX4viI2ypcdWjQ_YBqgi_TV';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: _url, publishableKey: _key);
  runApp(const JibMerchantApp());
}

class JibMerchantApp extends StatelessWidget {
  const JibMerchantApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'JIB Partenaire', debugShowCheckedModeBanner: false,
    theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF155E75)), useMaterial3: true),
    home: const MerchantHome(),
  );
}

class MerchantHome extends StatefulWidget {
  const MerchantHome({super.key});
  @override
  State<MerchantHome> createState() => _MerchantHomeState();
}

class _MerchantHomeState extends State<MerchantHome> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;
  Map<String, dynamic>? _merchant;
  List<Map<String, dynamic>> _orders = [];

  SupabaseClient get _db => Supabase.instance.client;
  User? get _user => _db.auth.currentUser;

  @override
  void initState() {
    super.initState();
    if (_user != null) _loadWorkspace();
  }

  Future<void> _signIn() async {
    setState(() { _busy = true; _error = null; });
    try {
      await _db.auth.signInWithPassword(email: _email.text.trim(), password: _password.text);
      await _loadWorkspace();
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'تعذر تسجيل الدخول أو تحميل الحساب.');
    } finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _loadWorkspace() async {
    if (_user == null) return;
    setState(() { _busy = true; _error = null; });
    try {
      final merchant = await _db.from('merchants').select('id,name')
        .eq('owner_user_id', _user!.id).eq('is_active', true).maybeSingle();
      if (merchant == null) {
        setState(() { _merchant = null; _orders = []; });
        return;
      }
      final branches = await _db.from('branches').select('id,name')
        .eq('merchant_id', merchant['id']).eq('is_active', true);
      final ids = (branches as List).map((b) => b['id'] as String).toList();
      List<Map<String, dynamic>> orders = [];
      if (ids.isNotEmpty) {
        final rows = await _db.from('orders')
          .select('id,status,submitted_at,customer_phone,delivery_address,subtotal_mad,eta_minutes')
          .inFilter('branch_id', ids).order('submitted_at', ascending: false);
        orders = List<Map<String, dynamic>>.from(rows);
      }
      setState(() { _merchant = merchant; _orders = orders; });
    } catch (e) {
      setState(() => _error = 'تعذر تحميل طلبات المتجر. تحقق من صلاحيات الحساب.');
    } finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _advance(String orderId, String action) async {
    setState(() { _busy = true; _error = null; });
    try {
      await _db.rpc('merchant_update_order', params: {
        'p_order_id': orderId, 'p_action': action, 'p_reason': null, 'p_eta_minutes': null,
      });
      await _loadWorkspace();
    } catch (e) {
      setState(() => _error = 'لم يتم تحديث حالة الطلب. قد تكون حالته تغيرت بالفعل.');
    } finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _signOut() async {
    await _db.auth.signOut();
    setState(() { _merchant = null; _orders = []; _error = null; });
  }

  @override
  void dispose() { _email.dispose(); _password.dispose(); super.dispose(); }

  String _status(String value) => switch (value) {
    'customer_submitted' => 'طلب جديد',
    'merchant_accepted' => 'تم القبول',
    'preparing' => 'قيد التحضير',
    'ready_for_pickup' => 'جاهز للاستلام',
    'courier_offered' => 'بانتظار المندوب',
    'courier_accepted' => 'المندوب قبل الطلب',
    'picked_up' => 'تم الاستلام',
    'en_route' => 'في الطريق',
    'delivered' => 'تم التسليم',
    'merchant_rejected' => 'مرفوض',
    'cancelled' => 'ملغى',
    _ => value,
  };

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('JIB Partenaire'), actions: [
        if (_user != null) IconButton(onPressed: _loadWorkspace, icon: const Icon(Icons.refresh)),
        if (_user != null) IconButton(onPressed: _signOut, icon: const Icon(Icons.logout)),
      ]),
      body: _user == null ? _login() : _workspace(),
    ),
  );

  Widget _login() => ListView(padding: const EdgeInsets.all(22), children: [
    const Text('مساحة التاجر', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
    const SizedBox(height: 8),
    const Text('سجّل الدخول بحساب تاجر اعتمده مدير JIB.'),
    const SizedBox(height: 20),
    TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'البريد الإلكتروني')),
    const SizedBox(height: 12),
    TextField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'كلمة المرور')),
    const SizedBox(height: 16),
    FilledButton(onPressed: _busy ? null : _signIn, child: Text(_busy ? 'جارٍ الدخول...' : 'تسجيل الدخول')),
    if (_error != null) _errorPanel(),
  ]);

  Widget _workspace() {
    if (_busy && _merchant == null) return const Center(child: CircularProgressIndicator());
    if (_merchant == null) return ListView(padding: const EdgeInsets.all(22), children: [
      const Icon(Icons.store_mall_directory_outlined, size: 52),
      const SizedBox(height: 12),
      const Text('هذا الحساب غير مرتبط بمتجر نشط في JIB بعد.', textAlign: TextAlign.center),
      const SizedBox(height: 8),
      const Text('يجب على الإدارة اعتماد التاجر وإضافة فرعه قبل استقبال الطلبات.', textAlign: TextAlign.center),
      if (_error != null) _errorPanel(),
    ]);
    return RefreshIndicator(onRefresh: _loadWorkspace, child: ListView(padding: const EdgeInsets.all(16), children: [
      Text('مرحباً، ${_merchant!['name']}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Text('الطلبات: ${_orders.length}'),
      if (_error != null) _errorPanel(),
      if (_orders.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('لا توجد طلبات حالياً.'))),
      ..._orders.map((o) {
        final status = o['status'] as String;
        final actions = <Widget>[];
        if (status == 'customer_submitted') {
          actions.add(FilledButton(onPressed: _busy ? null : () => _advance(o['id'] as String, 'accept'), child: const Text('قبول الطلب')));
          actions.add(OutlinedButton(onPressed: _busy ? null : () => _advance(o['id'] as String, 'reject'), child: const Text('رفض')));
        } else if (status == 'merchant_accepted') {
          actions.add(FilledButton(onPressed: _busy ? null : () => _advance(o['id'] as String, 'start_preparing'), child: const Text('بدء التحضير')));
        } else if (status == 'preparing') {
          actions.add(FilledButton(onPressed: _busy ? null : () => _advance(o['id'] as String, 'mark_ready'), child: const Text('الطلب جاهز')));
        }
        return Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('طلب #${(o['id'] as String).substring(0,8)}', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('الحالة: ${_status(status)}'),
          Text('الهاتف: ${o['customer_phone']}'),
          Text('العنوان: ${o['delivery_address']}'),
          Text('المجموع المرجعي للمنتجات: ${o['subtotal_mad']} درهم'),
          if (actions.isNotEmpty) Wrap(spacing: 8, children: actions),
        ])));
      }),
    ]));
  }

  Widget _errorPanel() => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Text(_error!, style: const TextStyle(color: Colors.red)),
  );
}
