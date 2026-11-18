import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const green = Color(0xFF00843D);
const red = Color(0xFFE31E24);
const supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://emvleaghjsmzjmzgguvu.supabase.co');
const supabaseKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY', defaultValue: 'sb_publishable_6rD4poWuBH0TzK2HBFQFTg_4wOFnsX6');

String networkMessage(Object e) {
  final detail = e.toString().toLowerCase();
  if (e is SocketException ||
      detail.contains('failed host lookup') ||
      detail.contains('socketexception') ||
      detail.contains('no address associated with hostname') ||
      detail.contains('name or service not known')) {
    return 'تعذر على هاتفك العثور على خادم Supabase (خطأ DNS). بدّل بين Wi‑Fi وبيانات الهاتف، وأوقف VPN أو مانع الإعلانات، واجعل Private DNS في Android على تلقائي ثم أعد المحاولة.';
  }
  if (e is TimeoutException || detail.contains('timed out') || detail.contains('timeout')) {
    return 'انتهت مهلة الاتصال بخادم JIB. تحقق من الإنترنت وحاول مجدداً.';
  }
  if (detail.contains('connection refused') || detail.contains('network is unreachable')) {
    return 'الشبكة لا تسمح بالاتصال بخدمة JIB. جرّب شبكة أخرى ثم أعد المحاولة.';
  }
  return e.toString();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String? startupError;
  try {
    await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseKey);
  } catch (e) {
    startupError = networkMessage(e);
  }
  runApp(CourierApp(startupError: startupError));
}

final db = Supabase.instance.client;

class CourierApp extends StatelessWidget {
  final String? startupError;
  const CourierApp({super.key, this.startupError});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'JIB · المندوب',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: red, primary: red, surface: Colors.white)
          .copyWith(onSurface: const Color(0xFF19191C)),
      scaffoldBackgroundColor: const Color(0xFFF7F5F2),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF7F5F2),
        foregroundColor: Color(0xFF19191C),
        elevation: 0,
        titleTextStyle: TextStyle(color: Color(0xFF19191C), fontSize: 19, fontWeight: FontWeight.w900),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: Color(0xFFECE8E3)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE9E4DE))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE9E4DE))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: red, width: 1.5)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: red,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    ),
    home: Directionality(
      textDirection: TextDirection.rtl,
      child: startupError == null ? const AuthGate() : StartupError(message: startupError!),
    ),
  );
}

class StartupError extends StatelessWidget {
  final String message;
  const StartupError({super.key, required this.message});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.cloud_off, color: red, size: 52),
        const SizedBox(height: 12),
        const Text('تعذر الاتصال بخدمة JIB', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        Text(message, textAlign: TextAlign.center),
      ]),
    )),
  );
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) => StreamBuilder<AuthState>(
    stream: db.auth.onAuthStateChange,
    builder: (context, snapshot) => db.auth.currentSession == null ? const CourierLogin() : const CourierHome(),
  );
}

class CourierLogin extends StatefulWidget {
  const CourierLogin({super.key});
  @override
  State<CourierLogin> createState() => _CourierLoginState();
}

class _CourierLoginState extends State<CourierLogin> {
  final name = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  bool registering = false, busy = false, showPassword = false;
  String? error, notice;

  @override
  void dispose() {
    name.dispose(); phone.dispose(); email.dispose(); password.dispose(); super.dispose();
  }

  Future<void> enroll() async {
    final user = db.auth.currentUser;
    if (user == null) throw const AuthException('يجب تسجيل الدخول أولاً');
    final meta = user.userMetadata ?? {};
    await db.rpc('register_courier_profile', params: {
      'p_full_name': name.text.trim().isNotEmpty ? name.text.trim() : (meta['full_name']?.toString() ?? ''),
      'p_phone': phone.text.trim().isNotEmpty ? phone.text.trim() : (meta['phone']?.toString() ?? ''),
    });
  }

  Future<void> submit() async {
    if (email.text.trim().isEmpty || password.text.length < 8) {
      setState(() => error = 'أدخل البريد وكلمة المرور (8 أحرف على الأقل).'); return;
    }
    if (registering && (name.text.trim().isEmpty || phone.text.trim().isEmpty)) {
      setState(() => error = 'أدخل الاسم الكامل ورقم الهاتف.'); return;
    }
    setState(() { busy = true; error = null; notice = null; });
    try {
      if (registering) {
        final result = await db.auth.signUp(
          email: email.text.trim(),
          password: password.text,
          data: {'full_name': name.text.trim(), 'phone': phone.text.trim()},
        );
        if (result.session == null) {
          if (mounted) setState(() {
            notice = 'تم إنشاء الحساب. أكّد بريدك الإلكتروني ثم سجّل الدخول لإرسال طلب اعتماد المندوب.';
            registering = false;
          });
          return;
        }
      } else {
        await db.auth.signInWithPassword(email: email.text.trim(), password: password.text);
      }
      await enroll();
    } on AuthException catch (e) {
      if (mounted) setState(() => error = e.message);
    } on PostgrestException catch (e) {
      if (mounted) setState(() => error = e.message);
    } on SocketException catch (e) {
      if (mounted) setState(() => error = networkMessage(e));
    } on TimeoutException catch (e) {
      if (mounted) setState(() => error = networkMessage(e));
    } catch (e) {
      if (mounted) setState(() => error = 'تعذر إتمام التسجيل: ' + e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget field(TextEditingController controller, String label, {TextInputType? type, bool secret = false}) =>
    Padding(
      padding: const EdgeInsets.only(top: 12),
      child: TextField(
        controller: controller, keyboardType: type, obscureText: secret,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      ),
    );

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(child: Center(child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [Color(0xFFEF3A40), Color(0xFF9F1118)],
              ),
              borderRadius: BorderRadius.circular(26),
              boxShadow: const [BoxShadow(color: Color(0x26E31E24), blurRadius: 24, offset: Offset(0, 10))],
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.delivery_dining_rounded, color: Colors.white, size: 43),
          ),
          const SizedBox(height: 18),
          const Text('جيب JIB · المندوب', textAlign: TextAlign.center, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
          const Text('JIB SIGNATURE  /  COURIER', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF82766F), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.1)),
          const SizedBox(height: 6),
          const Text('توصيلاتك بوضوح، خطوة بخطوة', textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Text(registering ? 'إنشاء حساب مندوب' : 'تسجيل الدخول', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          if (registering) ...[
            field(name, 'الاسم الكامل'),
            field(phone, 'رقم الهاتف', type: TextInputType.phone),
          ],
          field(email, 'البريد الإلكتروني', type: TextInputType.emailAddress),
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: TextField(
              controller: password, obscureText: !showPassword,
              decoration: InputDecoration(
                labelText: 'كلمة المرور (8 أحرف على الأقل)',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => showPassword = !showPassword),
                  icon: Icon(showPassword ? Icons.visibility_off : Icons.visibility),
                ),
              ),
            ),
          ),
          if (error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(error!, style: const TextStyle(color: red))),
          if (notice != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(notice!, style: const TextStyle(color: green))),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: busy ? null : submit,
            style: FilledButton.styleFrom(backgroundColor: green, padding: const EdgeInsets.all(15)),
            child: Text(busy ? 'يرجى الانتظار...' : registering ? 'إنشاء حساب المندوب' : 'تسجيل الدخول'),
          ),
          TextButton(
            onPressed: busy ? null : () => setState(() { registering = !registering; error = null; notice = null; }),
            child: Text(registering ? 'لديك حساب؟ سجّل الدخول' : 'مستخدم جديد؟ أنشئ حساب مندوب'),
          ),
          const Text('بعد التسجيل، يجب اعتماد الحساب من إدارة JIB قبل استلام الطلبات.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54, fontSize: 12)),
        ]),
      ),
    ))),
  );
}

class CourierHome extends StatefulWidget {
  const CourierHome({super.key});
  @override
  State<CourierHome> createState() => _CourierHomeState();
}

class _CourierHomeState extends State<CourierHome> {
  bool loading = true, active = false;
  String? error;
  List<Map<String, dynamic>> orders = [];

  @override
  void initState() { super.initState(); load(); }

  void notify(String message) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> load() async {
    setState(() { loading = true; error = null; });
    try {
      final user = db.auth.currentUser;
      if (user == null) throw const AuthException('انتهت الجلسة. سجّل الدخول مجدداً.');
      var profile = await db.from('courier_profiles').select('is_active').eq('user_id', user.id).maybeSingle();
      if (profile == null) {
        final meta = user.userMetadata ?? {};
        await db.rpc('register_courier_profile', params: {
          'p_full_name': meta['full_name']?.toString() ?? '',
          'p_phone': meta['phone']?.toString() ?? '',
        });
        profile = await db.from('courier_profiles').select('is_active').eq('user_id', user.id).maybeSingle();
      }
      if (profile == null) throw const AuthException('تعذر إنشاء ملف المندوب.');
      active = profile['is_active'] == true;
      if (active) {
        final rows = await db.rpc('courier_dashboard');
        orders = (rows as List<dynamic>).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        try {
          final rawTimelines = await db.rpc('jib_order_timeline');
          final timelines = <String, Map<String, dynamic>>{};
          for (final raw in rawTimelines as List<dynamic>) {
            final item = Map<String, dynamic>.from(raw as Map);
            timelines[item['order_id'].toString()] = item;
          }
          for (final order in orders) {
            order['timeline'] = timelines[order['order_id'].toString()];
          }
        } catch (_) {
          // Courier actions remain available if the optional timeline query is unavailable.
        }
      } else {
        orders = [];
      }
    } on SocketException catch (e) {
      error = networkMessage(e);
    } on TimeoutException catch (e) {
      error = networkMessage(e);
    } on AuthException catch (e) {
      error = e.message;
    } on PostgrestException catch (e) {
      error = e.message;
    } catch (e) {
      error = 'تعذر تحميل بيانات المندوب: ' + e.toString();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> claim(String id) async {
    try {
      await db.rpc('claim_delivery_order', params: {'p_order_id': id});
      notify('تم استلام الطلب. يمكنك الآن متابعة التوصيل.');
      await load();
    } on PostgrestException catch (e) {
      notify(e.message); await load();
    } catch (e) {
      notify(networkMessage(e));
    }
  }

  Future<void> updateStatus(String id, String status) async {
    try {
      await db.rpc('courier_update_order_status', params: {'p_order_id': id, 'p_new_status': status});
      notify('تم تحديث حالة التوصيل.');
      await load();
    } on PostgrestException catch (e) {
      notify(e.message);
    } catch (e) {
      notify(networkMessage(e));
    }
  }

  String _courierTime(dynamic raw) {
    if (raw == null) return '—';
    final value = DateTime.parse(raw.toString()).toLocal();
    return '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }

  String _courierDuration(dynamic raw) {
    if (raw == null) return '—';
    final seconds = (raw as num).toInt();
    if (seconds <= 0) return 'اكتمل';
    final minutes = (seconds / 60).ceil();
    if (minutes < 60) return '$minutes دقيقة';
    final hours = minutes ~/ 60;
    final remainder = minutes % 60;
    return remainder == 0 ? '$hours ساعة' : '$hours س و$remainder د';
  }

  Widget _courierTimeline(Map<String, dynamic> timeline) {
    const stages = <(String, String)>[
      ('courier_assigned_at', 'قبول التوصيلة'),
      ('picked_up_at', 'استلام الطلب من المتجر'),
      ('delivering_at', 'بدء الطريق'),
      ('delivered_at', 'تأكيد التسليم'),
    ];
    final completed = stages.where((stage) => timeline[stage.$1] != null).toList();
    if (completed.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFF1F8F4), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('توقيت التوصيلة', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
          const SizedBox(height: 7),
          ...completed.map((stage) => Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(
              children: [
                Expanded(child: Text(stage.$2, style: const TextStyle(fontSize: 11, color: Color(0xFF6F7D74)))),
                Text(_courierTime(timeline[stage.$1]), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
              ],
            ),
          )),
          const Divider(height: 12),
          Row(
            children: [
              const Expanded(child: Text('الوقت المنقضي', style: TextStyle(fontSize: 11, color: Color(0xFF6F7D74)))),
              Text(_courierDuration(timeline['elapsed_seconds']), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              const Expanded(child: Text('المتبقي المتوقع', style: TextStyle(fontSize: 11, color: Color(0xFF6F7D74)))),
              Text(_courierDuration(timeline['expected_remaining_seconds']), style: const TextStyle(fontSize: 11, color: green, fontWeight: FontWeight.w900)),
            ],
          ),
        ],
      ),
    );
  }

  Widget orderCard(Map<String, dynamic> order) {
    final id = order['order_id'].toString();
    final status = order['status'].toString();
    final mine = order['delivery_address'] != null;
    final timeline = order['timeline'] as Map<String, dynamic>?;
    Widget? action;
    if (status == 'ready_for_pickup' && !mine) {
      action = FilledButton(onPressed: () => claim(id), child: const Text('استلام الطلب'));
    } else if (status == 'ready_for_pickup' && mine) {
      action = FilledButton(onPressed: () => updateStatus(id, 'picked_up'), child: const Text('تم الاستلام من المتجر'));
    } else if (status == 'picked_up') {
      action = FilledButton(onPressed: () => updateStatus(id, 'delivering'), child: const Text('بدء التوصيل'));
    } else if (status == 'delivering') {
      action = FilledButton(onPressed: () => updateStatus(id, 'delivered'), child: const Text('تأكيد التسليم'));
    }
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.receipt_long, color: green),
            const SizedBox(width: 8),
            Expanded(child: Text('طلب #' + id.substring(0, 8), style: const TextStyle(fontWeight: FontWeight.w900))),
            Text(order['total_mad'].toString() + ' د.م', style: const TextStyle(fontWeight: FontWeight.w900)),
          ]),
          const SizedBox(height: 8),
          Text((order['store_name'] ?? 'متجر JIB').toString() + ' · ' + courierStatusLabel(status), style: const TextStyle(color: green, fontWeight: FontWeight.bold)),
          if ((order['store_address'] ?? '').toString().isNotEmpty)
            Padding(padding: const EdgeInsets.only(top: 7), child: Text('عنوان المتجر: ' + order['store_address'].toString())),
          if (mine && (order['delivery_address'] ?? '').toString().isNotEmpty)
            Padding(padding: const EdgeInsets.only(top: 7), child: Text('عنوان الزبون: ' + order['delivery_address'].toString())),
          if (mine && (order['customer_note'] ?? '').toString().trim().isNotEmpty)
            Padding(padding: const EdgeInsets.only(top: 7), child: Text('ملاحظة الزبون: ' + order['customer_note'].toString())),
          if (mine && timeline != null) _courierTimeline(timeline),
          if (action != null) ...[
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: action),
          ],
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Row(children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: red,
          child: Text('J', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 21)),
        ),
        SizedBox(width: 10),
        Text('جيب · المندوب', style: TextStyle(fontWeight: FontWeight.w900)),
      ]),
      actions: [
        IconButton(onPressed: load, icon: const Icon(Icons.refresh), tooltip: 'تحديث'),
        IconButton(onPressed: () => db.auth.signOut(), icon: const Icon(Icons.logout), tooltip: 'تسجيل الخروج'),
      ],
    ),
    body: loading
      ? const Center(child: CircularProgressIndicator())
      : error != null
        ? Center(child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: load, child: const Text('إعادة المحاولة')),
            ]),
          ))
        : !active
          ? const Center(child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.hourglass_top, size: 52, color: Colors.orange),
                SizedBox(height: 12),
                Text('حسابك قيد المراجعة', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
                SizedBox(height: 8),
                Text('تم استلام طلبك. ستظهر الطلبات بعد اعتماد الحساب من لوحة الإدارة.', textAlign: TextAlign.center),
              ]),
            ))
          : RefreshIndicator(
              onRefresh: load,
              child: ListView(padding: const EdgeInsets.all(16), children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [Color(0xFFEE343B), Color(0xFF94131A)],
                    ),
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: const [BoxShadow(color: Color(0x20A20F16), blurRadius: 24, offset: Offset(0, 12))],
                  ),
                  child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('JIB SIGNATURE  /  DELIVERY', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.1)),
                    SizedBox(height: 6),
                    Text('الطلبات المتاحة والتوصيلات المسندة إليك', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900)),
                  ]),
                ),
                const SizedBox(height: 18),
                Text('الطلبات (' + orders.length.toString() + ')', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
                const SizedBox(height: 10),
                if (orders.isEmpty)
                  const Card(child: Padding(padding: EdgeInsets.all(24), child: Column(children: [
                    Icon(Icons.delivery_dining, size: 44, color: Colors.black38),
                    SizedBox(height: 8),
                    Text('لا توجد توصيلات متاحة حالياً'),
                  ])))
                else
                  ...orders.map(orderCard),
              ]),
            ),
  );
}

String courierStatusLabel(String status) => const {
  'ready_for_pickup': 'جاهز للاستلام',
  'picked_up': 'تم الاستلام',
  'delivering': 'في الطريق إلى الزبون',
  'delivered': 'تم التسليم',
}[status] ?? status;

String? nextCourierStatus(String status) => const {
  'ready_for_pickup': 'picked_up',
  'picked_up': 'delivering',
  'delivering': 'delivered',
}[status];
