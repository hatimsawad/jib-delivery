import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const jibRed = Color(0xFFE31E24);
const jibGreen = Color(0xFF00843D);
const supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://emvleaghjsmzjmzgguvu.supabase.co',
);
const supabasePublishableKey = String.fromEnvironment(
  'SUPABASE_PUBLISHABLE_KEY',
  defaultValue: 'sb_publishable_6rD4poWuBH0TzK2HBFQFTg_4wOFnsX6',
);


String networkErrorMessage(Object error) {
  final detail = error.toString().toLowerCase();
  if (error is SocketException ||
      detail.contains('failed host lookup') ||
      detail.contains('socketexception') ||
      detail.contains('no address associated with hostname') ||
      detail.contains('name or service not known')) {
    return 'تعذر على هاتفك العثور على خادم Supabase (خطأ DNS). بدّل بين Wi‑Fi وبيانات الهاتف، وأوقف VPN أو مانع الإعلانات، واجعل Private DNS في Android على تلقائي ثم أعد المحاولة.';
  }
  if (error is TimeoutException ||
      detail.contains('timed out') ||
      detail.contains('timeout')) {
    return 'انتهت مهلة الاتصال بخادم JIB. تحقق من الإنترنت وحاول مجدداً.';
  }
  if (detail.contains('connection refused') ||
      detail.contains('network is unreachable')) {
    return 'الشبكة لا تسمح بالاتصال بخدمة JIB. جرّب شبكة أخرى ثم أعد المحاولة.';
  }
  return 'تعذر الاتصال بخدمة JIB: ' + error.toString();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String? startupError;
  try {
    await Supabase.initialize(url: supabaseUrl, publishableKey: supabasePublishableKey);
  } catch (error) {
    startupError = networkErrorMessage(error);
  }
  runApp(JibApp(startupError: startupError));
}

final supabase = Supabase.instance.client;

Widget _productImage(Object? rawUrl, {double size = 78}) {
  final url = rawUrl?.toString().trim() ?? '';
  final uri = Uri.tryParse(url);
  final valid = uri != null && (uri.scheme == 'https' || uri.scheme == 'http');
  final fallback = Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: const Color(0xFFF4F7F4), borderRadius: BorderRadius.circular(16)),
    child: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF9A8F87), size: 30),
  );
  if (!valid) return fallback;
  return ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: Image.network(url, width: size, height: size, fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => fallback),
  );
}

class JibApp extends StatelessWidget {
  final String? startupError;
  const JibApp({super.key, this.startupError});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'JIB | جيب',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: jibRed, primary: jibRed, surface: Colors.white)
              .copyWith(onSurface: const Color(0xFF19191C)),
          scaffoldBackgroundColor: const Color(0xFFFFFFFF),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFFFFFFF),
            foregroundColor: Color(0xFF19191C),
            elevation: 0,
            centerTitle: false,
            titleTextStyle: TextStyle(color: Color(0xFF19191C), fontSize: 19, fontWeight: FontWeight.w900),
          ),
          cardTheme: CardThemeData(
            color: Colors.white,
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: const BorderSide(color: Color(0xFFE7ECE8)),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE9E4DE))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE9E4DE))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: jibRed, width: 1.5)),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: jibRed,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              textStyle: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: Colors.white,
            indicatorColor: jibRed.withValues(alpha: .12),
            labelTextStyle: WidgetStateProperty.all(const TextStyle(fontWeight: FontWeight.w700, fontSize: 11)),
          ),
        ),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: startupError == null
              ? const AuthGate()
              : StartupConnectionError(message: startupError!, onRetry: main),
        ),
      );
}

class StartupConnectionError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  const StartupConnectionError({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.cloud_off, color: jibRed, size: 52),
        const SizedBox(height: 12),
        const Text('تعذر الاتصال بخدمة JIB', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 18),
        FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('إعادة المحاولة')),
      ]),
    )),
  );
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) => StreamBuilder<AuthState>(
        stream: supabase.auth.onAuthStateChange,
        builder: (context, snapshot) {
          if (supabase.auth.currentSession != null) return const CustomerHome();
          return const LoginScreen();
        },
      );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  bool _register = false;
  bool _busy = false;
  bool _showPassword = false;
  String? _message;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_register && _name.text.trim().isEmpty) {
      setState(() => _message = 'أدخل اسمك الكامل أولاً.');
      return;
    }
    if (_email.text.trim().isEmpty || _password.text.length < 8) {
      setState(() => _message = 'أدخل البريد وكلمة مرور من 8 أحرف على الأقل.');
      return;
    }
    setState(() { _busy = true; _message = null; });
    try {
      if (_register) {
        final result = await supabase.auth.signUp(
          email: _email.text.trim(),
          password: _password.text,
          data: {'full_name': _name.text.trim()},
        );
        if (result.session == null && mounted) {
          setState(() => _message = 'تم إنشاء الحساب. تحقق من بريدك لتأكيده ثم سجّل الدخول.');
        }
      } else {
        await supabase.auth.signInWithPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
      }
    } on AuthException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } on SocketException catch (error) {
      if (mounted) setState(() => _message = networkErrorMessage(error));
    } on TimeoutException catch (error) {
      if (mounted) setState(() => _message = networkErrorMessage(error));
    } catch (error) {
      if (mounted) setState(() => _message = networkErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                        boxShadow: const [
                          BoxShadow(color: Color(0x26E31E24), blurRadius: 24, offset: Offset(0, 10)),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Text('J', style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900)),
                    ),
                    const SizedBox(height: 18),
                    const Text('جيب JIB', textAlign: TextAlign.center, style: TextStyle(fontSize: 30, letterSpacing: -.5, fontWeight: FontWeight.w900)),
                    const Text('Jib وتكايس على jib', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF82766F), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.1)),
                    const SizedBox(height: 28),
                    Text(_register ? 'إنشاء حساب زبون' : 'مرحباً بعودتك', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
                    if (_register) ...[
                      const SizedBox(height: 12),
                      TextField(controller: _name, decoration: const InputDecoration(labelText: 'الاسم الكامل', border: OutlineInputBorder())),
                    ],
                    const SizedBox(height: 12),
                    TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'البريد الإلكتروني', border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    TextField(controller: _password, obscureText: !_showPassword, decoration: InputDecoration(labelText: 'كلمة المرور (8 أحرف على الأقل)', border: const OutlineInputBorder(), suffixIcon: IconButton(icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _showPassword = !_showPassword)))),
                    if (_message != null) ...[
                      const SizedBox(height: 12),
                      Text(_message!, style: const TextStyle(color: jibRed)),
                    ],
                    const SizedBox(height: 18),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      style: FilledButton.styleFrom(backgroundColor: jibRed, padding: const EdgeInsets.all(15)),
                      child: Text(_busy ? 'يرجى الانتظار...' : (_register ? 'إنشاء الحساب' : 'تسجيل الدخول')),
                    ),
                    TextButton(
                      onPressed: _busy ? null : () => setState(() { _register = !_register; _message = null; }),
                      child: Text(_register ? 'لديك حساب؟ سجّل الدخول' : 'ليس لديك حساب؟ أنشئ حساباً'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

class _ServicePill extends StatelessWidget {
  final String label;
  const _ServicePill({required this.label});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), border: Border.all(color: const Color(0xFFDCE9DF))),
    child: Text(label, style: const TextStyle(color: jibGreen, fontSize: 11, fontWeight: FontWeight.w800)),
  );
}

class CustomerHome extends StatefulWidget {
  const CustomerHome({super.key});

  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  int _tab = 0;
  int _category = 0;
  String _search = '';
  final _searchController = TextEditingController();
  final Map<String, Map<String, dynamic>> _cart = {};
  String? _cartStoreId;
  bool _checkoutBusy = false;

  static const _categories = ['الكل', 'مطاعم', 'بقالة'];
  static const _categoryKeys = [null, 'restaurant', 'grocery'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _notify(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  Future<List<Map<String, dynamic>>> _stores() async {
    final rows = await supabase.from('stores').select('id,name,description,category,address_text,is_open')
      .eq('is_active', true).eq('is_open', true).eq('onboarding_status', 'approved').order('name');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> _openStore(Map<String, dynamic> store) async {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: SizedBox(
          height: MediaQuery.of(sheetContext).size.height * .82,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(18),
                child: Row(children: [
                  Expanded(child: Text(store['name'] as String? ?? 'المتجر', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900))),
                  IconButton(onPressed: () => Navigator.pop(sheetContext), icon: const Icon(Icons.close)),
                ]),
              ),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: supabase.from('products').select('id,name,description,price_mad,image_url,image_is_ai_generated')
                    .eq('store_id', store['id']).eq('is_available', true).order('name')
                    .then((rows) => List<Map<String, dynamic>>.from(rows)),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                    if (snapshot.hasError) return const Center(child: Text('تعذر تحميل المنتجات.'));
                    final products = snapshot.data ?? [];
                    if (products.isEmpty) return const Center(child: Text('لا توجد منتجات متاحة حالياً.'));
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return Card(
                          child: ListTile(
                            leading: _productImage(product['image_url'], size: 74),
                            title: Text(product['name'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.w800)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${product['price_mad']} درهم'),
                                if (product['image_is_ai_generated'] == true)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 3),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.auto_awesome, size: 11, color: jibRed),
                                        SizedBox(width: 4),
                                        Text('صورة مولدة بالذكاء الاصطناعي', style: TextStyle(fontSize: 10, color: Color(0xFF82766F))),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.add_circle, color: jibRed),
                              onPressed: () {
                                final storeId = store['id'].toString();
                                if (_cartStoreId != null && _cartStoreId != storeId) {
                                  _notify('أكمل أو أفرغ سلتك الحالية قبل الطلب من متجر آخر.');
                                  return;
                                }
                                setState(() {
                                  _cartStoreId = storeId;
                                  final id = product['id'].toString();
                                  final existing = _cart[id];
                                  _cart[id] = {...product, 'quantity': ((existing?['quantity'] as int?) ?? 0) + 1};
                                });
                                _notify('أضيف المنتج إلى السلة');
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _checkout() async {
    if (_cart.isEmpty || _cartStoreId == null) return;
    final addressController = TextEditingController();
    final noteController = TextEditingController();
    final address = await showDialog<String>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('عنوان التوصيل'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: addressController, decoration: const InputDecoration(labelText: 'العنوان بالتفصيل', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: noteController, decoration: const InputDecoration(labelText: 'ملاحظة للسائق (اختياري)', border: OutlineInputBorder())),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, addressController.text.trim()), child: const Text('تأكيد')),
          ],
        ),
      ),
    );
    if (address == null) return;
    if (address.isEmpty) { _notify('أدخل عنوان التوصيل أولاً.'); return; }
    setState(() => _checkoutBusy = true);
    try {
      final userId = supabase.auth.currentUser!.id;
      final savedAddress = await supabase.from('addresses').insert({
        'customer_id': userId,
        'label': 'عنوان التوصيل',
        'address_text': address,
      }).select('id').single();
      final orderId = await supabase.rpc('checkout_order', params: {
        'p_store_id': _cartStoreId,
        'p_address_id': savedAddress['id'],
        'p_items': _cart.entries.map((entry) => {'product_id': entry.key, 'quantity': entry.value['quantity']}).toList(),
        'p_customer_note': noteController.text.trim(),
      });
      if (!mounted) return;
      setState(() { _cart.clear(); _cartStoreId = null; _tab = 1; });
      _notify('تم تسجيل طلبك بنجاح: ${orderId.toString().substring(0, 8)}');
    } on PostgrestException catch (error) {
      _notify(error.message);
    } catch (_) {
      _notify('تعذر إتمام الطلب. تحقق من العنوان والمنتجات وحاول مجدداً.');
    } finally {
      if (mounted) setState(() => _checkoutBusy = false);
      addressController.dispose();
      noteController.dispose();
    }
  }

  Widget _discovery() => FutureBuilder<List<Map<String, dynamic>>>(
        future: _stores(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return const Center(child: Text('تعذر تحميل المتاجر. تحقق من الاتصال.'));
          final category = _categoryKeys[_category];
          final stores = (snapshot.data ?? []).where((store) {
            final matchesCategory = category == null || store['category'] == category;
            final text = '${store['name']} ${store['description'] ?? ''}'.toLowerCase();
            return matchesCategory && text.contains(_search.toLowerCase());
          }).toList();
          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                          colors: [jibRed, Color(0xFFB9161D)],
                        ),
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: const [
                          BoxShadow(color: Color(0x20A20F16), blurRadius: 24, offset: Offset(0, 12)),
                        ],
                      ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('JIB · الرباط', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                  const SizedBox(height: 8),
                  const Text('كل شيأ تحبه في مكان واحد', style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _search = value),
                    decoration: const InputDecoration(hintText: 'قلب على متجر...', prefixIcon: Icon(Icons.search), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)), borderSide: BorderSide.none)),
                  ),
                ]),
              ),
              const SizedBox(height: 22),
              const Text('اكتشف ما تحب', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7FBF8),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: jibGreen.withValues(alpha: .18)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Row(children: [
                    Icon(Icons.auto_awesome, color: Color(0xFFB99A54), size: 15),
                    SizedBox(width: 6),
                    Text('عالم JIB', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                  ]),
                  const SizedBox(height: 10),
                  Wrap(spacing: 7, runSpacing: 7, children: const [
                    _ServicePill(label: 'المطاعم والمأكولات'),
                    _ServicePill(label: 'المشروبات'),
                    _ServicePill(label: 'الحلويات'),
                    _ServicePill(label: 'البقالة'),
                  ]),
                  const SizedBox(height: 8),
                  const Text('تنضم هذه الفئات تدريجياً إلى JIB في الرباط', style: TextStyle(color: Color(0xFF68736B), fontSize: 11)),
                ]),
              ),
              const SizedBox(height: 12),
              Wrap(spacing: 8, children: List.generate(_categories.length, (index) => ChoiceChip(
                label: Text(_categories[index]),
                selected: _category == index,
                onSelected: (_) => setState(() => _category = index),
                selectedColor: jibGreen.withValues(alpha: .13),
                showCheckmark: false,
              ))),
              const SizedBox(height: 22),
              const Text('المطاعم والمتاجر المتاحة الآن', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              if (stores.isEmpty)
                const Card(child: Padding(padding: EdgeInsets.all(22), child: Column(children: [
                  Icon(Icons.store_mall_directory_outlined, size: 42, color: Colors.black38),
                  SizedBox(height: 8),
                  Text('لا توجد متاجر متاحة حالياً', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('المطاعم والمأكولات والمشروبات والحلويات والبقالة تنضم تدريجياً. الإلكترونيات والملابس وباقي المتاجر قريباً.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54, fontSize: 12)),
                ])))
              else
                ...stores.map((store) => Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    leading: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(color: const Color(0xFFFFE8E8), borderRadius: BorderRadius.circular(17)),
                      child: const Icon(Icons.storefront_rounded, color: jibRed, size: 28),
                    ),
                    title: Text(store['name'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.w900)),
                    subtitle: Text(store['description'] as String? ?? store['address_text'] as String? ?? 'متجر JIB'),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () => _openStore(store),
                  ),
                )),
              const SizedBox(height: 26),
              const Row(
                children: [
                  Expanded(child: Text('علامات JIB التجارية', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900))),
                  _ServicePill(label: '51 علامة'),
                ],
              ),
              const SizedBox(height: 5),
              const Text('تعرّف على العلامات الموجودة في دليل JIB. ظهور العلامة لا يعني أن الطلب منها مفتوح حالياً.', style: TextStyle(color: Color(0xFF68736B), fontSize: 11)),
              const SizedBox(height: 12),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: supabase.from('commercial_brands')
                    .select('id,name,category,website_url,logo_url')
                    .eq('status', 'approved')
                    .order('name')
                    .then((rows) => List<Map<String, dynamic>>.from(rows)),
                builder: (context, brandSnapshot) {
                  if (brandSnapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (brandSnapshot.hasError) {
                    return const Card(child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('تعذر تحميل دليل العلامات حالياً.'),
                    ));
                  }
                  final brands = (brandSnapshot.data ?? []).where((brand) {
                    final value = '${brand['name']} ${brand['category']}'.toLowerCase();
                    return value.contains(_search.toLowerCase());
                  }).toList();
                  if (brands.isEmpty) {
                    return const Card(child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('لا توجد علامة مطابقة لبحثك.'),
                    ));
                  }
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: brands.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 9,
                      crossAxisSpacing: 9,
                      childAspectRatio: 1.55,
                    ),
                    itemBuilder: (context, index) {
                      final brand = brands[index];
                      final name = brand['name']?.toString() ?? 'علامة تجارية';
                      final category = brand['category']?.toString() ?? '';
                      final categoryLabel = const {
                        'prepared-food': 'مطاعم ومأكولات',
                        'beverages': 'مشروبات',
                        'grocery': 'بقالة ومواد غذائية',
                        'fashion': 'ملابس وأزياء',
                        'electronics': 'إلكترونيات',
                        'beauty': 'جمال وعناية',
                        'personal-care': 'عناية شخصية',
                        'household': 'المنزل',
                        'sports-outdoors': 'رياضة',
                        'toys-games': 'ألعاب',
                        'general-merchandise': 'متاجر متنوعة',
                      }[category] ?? 'علامة ضمن دليل JIB';
                      final logo = brand['logo_url']?.toString() ?? '';
                      final logoUri = Uri.tryParse(logo);
                      final hasLogo = logoUri != null && (logoUri.scheme == 'https' || logoUri.scheme == 'http');
                      return Card(
                        margin: EdgeInsets.zero,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(22),
                          onTap: () => _openBrand(brand),
                          child: Padding(
                            padding: const EdgeInsets.all(11),
                            child: Row(
                              children: [
                                Container(
                                  width: 43,
                                  height: 43,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFE8E8),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: hasLogo
                                      ? Image.network(logo, fit: BoxFit.contain,
                                          errorBuilder: (_, __, ___) => Center(
                                            child: Text(name.isEmpty ? 'J' : name.characters.first,
                                              style: const TextStyle(color: jibRed, fontWeight: FontWeight.w900, fontSize: 18)),
                                          ))
                                      : Center(child: Text(name.isEmpty ? 'J' : name.characters.first,
                                          style: const TextStyle(color: jibRed, fontWeight: FontWeight.w900, fontSize: 18))),
                                ),
                                const SizedBox(width: 9),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(name, maxLines: 2, overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
                                      const SizedBox(height: 4),
                                      Text(categoryLabel, maxLines: 1, overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 9, color: Color(0xFF68736B))),
                                      const SizedBox(height: 5),
                                      const Text('ضمن دليل JIB', style: TextStyle(fontSize: 9, color: jibGreen, fontWeight: FontWeight.w800)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          );
        },
      );

  Future<void> _openBrand(Map<String, dynamic> brand) async {
    final brandId = brand['id'];
    final brandName = brand['name']?.toString() ?? 'العلامة التجارية';
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: SizedBox(
          height: MediaQuery.of(sheetContext).size.height * .82,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
                child: Row(children: [
                  Expanded(child: Text(brandName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900))),
                  IconButton(onPressed: () => Navigator.pop(sheetContext), icon: const Icon(Icons.close)),
                ]),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 18),
                child: Text(
                  'كتالوج منتجات العلامة. المنتجات التي لم تعتمد أسعارها وتوفرها لا يمكن طلبها بعد.',
                  style: TextStyle(color: Color(0xFF68736B), fontSize: 12),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: supabase
                      .from('commercial_brand_product_templates')
                      .select('id,name,category,price_mad,status,is_active')
                      .eq('brand_id', brandId)
                      .order('name')
                      .then((rows) => List<Map<String, dynamic>>.from(rows)),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return const Center(child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('تعذر تحميل منتجات هذه العلامة حالياً.'),
                      ));
                    }
                    final products = snapshot.data ?? [];
                    if (products.isEmpty) {
                      return const Center(child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.inventory_2_outlined, size: 42, color: Color(0xFF9A928B)),
                          SizedBox(height: 10),
                          Text('لم تتم إضافة منتجات لهذه العلامة بعد.', textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.w800)),
                          SizedBox(height: 6),
                          Text('ستظهر المنتجات هنا عندما يضيفها المسؤول إلى كتالوج JIB.',
                            textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF68736B), fontSize: 12)),
                        ]),
                      ));
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: products.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final product = products[index];
                        final active = product['is_active'] == true && product['status'] == 'approved';
                        final price = product['price_mad'];
                        return Card(
                          margin: EdgeInsets.zero,
                          child: ListTile(
                            leading: Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFE8E8),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.shopping_bag_outlined, color: jibRed),
                            ),
                            title: Text(product['name']?.toString() ?? '',
                              style: const TextStyle(fontWeight: FontWeight.w800)),
                            subtitle: Text(price == null ? 'السعر لم يحدد بعد' : '$price درهم'),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                              decoration: BoxDecoration(
                                color: active ? const Color(0xFFE8F5EC) : const Color(0xFFFFF3E0),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(active ? 'معتمد' : 'قريباً',
                                style: TextStyle(
                                  color: active ? jibGreen : const Color(0xFF946200),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                )),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel(String status) => const {
    'pending': 'في انتظار تأكيد المتجر', 'accepted': 'تم قبول الطلب', 'rejected': 'تم رفض الطلب',
    'preparing': 'قيد التحضير', 'ready_for_pickup': 'جاهز للتوصيل', 'picked_up': 'استلمه الموصّل',
    'delivering': 'في الطريق إليك', 'delivered': 'تم التسليم', 'cancelled': 'ملغى',
  }[status] ?? status;

  Widget _orderProgress(String status) {
    final stage = const {
      'pending': 0,
      'accepted': 1,
      'preparing': 1,
      'ready_for_pickup': 2,
      'picked_up': 2,
      'delivering': 2,
      'delivered': 3,
    }[status];

    if (stage == null) {
      final rejected = status == 'rejected';
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEEEE),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(rejected ? Icons.cancel_outlined : Icons.info_outline, color: jibRed),
            const SizedBox(width: 8),
            Expanded(child: Text(_statusLabel(status), style: const TextStyle(color: jibRed, fontWeight: FontWeight.w800))),
          ],
        ),
      );
    }

    const phases = ['تأكيد الطلب', 'التحضير', 'التوصيل', 'التسليم'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(child: Text('متابعة الطلب', style: TextStyle(fontWeight: FontWeight.w900))),
            Text(
              phases[stage],
              style: const TextStyle(color: jibRed, fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: (stage + 1) / phases.length,
            minHeight: 7,
            backgroundColor: const Color(0xFFECE8E3),
            color: jibRed,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: phases.map((phase) => Expanded(
            child: Text(
              phase,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: phases.indexOf(phase) <= stage ? jibRed : const Color(0xFF9A928B),
                fontSize: 9,
                fontWeight: phases.indexOf(phase) == stage ? FontWeight.w900 : FontWeight.w500,
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }

  Future<List<Map<String, dynamic>>> _loadOrdersWithTimeline() async {
    final rows = await supabase
        .from('orders')
        .select('id,status,total_mad,created_at,stores(name)')
        .order('created_at', ascending: false)
        .limit(50);
    if (rows.isEmpty) return [];

    final rawTimelines = await supabase.rpc('jib_order_timeline');
    final timelines = <String, Map<String, dynamic>>{};
    for (final raw in rawTimelines as List<dynamic>) {
      final item = Map<String, dynamic>.from(raw as Map);
      timelines[item['order_id'].toString()] = item;
    }

    return rows.map((raw) {
      final order = Map<String, dynamic>.from(raw);
      order['timeline'] = timelines[order['id'].toString()];
      return order;
    }).toList();
  }

  String _durationLabel(dynamic rawSeconds) {
    if (rawSeconds == null) return 'غير متاح';
    final seconds = (rawSeconds as num).toInt();
    if (seconds <= 0) return 'اكتمل';
    final minutes = (seconds / 60).ceil();
    if (minutes < 60) return '$minutes دقيقة';
    final hours = minutes ~/ 60;
    final remainder = minutes % 60;
    return remainder == 0 ? '$hours ساعة' : '$hours س و$remainder د';
  }

  String _timeLabel(dynamic rawTime) {
    if (rawTime == null) return '—';
    final value = DateTime.parse(rawTime.toString()).toLocal();
    return '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }

  Widget _orders() => FutureBuilder<List<Map<String, dynamic>>>(
    future: _loadOrdersWithTimeline(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) return const Center(child: Text('تعذر تحميل الطلبات.'));
      final rows = snapshot.data ?? [];
      if (rows.isEmpty) return const Center(child: Text('لا توجد طلبات بعد.'));
      return RefreshIndicator(
        onRefresh: () async {
          if (mounted) setState(() {});
          await Future<void>.delayed(const Duration(milliseconds: 250));
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: rows.map((order) {
            final status = order['status'].toString();
            final orderId = order['id'].toString();
            final timeline = order['timeline'] as Map<String, dynamic>?;
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE8E8),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.receipt_long_rounded, color: jibRed),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (order['stores']?['name'] ?? 'طلب JIB').toString(),
                                style: const TextStyle(fontWeight: FontWeight.w900),
                              ),
                              Text(
                                'طلب #${orderId.substring(0, 8)}',
                                style: const TextStyle(color: Color(0xFF82766F), fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${order['total_mad']} د.م',
                          style: const TextStyle(color: jibRed, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _orderProgress(status),
                    if (timeline != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F5F2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                const Expanded(child: Text('الوقت المنقضي', style: TextStyle(fontSize: 11, color: Color(0xFF82766F)))),
                                Text(_durationLabel(timeline['elapsed_seconds']), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Expanded(child: Text('الوقت المتوقع المتبقي', style: TextStyle(fontSize: 11, color: Color(0xFF82766F)))),
                                Text(_durationLabel(timeline['expected_remaining_seconds']), style: const TextStyle(color: jibRed, fontWeight: FontWeight.w900, fontSize: 12)),
                              ],
                            ),
                            if (timeline['estimated_delivery_at'] != null) ...[
                              const SizedBox(height: 6),
                              Text('${status == 'delivered' ? 'تم التسليم في' : 'موعد التسليم المتوقع'}: ${_timeLabel(timeline['estimated_delivery_at'])}', style: const TextStyle(fontSize: 11, color: Color(0xFF82766F))),
                            ],
                            if (timeline['eta_confidence'] == 'baseline')
                              const Padding(
                                padding: EdgeInsets.only(top: 5),
                                child: Text('تقدير أولي يتحسن مع تراكم بيانات التوصيل.', style: TextStyle(fontSize: 10, color: Color(0xFF82766F))),
                              ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      _statusLabel(status),
                      textAlign: TextAlign.start,
                      style: const TextStyle(color: Color(0xFF82766F), fontSize: 11),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      );
    },
  );

  Widget _cartPage() {
    final total = _cart.values.fold<double>(0, (sum, item) => sum + (double.tryParse(item['price_mad'].toString()) ?? 0) * (item['quantity'] as int));
    return ListView(padding: const EdgeInsets.all(18), children: [
      const Text('سلة المشتريات', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
      const SizedBox(height: 12),
      if (_cart.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(24), child: Text('السلة فارغة. اختر متجراً وأضف المنتجات.', textAlign: TextAlign.center)))
      else ...[
        ..._cart.entries.map((entry) => Card(child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          leading: _productImage(entry.value['image_url'], size: 66),
          title: Text(entry.value['name'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${entry.value['quantity']} × ${entry.value['price_mad']} درهم'),
              if (entry.value['image_is_ai_generated'] == true)
                const Text('صورة مولدة بالذكاء الاصطناعي', style: TextStyle(fontSize: 10, color: Color(0xFF82766F))),
            ],
          ),
          trailing: SizedBox(width: 126, child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            IconButton(visualDensity: VisualDensity.compact, icon: const Icon(Icons.remove_circle_outline), onPressed: () => setState(() {
              final quantity = entry.value['quantity'] as int;
              if (quantity <= 1) { _cart.remove(entry.key); if (_cart.isEmpty) _cartStoreId = null; }
              else { _cart[entry.key] = {...entry.value, 'quantity': quantity - 1}; }
            })),
            Text('${entry.value['quantity']}', style: const TextStyle(fontWeight: FontWeight.bold)),
            IconButton(visualDensity: VisualDensity.compact, icon: const Icon(Icons.add_circle_outline, color: jibRed), onPressed: () => setState(() => _cart[entry.key] = {...entry.value, 'quantity': (entry.value['quantity'] as int) + 1})),
          ])),
        ))),
        ListTile(title: const Text('مجموع المنتجات'), trailing: Text('${total.toStringAsFixed(2)} د.م')),
        const ListTile(title: Text('التوصيل'), trailing: Text('15.00 د.م')),
        const Divider(),
        ListTile(title: const Text('الإجمالي عند الاستلام', style: TextStyle(fontWeight: FontWeight.w900)), trailing: Text('${(total + 15).toStringAsFixed(2)} د.م', style: const TextStyle(fontWeight: FontWeight.w900, color: jibRed))),
        const Text('الدفع نقداً عند استلام الطلب.', style: TextStyle(color: Colors.black54, fontSize: 12)),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _checkoutBusy ? null : _checkout,
          style: FilledButton.styleFrom(backgroundColor: jibRed, padding: const EdgeInsets.all(15)),
          child: Text(_checkoutBusy ? 'جارٍ إرسال الطلب...' : 'تأكيد الطلب نقداً عند الاستلام'),
        ),
      ],
    ]);
  }

  Widget _account() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    const CircleAvatar(radius: 34, child: Icon(Icons.person, size: 36)),
    const SizedBox(height: 12),
    Text(supabase.auth.currentUser?.email ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
    const SizedBox(height: 16),
    OutlinedButton.icon(
      onPressed: () async => supabase.auth.signOut(),
      icon: const Icon(Icons.logout),
      label: const Text('تسجيل الخروج'),
    ),
  ]));

  @override
  Widget build(BuildContext context) {
    final pages = [_discovery(), _orders(), _cartPage(), _account()];
    return Scaffold(
      appBar: AppBar(
        title: const Row(children: [
          CircleAvatar(
            radius: 19,
            backgroundColor: jibRed,
            child: Text('J', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22)),
          ),
          SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('جيب JIB', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            Text('SIGNATURE  ·  كلشي قريب ليك', style: TextStyle(fontSize: 9, color: Color(0xFF82766F), letterSpacing: .7)),
          ]),
        ]),
      ),
      body: IndexedStack(index: _tab, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (index) => setState(() => _tab = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'الرئيسية'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'طلباتي'),
          NavigationDestination(icon: Icon(Icons.shopping_bag_outlined), label: 'السلة'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'حسابي'),
        ],
      ),
    );
  }
}
