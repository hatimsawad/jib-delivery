import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _url = 'https://ldgbyshgcifheditplnn.supabase.co';
const _key = 'sb_publishable_wvNMRZTBFX4viI2ypcdWjQ_YBqgi_TV';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: _url, publishableKey: _key);
  runApp(const JibMerchantApp());
}

class _JibMark extends StatelessWidget {
  const _JibMark({this.size = 48});
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      color: const Color(0xFFE31E24),
      borderRadius: BorderRadius.circular(size * .23),
      border: Border.all(color: const Color(0xFF00843D), width: 2),
    ),
    child: Stack(alignment: Alignment.center, children: [
      Positioned(top: size * .01, right: size * .02,
        child: Icon(Icons.star, color: const Color(0xFFD7B45A), size: size * .24)),
      Positioned(top: size * .09,
        child: Icon(Icons.delivery_dining, color: Colors.white, size: size * .62)),
      Positioned(bottom: size * .015,
        child: Text('JIB', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: size * .19, height: 1))),
    ]),
  );
}

class JibMerchantApp extends StatelessWidget {
  const JibMerchantApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'JIB Partenaire', debugShowCheckedModeBanner: false,
    theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE31E24), primary: const Color(0xFFE31E24), secondary: const Color(0xFF00843D), tertiary: const Color(0xFF00843D)), scaffoldBackgroundColor: const Color(0xFFF7F8F7), useMaterial3: true),
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
  final _fullName = TextEditingController();
  final _phone = TextEditingController();
  final _businessName = TextEditingController();
  bool _register = false;
  String? _notice;
  final _eta = TextEditingController();
  final _productPrice = TextEditingController();
  List<Map<String,dynamic>> _branches = [];
  List<Map<String,dynamic>> _catalogProducts = [];
  List<Map<String,dynamic>> _branchProducts = [];
  String? _selectedBranchId;
  String? _selectedProductId;
  bool _productAvailable = true;
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

  Future<void> _signUp() async {
    if (_fullName.text.trim().length < 2 || _businessName.text.trim().length < 2 ||
        _phone.text.trim().length < 8 || _password.text.length < 8) {
      setState(() => _error = 'أكمل الاسم واسم المتجر ورقم الهاتف، واجعل كلمة المرور 8 أحرف على الأقل.');
      return;
    }
    setState(() { _busy = true; _error = null; _notice = null; });
    try {
      final result = await _db.auth.signUp(
        email: _email.text.trim(),
        password: _password.text,
        data: {
          'full_name': _fullName.text.trim(),
          'phone': _phone.text.trim(),
          'requested_role': 'merchant',
          'business_name': _businessName.text.trim(),
        },
      );
      if (result.session != null) await _db.auth.signOut();
      setState(() {
        _notice = 'تم إنشاء طلب حساب التاجر. أكّد بريدك الإلكتروني، ثم انتظر اعتماد الإدارة قبل تسجيل الدخول.';
        _register = false;
      });
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'تعذر إنشاء الحساب. تحقق من البريد الإلكتروني والاتصال.');
    } finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _loadWorkspace() async {
    if (_user == null) return;
    setState(() { _busy = true; _error = null; });
    try {
      final merchant = await _db.from('merchants').select('id,name')
        .eq('owner_user_id', _user!.id).maybeSingle();
      if (merchant == null) {
        setState(() { _merchant = null; _orders = []; });
        return;
      }
      final branches = await _db.from('branches').select('id,name,address,is_active')
        .eq('merchant_id', merchant['id']).order('name');
      final catalog = await _db.from('products').select('id,name,reference_price_mad')
        .eq('is_active', true).order('name');
      final ids = (branches as List).map((b) => b['id'] as String).toList();
      List<Map<String, dynamic>> orders = [];
      if (ids.isNotEmpty) {
        final rows = await _db.from('orders')
          .select('id,status,submitted_at,customer_phone,delivery_address,subtotal_mad,eta_minutes,merchant_accepted_at,preparation_started_at,preparation_completed_at,order_items(product_name_snapshot,quantity,unit_price_mad,line_total_mad)')
          .inFilter('branch_id', ids).order('submitted_at', ascending: false);
        orders = List<Map<String, dynamic>>.from(rows);
      }
      final branchList = List<Map<String,dynamic>>.from(branches);
      final productList = List<Map<String,dynamic>>.from(catalog);
      final selected = _selectedBranchId ?? (branchList.isEmpty ? null : branchList.first['id'] as String);
      List<Map<String,dynamic>> inventory = [];
      if (selected != null) {
        final rows = await _db.from('branch_products')
          .select('id,product_id,price_mad,availability,products!inner(name)')
          .eq('branch_id', selected).order('updated_at', ascending: false);
        inventory = List<Map<String,dynamic>>.from(rows);
      }
      setState(() {
        _merchant = merchant; _orders = orders; _branches = branchList;
        _catalogProducts = productList; _selectedBranchId = selected; _branchProducts = inventory;
        if (_selectedProductId == null && productList.isNotEmpty) {
          _selectedProductId = productList.first['id'] as String;
        }
      });
    } catch (e) {
      setState(() => _error = 'تعذر تحميل طلبات المتجر. تحقق من صلاحيات الحساب.');
    } finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _selectBranch(String? branchId) async {
    if (branchId == null) return;
    setState(() { _selectedBranchId = branchId; _busy = true; _error = null; });
    try {
      final rows = await _db.from('branch_products')
        .select('id,product_id,price_mad,availability,products!inner(name)')
        .eq('branch_id', branchId).order('updated_at', ascending: false);
      setState(() => _branchProducts = List<Map<String,dynamic>>.from(rows));
    } catch (_) { setState(() => _error = 'تعذر تحميل قائمة منتجات الفرع.'); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _saveProduct() async {
    if (_selectedBranchId == null || _selectedProductId == null) return;
    final price = num.tryParse(_productPrice.text.trim());
    if (price == null || price < 0) { setState(() => _error = 'أدخل سعراً صحيحاً بالدرهم.'); return; }
    setState(() { _busy = true; _error = null; });
    try {
      await _db.rpc('merchant_set_branch_product', params: {
        'p_branch_id': _selectedBranchId,
        'p_product_id': _selectedProductId,
        'p_price_mad': price,
        'p_available': _productAvailable,
      });
      await _selectBranch(_selectedBranchId);
    } catch (e) { setState(() => _error = 'تعذر حفظ سعر وتوفر المنتج.'); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _advance(String orderId, String action, [int? etaMinutes]) async {
    setState(() { _busy = true; _error = null; });
    try {
      await _db.rpc('merchant_update_order', params: {
        'p_order_id': orderId, 'p_action': action, 'p_reason': null, 'p_eta_minutes': etaMinutes,
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
  void dispose() { _email.dispose(); _password.dispose(); _fullName.dispose(); _phone.dispose(); _businessName.dispose(); _eta.dispose(); _productPrice.dispose(); super.dispose(); }

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
      appBar: AppBar(title: const Row(mainAxisSize: MainAxisSize.min, children: [_JibMark(size: 34), SizedBox(width: 8), Text('JIB Partenaire')]), actions: [
        if (_user != null) IconButton(onPressed: _loadWorkspace, icon: const Icon(Icons.refresh)),
        if (_user != null) IconButton(onPressed: _signOut, icon: const Icon(Icons.logout)),
      ]),
      body: _user == null ? _login() : _workspace(),
    ),
  );

  Widget _login() => ListView(padding: const EdgeInsets.all(22), children: [
    const Text('مساحة التاجر', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
    const SizedBox(height: 8),
    Text(_register ? 'أنشئ حساب متجرك. سيظل الحساب غير نشط حتى يراجعه مدير JIB.' : 'سجّل الدخول بحساب تاجر اعتمده مدير JIB.'),
    const SizedBox(height: 20),
    if (_register) ...[
      TextField(controller: _fullName, decoration: const InputDecoration(labelText: 'الاسم الكامل')),
      const SizedBox(height: 12),
      TextField(controller: _businessName, decoration: const InputDecoration(labelText: 'اسم المتجر أو الشركة')),
      const SizedBox(height: 12),
      TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'رقم الهاتف')),
      const SizedBox(height: 12),
    ],
    TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'البريد الإلكتروني')),
    const SizedBox(height: 12),
    TextField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'كلمة المرور (8 أحرف على الأقل)')),
    const SizedBox(height: 16),
    FilledButton(onPressed: _busy ? null : (_register ? _signUp : _signIn),
      child: Text(_busy ? 'جارٍ التنفيذ...' : (_register ? 'إنشاء طلب حساب تاجر' : 'تسجيل الدخول'))),
    TextButton(onPressed: _busy ? null : () => setState(() { _register = !_register; _error = null; _notice = null; }),
      child: Text(_register ? 'لدي حساب بالفعل — تسجيل الدخول' : 'إنشاء حساب تاجر جديد')),
    if (_notice != null) Card(color: const Color(0xFFE8F2EA), child: Padding(padding: const EdgeInsets.all(12), child: Text(_notice!, style: const TextStyle(color: Color(0xFF006B36))))),
    if (_error != null) _errorPanel(),
  ]);

  Widget _workspace() {
    if (_busy && _merchant == null) return const Center(child: CircularProgressIndicator());
    if (_merchant == null) {
      return ListView(padding: const EdgeInsets.all(22), children: [
      const Icon(Icons.store_mall_directory_outlined, size: 52),
      const SizedBox(height: 12),
      const Text('هذا الحساب غير مرتبط بسجل تاجر في JIB بعد.', textAlign: TextAlign.center),
      const SizedBox(height: 8),
      const Text('يجب على الإدارة اعتماد هذا الحساب كتاجر وإنشاء سجله أولاً.', textAlign: TextAlign.center),
      if (_error != null) _errorPanel(),
      ]);
    }
    return RefreshIndicator(onRefresh: _loadWorkspace, child: ListView(padding: const EdgeInsets.all(16), children: [
      Text('مرحباً، ${_merchant!['name']}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Text('الطلبات: ${_orders.length}'),
      const SizedBox(height: 18),
      const Text('الفروع والمنتجات', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
      if (_branches.isEmpty)
        const Card(child: Padding(padding: EdgeInsets.all(14), child: Text('لم تنشئ الإدارة فرعاً لهذا المتجر بعد.')))
      else ...[
        DropdownButtonFormField<String>(
          initialValue: _selectedBranchId,
          decoration: const InputDecoration(labelText: 'اختر الفرع', border: OutlineInputBorder()),
          items: _branches.map((b) => DropdownMenuItem<String>(
            value: b['id'] as String,
            child: Text('${b['name']} ${b['is_active'] == true ? '— نشط' : '— غير منشور'}'),
          )).toList(),
          onChanged: _busy ? null : _selectBranch,
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: _selectedProductId,
          decoration: const InputDecoration(labelText: 'اختر منتجاً من كتالوج JIB', border: OutlineInputBorder()),
          items: _catalogProducts.map((p) => DropdownMenuItem<String>(
            value: p['id'] as String, child: Text(p['name'] as String),
          )).toList(),
          onChanged: (value) {
            setState(() {
              _selectedProductId = value;
              final matches = _catalogProducts.where((p) => p['id'] == value);
              final product = matches.isEmpty ? null : matches.first;
              final reference = product?['reference_price_mad'];
              _productPrice.text = reference == null ? '' : reference.toString();
            });
          },
        ),
        const SizedBox(height: 10),
        TextField(controller: _productPrice, keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'سعر الفرع بالدرهم (إلزامي)', border: OutlineInputBorder())),
        SwitchListTile(
          contentPadding: EdgeInsets.zero, title: const Text('المنتج متوفر للبيع'),
          value: _productAvailable, onChanged: (value) => setState(() => _productAvailable = value),
        ),
        FilledButton(onPressed: _busy ? null : _saveProduct, child: const Text('حفظ السعر والتوفر')),
        const SizedBox(height: 8),
        ..._branchProducts.map((row) {
          final product = Map<String,dynamic>.from(row['products'] as Map);
          return ListTile(
            dense: true, title: Text(product['name'] as String),
            subtitle: Text('${row['price_mad'] ?? 'بدون سعر'} درهم • ${row['availability'] == 'available' ? 'متوفر' : 'غير متوفر'}'),
            trailing: Icon(row['availability'] == 'available' ? Icons.check_circle : Icons.pause_circle_outline),
          );
        }),
      ],
      const Divider(height: 28),
      if (_error != null) _errorPanel(),
      if (_orders.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('لا توجد طلبات حالياً.'))),
      ..._orders.map((o) {
        final status = o['status'] as String;
        final actions = <Widget>[];
        if (status == 'customer_submitted') {
          actions.add(FilledButton(onPressed: _busy ? null : () => _advance(o['id'] as String, 'accept', int.tryParse(_eta.text.trim())), child: const Text('قبول الطلب')));
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
          Text('المجموع: ${o['subtotal_mad']} درهم'),
          if (status == 'customer_submitted')
            TextField(controller: _eta, keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'الوقت المتوقع للتحضير والتجهيز بالدقائق (اختياري)')),
          ...((o['order_items'] as List<dynamic>? ?? []).map((item) {
            final line = Map<String,dynamic>.from(item as Map);
            return Padding(padding: const EdgeInsets.only(top: 5),
              child: Text('• ${line['product_name_snapshot']} × ${line['quantity']} — ${line['line_total_mad']} درهم'));
          })),
          Text('مضى على إرسال الطلب: ${DateTime.now().difference(DateTime.parse(o['submitted_at'] as String)).inMinutes} دقيقة',
            style: const TextStyle(color: Colors.blueGrey)),
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
