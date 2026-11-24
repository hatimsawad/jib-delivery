import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _url = 'https://ldgbyshgcifheditplnn.supabase.co';
const _key = 'sb_publishable_wvNMRZTBFX4viI2ypcdWjQ_YBqgi_TV';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: _url, publishableKey: _key);
  runApp(const JibCourierApp());
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

class JibCourierApp extends StatelessWidget {
  const JibCourierApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'JIB Livreur', debugShowCheckedModeBanner: false,
    theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE31E24), primary: const Color(0xFFE31E24), secondary: const Color(0xFF00843D), tertiary: const Color(0xFF00843D)), scaffoldBackgroundColor: const Color(0xFFF7F8F7), useMaterial3: true),
    home: const CourierHome(),
  );
}

class CourierHome extends StatefulWidget {
  const CourierHome({super.key});
  @override
  State<CourierHome> createState() => _CourierHomeState();
}

class _CourierHomeState extends State<CourierHome> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _fullName = TextEditingController();
  final _phone = TextEditingController();
  bool _register = false;
  String? _notice;
  bool _busy = false;
  bool _onDuty = false;
  String? _error;
  List<Map<String,dynamic>> _assignments = [];
  SupabaseClient get _db => Supabase.instance.client;
  User? get _user => _db.auth.currentUser;

  @override
  void initState() { super.initState(); if (_user != null) _loadTasks(); }

  Future<void> _signIn() async {
    setState(() { _busy = true; _error = null; });
    try {
      await _db.auth.signInWithPassword(email: _email.text.trim(), password: _password.text);
      await _loadTasks();
    } on AuthException catch (e) { setState(() => _error = e.message); }
    catch (e) { setState(() => _error = 'تعذر تسجيل الدخول.'); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _signUp() async {
    if (_fullName.text.trim().length < 2 || _phone.text.trim().length < 8 || _password.text.length < 8) {
      setState(() => _error = 'أكمل الاسم ورقم الهاتف، واجعل كلمة المرور 8 أحرف على الأقل.');
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
          'requested_role': 'courier',
        },
      );
      if (result.session != null) await _db.auth.signOut();
      setState(() {
        _notice = 'تم إنشاء طلب حساب المندوب. أكّد بريدك الإلكتروني، ثم انتظر اعتماد الإدارة قبل تسجيل الدخول.';
        _register = false;
      });
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'تعذر إنشاء الحساب. تحقق من البريد الإلكتروني والاتصال.');
    } finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _loadTasks() async {
    if (_user == null) return;
    setState(() { _busy = true; _error = null; });
    try {
      final profile = await _db.from('courier_profiles').select('is_on_duty')
        .eq('user_id', _user!.id).maybeSingle();
      _onDuty = profile?['is_on_duty'] == true;
      final rows = await _db.from('courier_assignments')
        .select('id,order_id,status,offered_at,orders!inner(id,status,delivery_address,customer_phone,subtotal_mad,delivery_fee_mad,courier_purchase_total_mad,submitted_at,branches(name,address,merchants(name)),order_items(product_name_snapshot,quantity,unit_price_mad,line_total_mad,products(name,brands(name))))')
        .eq('courier_id', _user!.id)
        .inFilter('status', ['offered','accepted'])
        .order('offered_at', ascending: false);
      setState(() => _assignments = List<Map<String,dynamic>>.from(rows));
    } catch (e) { setState(() => _error = 'تعذر تحميل عروض التوصيل. تأكد من تفعيل حساب المندوب.'); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _toggleDuty(bool value) async {
    setState(() { _busy = true; _error = null; });
    try {
      await _db.from('courier_profiles').update({'is_on_duty': value}).eq('user_id', _user!.id);
      setState(() => _onDuty = value);
    } catch (e) { setState(() => _error = 'لم نتمكن من تغيير حالة التوفر.'); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _respond(String id, bool accept) async {
    setState(() { _busy = true; _error = null; });
    try {
      await _db.rpc('courier_respond_to_offer', params: {'p_assignment_id': id, 'p_accept': accept});
      await _loadTasks();
    } catch (e) { setState(() => _error = 'تعذر تسجيل الرد على العرض.'); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _confirmPurchase(String orderId) async {
    final controller = TextEditingController();
    final value = await showDialog<String>(context: context, builder: (dialogContext) => AlertDialog(
      title: const Text('تأكيد شراء المنتجات'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('أدخل المبلغ الإجمالي الذي دفعته فعلياً في المتجر، حسب الفاتورة.'),
        const SizedBox(height: 10),
        TextField(controller: controller, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'تكلفة الشراء بالدرهم', border: OutlineInputBorder())),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
        FilledButton(onPressed: () => Navigator.pop(dialogContext, controller.text.trim()), child: const Text('تأكيد الشراء')),
      ],
    ));
    final amount = num.tryParse(value ?? '');
    controller.dispose();
    if (amount == null || amount < 0) { if (value != null) setState(() => _error = 'أدخل تكلفة شراء صحيحة.'); return; }
    setState(() { _busy = true; _error = null; });
    try {
      await _db.rpc('courier_confirm_purchase', params: {'p_order_id': orderId, 'p_purchase_total_mad': amount});
      await _loadTasks();
    } catch (e) { setState(() => _error = 'تعذر تسجيل شراء المنتجات. تحقق من حالة الطلب والمبلغ.'); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _confirmDelivery(String orderId) async {
    final controller = TextEditingController();
    final value = await showDialog<String>(context: context, builder: (dialogContext) => AlertDialog(
      title: const Text('تأكيد التسليم والتحصيل'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('أدخل كامل المبلغ النقدي الذي استلمته من الزبون.'),
        const SizedBox(height: 10),
        TextField(controller: controller, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'المبلغ المحصل بالدرهم', border: OutlineInputBorder())),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
        FilledButton(onPressed: () => Navigator.pop(dialogContext, controller.text.trim()), child: const Text('تأكيد التسليم')),
      ],
    ));
    final amount = num.tryParse(value ?? '');
    controller.dispose();
    if (amount == null || amount < 0) { if (value != null) setState(() => _error = 'أدخل المبلغ المحصل بشكل صحيح.'); return; }
    setState(() { _busy = true; _error = null; });
    try {
      await _db.rpc('courier_complete_delivery', params: {'p_order_id': orderId, 'p_cash_collected_mad': amount});
      await _loadTasks();
    } catch (e) { setState(() => _error = 'تعذر تأكيد التسليم والتحصيل. تحقق من تسجيل تكلفة الشراء أولاً.'); }
    finally { if (mounted) setState(() => _busy = false); }
  }
  Future<void> _advance(String orderId, String action) async {
    setState(() { _busy = true; _error = null; });
    try {
      await _db.rpc('courier_update_order', params: {'p_order_id': orderId, 'p_action': action});
      await _loadTasks();
    } catch (e) { setState(() => _error = 'تعذر تحديث مرحلة التوصيل.'); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _signOut() async {
    await _db.auth.signOut();
    setState(() { _assignments = []; _onDuty = false; _error = null; });
  }

  @override
  void dispose() { _email.dispose(); _password.dispose(); _fullName.dispose(); _phone.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Row(mainAxisSize: MainAxisSize.min, children: [_JibMark(size: 34), SizedBox(width: 8), Text('JIB Livreur')]), actions: [
        if (_user != null) IconButton(onPressed: _loadTasks, icon: const Icon(Icons.refresh)),
        if (_user != null) IconButton(onPressed: _signOut, icon: const Icon(Icons.logout)),
      ]),
      body: _user == null ? _login() : _workspace(),
    ),
  );

  Widget _login() => ListView(padding: const EdgeInsets.all(22), children: [
    const Text('مساحة المندوب', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
    const SizedBox(height: 8),
    Text(_register ? 'أنشئ حساب مندوب. لن تستقبل طلبات حتى تعتمد الإدارة حسابك.' : 'سجّل الدخول بحساب مندوب اعتمده مدير JIB.'),
    const SizedBox(height: 20),
    if (_register) ...[
      TextField(controller: _fullName, decoration: const InputDecoration(labelText: 'الاسم الكامل')),
      const SizedBox(height: 12),
      TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'رقم الهاتف')),
      const SizedBox(height: 12),
    ],
    TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'البريد الإلكتروني')),
    const SizedBox(height: 12),
    TextField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'كلمة المرور (8 أحرف على الأقل)')),
    const SizedBox(height: 16),
    FilledButton(onPressed: _busy ? null : (_register ? _signUp : _signIn),
      child: Text(_busy ? 'جارٍ التنفيذ...' : (_register ? 'إنشاء طلب حساب مندوب' : 'تسجيل الدخول'))),
    TextButton(onPressed: _busy ? null : () => setState(() { _register = !_register; _error = null; _notice = null; }),
      child: Text(_register ? 'لدي حساب بالفعل — تسجيل الدخول' : 'إنشاء حساب مندوب جديد')),
    if (_notice != null) Card(color: const Color(0xFFE8F2EA), child: Padding(padding: const EdgeInsets.all(12), child: Text(_notice!, style: const TextStyle(color: Color(0xFF006B36))))),
    if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
  ]);

  Widget _workspace() => RefreshIndicator(
    onRefresh: _loadTasks,
    child: ListView(padding: const EdgeInsets.all(16), children: [
      const Text('حالة العمل', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('متاح لاستقبال عروض التوصيل'),
        subtitle: const Text('لن يتم إسناد عروض جديدة عند إيقاف التوفر.'),
        value: _onDuty,
        onChanged: _busy ? null : _toggleDuty,
      ),
      if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
      const SizedBox(height: 12),
      const Text('العروض والمهام', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      if (_assignments.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('لا توجد عروض أو مهام حالياً.'))),
      ..._assignments.map((a) {
        final order = Map<String,dynamic>.from(a['orders'] as Map);
        final status = order['status'] as String;
        final branch = order['branches'] as Map<String,dynamic>?;
        final assignmentStatus = a['status'] as String;
        final orderId = a['order_id'] as String;
        final orderItems = order['order_items'] as List<dynamic>? ?? [];
        final actions = <Widget>[];
        if (assignmentStatus == 'offered') {
          actions.add(FilledButton(onPressed: _busy ? null : () => _respond(a['id'] as String,true), child: const Text('قبول العرض')));
          actions.add(OutlinedButton(onPressed: _busy ? null : () => _respond(a['id'] as String,false), child: const Text('رفض')));
        } else if (status == 'courier_accepted') {
          actions.add(FilledButton(onPressed: _busy ? null : () => _confirmPurchase(orderId), child: const Text('تأكيد الشراء وتسجيل التكلفة')));
        } else if (status == 'picked_up') {
          actions.add(FilledButton(onPressed: _busy ? null : () => _advance(orderId,'en_route'), child: const Text('بدء التوصيل')));
        } else if (status == 'en_route') {
          actions.add(FilledButton(onPressed: _busy ? null : () => _confirmDelivery(orderId), child: const Text('تأكيد التسليم والتحصيل')));
        }
        return Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('طلب #${orderId.substring(0,8)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('المتجر: ${(branch?['merchants'] as Map?)?['name'] ?? branch?['name'] ?? 'الفرع'} — ${branch?['address'] ?? ''}'),
            Text('عنوان التسليم: ${order['delivery_address']}'),
            Text('هاتف الزبون: ${order['customer_phone']}'),
            Text('قيمة المنتجات في JIB: ${order['subtotal_mad']} درهم'),
            Text('رسوم التوصيل: ${order['delivery_fee_mad'] ?? 'بانتظار تحديد الإدارة'} درهم'),
            Text('الحالة: $status'),
            if (orderItems.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('العلامة التجارية والمنتجات المطلوبة:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...orderItems.map((item) {
                final product = item['products'] as Map?;
                final brand = product?['brands'] as Map?;
                final brandName = brand?['name'] as String? ?? 'علامة غير محددة';
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('$brandName — ${item['product_name_snapshot']} × ${item['quantity']} • ${item['line_total_mad']} درهم'),
                );
              }),
            ],
            if (order['courier_purchase_total_mad'] != null) Text('تكلفة الشراء المسجلة: ${order['courier_purchase_total_mad']} درهم'),
            Text('مضى على الطلب: ${DateTime.now().difference(DateTime.parse(order['submitted_at'] as String)).inMinutes} دقيقة'),
            Wrap(spacing: 8, children: actions),
          ],
        )));
      }),
      const SizedBox(height: 12),
      const Text('مشاركة الموقع غير مفعلة في هذه النسخة. لن يتم تتبع موقعك دون موافقتك الصريحة وإظهار إشعار دائم أثناء التتبع.',
        style: TextStyle(color: Colors.blueGrey)),
    ]),
  );
}
