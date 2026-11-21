// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

const jibRed = Color(0xFFE31E24);
const supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://emvleaghjsmzjmzgguvu.supabase.co');
const supabasePublishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY', defaultValue: 'sb_publishable_6rD4poWuBH0TzK2HBFQFTg_4wOFnsX6');

Widget _merchantProductImage(Object? rawUrl) {
  final url = rawUrl?.toString().trim() ?? '';
  final uri = Uri.tryParse(url);
  final valid = uri != null && (uri.scheme == 'https' || uri.scheme == 'http');
  final fallback = Container(
    width: 58,
    height: 58,
    decoration: BoxDecoration(color: const Color(0xFFF4F7F4), borderRadius: BorderRadius.circular(15)),
    child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF9A8F87)),
  );
  if (!valid) return fallback;
  return ClipRRect(
    borderRadius: BorderRadius.circular(15),
    child: Image.network(url, width: 58, height: 58, fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => fallback),
  );
}


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
  runApp(JibMerchantApp(startupError: startupError));
}

final db = Supabase.instance.client;

class JibMerchantApp extends StatelessWidget {
  final String? startupError;
  const JibMerchantApp({super.key, this.startupError});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'JIB التاجر', debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: jibRed, primary: jibRed, surface: Colors.white, tertiary: const Color(0xFF00843D))
          .copyWith(onSurface: const Color(0xFF19191C)),
      scaffoldBackgroundColor: const Color(0xFFFFFFFF),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFFFFFF),
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
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    ),
    home: Directionality(
      textDirection: TextDirection.rtl,
      child: startupError == null
          ? const MerchantGate()
          : MerchantStartupConnectionError(message: startupError!, onRetry: main),
    ),
  );
}

class MerchantStartupConnectionError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  const MerchantStartupConnectionError({super.key, required this.message, required this.onRetry});

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
  bool busy = false, showPassword = false;
  String? error;

  @override
  void dispose() { email.dispose(); password.dispose(); super.dispose(); }

  Future<void> submit() async {
    if (email.text.trim().isEmpty || password.text.isEmpty) {
      setState(() => error = 'أدخل البريد الإلكتروني وكلمة المرور.');
      return;
    }
    setState(() { busy = true; error = null; });
    try {
      await db.auth.signInWithPassword(email: email.text.trim(), password: password.text);
    } on AuthException catch (e) {
      if (mounted) setState(() => error = e.message);
    } catch (e) {
      if (mounted) setState(() => error = networkErrorMessage(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(child: Center(child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
            width: 82, height: 82,
            decoration: BoxDecoration(
              gradient: const LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft,
                colors: [Color(0xFFE31E24), Color(0xFFB9161D)]),
              borderRadius: BorderRadius.circular(26),
              boxShadow: const [BoxShadow(color: Color(0x26E31E24), blurRadius: 24, offset: Offset(0, 10))],
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 42),
          ),
          const SizedBox(height: 18),
          const Text('JIB · فضاء التاجر', textAlign: TextAlign.center,
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
          const Text('Jib وتكايس على jib', textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF82766F), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.1)),
          const SizedBox(height: 8),
          const Text('دخول مخصص للحسابات التي اعتمدتها إدارة JIB',
            textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 20),
          TextField(controller: email, keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'البريد الإلكتروني', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: password, obscureText: !showPassword,
            decoration: InputDecoration(labelText: 'كلمة المرور', border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                onPressed: () => setState(() => showPassword = !showPassword),
                icon: Icon(showPassword ? Icons.visibility_off : Icons.visibility),
              ))),
          if (error != null) Padding(padding: const EdgeInsets.only(top: 12),
            child: Text(error!, style: const TextStyle(color: jibRed))),
          const SizedBox(height: 18),
          FilledButton(onPressed: busy ? null : submit,
            style: FilledButton.styleFrom(backgroundColor: jibRed, padding: const EdgeInsets.all(15)),
            child: Text(busy ? 'يرجى الانتظار...' : 'تسجيل الدخول')),
        ]),
      ),
    ))),
  );
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
        final timelines = <String, Map<String, dynamic>>{};
        try {
          final rawTimelines = await db.rpc('jib_order_timeline');
          for (final raw in rawTimelines as List<dynamic>) {
            final item = Map<String, dynamic>.from(raw as Map);
            timelines[item['order_id'].toString()] = item;
          }
        } catch (_) {
          // Keep order management usable if the timeline endpoint is temporarily unavailable.
        }
        orders = o.map((e) {
          final row = Map<String, dynamic>.from(e);
          row['timeline'] = timelines[row['id'].toString()];
          return row;
        }).toList();
      } else { store = null; products = []; orders = []; }
    } catch (e) { error = networkErrorMessage(e); }
    if (mounted) setState(() => loading = false);
  }

  String statusLabel(String status) => const {
    'pending': 'طلب جديد', 'accepted': 'تم القبول', 'rejected': 'مرفوض',
    'preparing': 'قيد التحضير', 'ready_for_pickup': 'جاهز للاستلام',
    'picked_up': 'استلمه الموصّل', 'delivering': 'في الطريق', 'delivered': 'تم التسليم', 'cancelled': 'ملغى',
  }[status] ?? status;

  String timelineTime(dynamic raw) {
    if (raw == null) return '—';
    final value = DateTime.parse(raw.toString()).toLocal();
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day/$month $hour:$minute';
  }

  String timelineDuration(dynamic raw) {
    if (raw == null) return '—';
    final seconds = (raw as num).toInt();
    if (seconds <= 0) return 'اكتمل';
    final minutes = (seconds / 60).ceil();
    if (minutes < 60) return '$minutes دقيقة';
    final hours = minutes ~/ 60;
    final remainder = minutes % 60;
    return remainder == 0 ? '$hours ساعة' : '$hours س و$remainder د';
  }

  Widget orderTimeline(Map<String, dynamic>? timeline) {
    if (timeline == null) return const SizedBox.shrink();
    const stages = <(String, String)>[
      ('order_placed_at', 'تأكيد الطلب'),
      ('merchant_accepted_at', 'قبول المتجر'),
      ('preparation_started_at', 'بدء التحضير'),
      ('ready_for_pickup_at', 'جاهز للاستلام'),
      ('courier_assigned_at', 'قبول المندوب'),
      ('picked_up_at', 'استلام المندوب'),
      ('delivering_at', 'بدء التوصيل'),
      ('delivered_at', 'التسليم'),
    ];
    final completed = stages.where((stage) => timeline[stage.$1] != null).toList();
    if (completed.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFF8F5F2), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('التوقيت التفصيلي للطلب', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
          const SizedBox(height: 8),
          ...completed.map((stage) => Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(
              children: [
                Expanded(child: Text(stage.$2, style: const TextStyle(fontSize: 11, color: Color(0xFF82766F)))),
                Text(timelineTime(timeline[stage.$1]), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
              ],
            ),
          )),
          const Divider(height: 12),
          Row(
            children: [
              const Expanded(child: Text('الوقت المنقضي', style: TextStyle(fontSize: 11, color: Color(0xFF82766F)))),
              Text(timelineDuration(timeline['elapsed_seconds']), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              const Expanded(child: Text('المتبقي المتوقع', style: TextStyle(fontSize: 11, color: Color(0xFF82766F)))),
              Text(timelineDuration(timeline['expected_remaining_seconds']), style: const TextStyle(fontSize: 11, color: jibRed, fontWeight: FontWeight.w900)),
            ],
          ),
          if (timeline['eta_confidence'] == 'baseline')
            const Padding(
              padding: EdgeInsets.only(top: 5),
              child: Text('تقدير أولي؛ سيصبح أدق مع تراكم الطلبات المكتملة.', style: TextStyle(fontSize: 10, color: Color(0xFF82766F))),
            ),
        ],
      ),
    );
  }

  Future<void> updateOrder(Map<String, dynamic> order, String status) async {
    try {
      await db.rpc('merchant_update_order_status', params: {
        'p_order_id': order['id'], 'p_new_status': status,
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث حالة الطلب')));
      await load();
    } on PostgrestException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر تحديث الطلب. حاول مجدداً.')));
    }
  }

  Widget orderCard(Map<String, dynamic> order) {
    final status = order['status'].toString();
    final actions = <Widget>[];
    if (status == 'pending') {
      actions.add(OutlinedButton(onPressed: () => updateOrder(order, 'rejected'), child: const Text('رفض')));
      actions.add(FilledButton(onPressed: () => updateOrder(order, 'accepted'), child: const Text('قبول الطلب')));
    } else if (status == 'accepted') {
      actions.add(FilledButton(onPressed: () => updateOrder(order, 'preparing'), child: const Text('بدء التحضير')));
    } else if (status == 'preparing') {
      actions.add(FilledButton(onPressed: () => updateOrder(order, 'ready_for_pickup'), child: const Text('جاهز للاستلام')));
    }
    return Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.receipt_long, color: jibRed),
        const SizedBox(width: 8),
        Expanded(child: Text('طلب #${order['id'].toString().substring(0, 8)}', style: const TextStyle(fontWeight: FontWeight.w900))),
        Text('${order['total_mad']} د.م', style: const TextStyle(fontWeight: FontWeight.w900)),
      ]),
      const SizedBox(height: 8),
      Text(statusLabel(status), style: const TextStyle(color: jibRed, fontWeight: FontWeight.bold)),
      orderTimeline(order['timeline'] as Map<String, dynamic>?),
      if ((order['customer_note'] ?? '').toString().trim().isNotEmpty)
        Padding(padding: const EdgeInsets.only(top: 6), child: Text('ملاحظة الزبون: ${order['customer_note']}')),
      if (actions.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 10), child: Wrap(spacing: 8, runSpacing: 8, children: actions)),
    ])));
  }

  Future<void> toggleOpen(bool value) async {
    if (store == null) return;
    try {
      await db.from('stores').update({'is_open': value}).eq('id', store!['id']);
      await load();
    } catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر تحديث حالة المتجر'))); }
  }

  Future<String> _uploadProductImage(XFile image) async {
    final bytes = await image.readAsBytes();
    if (bytes.lengthInBytes > 5 * 1024 * 1024) {
      throw const FormatException('حجم الصورة يتجاوز 5 ميغابايت.');
    }
    final extension = image.name.split('.').last.toLowerCase();
    const mimeTypes = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'webp': 'image/webp',
    };
    final contentType = mimeTypes[extension];
    if (contentType == null) {
      throw const FormatException('اختر صورة بصيغة JPG أو PNG أو WEBP.');
    }
    final storeId = store?['id']?.toString();
    if (storeId == null || storeId.isEmpty) {
      throw const FormatException('لا يوجد متجر مرتبط بهذا الحساب.');
    }
    final path = '$storeId/${DateTime.now().microsecondsSinceEpoch}.$extension';
    await db.storage.from('product-images').uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(contentType: contentType),
    );
    return db.storage.from('product-images').getPublicUrl(path);
  }

  Future<void> editProduct([Map<String, dynamic>? product]) async {
    final name = TextEditingController(text: product?['name']?.toString() ?? '');
    final description = TextEditingController(text: product?['description']?.toString() ?? '');
    final price = TextEditingController(text: product?['price_mad']?.toString() ?? '');
    String? currentImageUrl = product?['image_url']?.toString();
    bool currentImageIsAiGenerated = product?['image_is_ai_generated'] == true;
    XFile? selectedImage;

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(product == null ? 'إضافة منتج' : 'تعديل المنتج'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: name, decoration: const InputDecoration(labelText: 'اسم المنتج')),
                TextField(controller: description, decoration: const InputDecoration(labelText: 'الوصف')),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  height: 164,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4EFEB),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE9E4DE)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: selectedImage != null
                      ? Image.file(File(selectedImage?.path ?? ''), fit: BoxFit.cover)
                      : (currentImageUrl != null && currentImageUrl.trim().isNotEmpty
                          ? Image.network(
                              currentImageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Icon(Icons.add_photo_alternate_outlined, size: 42, color: Color(0xFF9A8F87)),
                              ),
                            )
                          : const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add_photo_alternate_outlined, size: 42, color: Color(0xFF9A8F87)),
                                  SizedBox(height: 8),
                                  Text('أضف صورة واضحة للمنتج', style: TextStyle(color: Color(0xFF82766F))),
                                ],
                              ),
                            )),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      final picked = await ImagePicker().pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 85,
                        maxWidth: 1600,
                        maxHeight: 1600,
                      );
                      if (picked != null && dialogContext.mounted) {
                        setDialogState(() {
                          selectedImage = picked;
                          currentImageIsAiGenerated = false;
                        });
                      }
                    } catch (_) {
                      if (dialogContext.mounted) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(content: Text('تعذر فتح معرض الصور. تحقق من أذونات الهاتف.')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(selectedImage == null ? 'اختيار صورة من الهاتف' : 'تغيير الصورة'),
                ),
                if (product != null) ...[
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'لضمان مطابقة صورة المنتج لما سيشتريه الزبون، نقبل حالياً الصور الأصلية من التاجر أو المورد فقط. أوقفنا التوليد الآلي لصور المنتجات لأن النموذج قد ينتج شكلاً غير مطابق.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF82766F)),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                TextField(
                  controller: price,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'الثمن بالدرهم'),
                ),
                const SizedBox(height: 8),
                const Text(
                  'الصور المقبولة: JPG أو PNG أو WEBP · بحد أقصى 5 ميغابايت',
                  style: TextStyle(color: Colors.black54, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('إلغاء')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('حفظ المنتج')),
          ],
        ),
      ),
    );

    try {
      if (ok == true) {
        final parsedPrice = double.tryParse(price.text.replaceAll(',', '.'));
        if (name.text.trim().isEmpty || parsedPrice == null || parsedPrice <= 0) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('أدخل اسم المنتج وثمناً صحيحاً أكبر من صفر.')),
            );
          }
          return;
        }

        final imageUrl = selectedImage != null
            ? await _uploadProductImage(selectedImage!)
            : currentImageUrl;
        final values = <String, dynamic>{
          'name': name.text.trim(),
          'description': description.text.trim(),
          'price_mad': parsedPrice,
          'is_available': product?['is_available'] ?? true,
          'image_url': imageUrl,
          'image_is_ai_generated': selectedImage != null ? false : currentImageIsAiGenerated,
        };

        if (product == null) {
          values['store_id'] = store!['id'];
          await db.from('products').insert(values);
        } else {
          await db.from('products').update(values).eq('id', product['id']);
        }
        await load();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(selectedImage == null ? 'تم حفظ المنتج.' : 'تم حفظ المنتج وصورته بنجاح.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر حفظ المنتج: $e')),
        );
      }
    } finally {
      name.dispose();
      description.dispose();
      price.dispose();
    }
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
      Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFFEE343B), Color(0xFF94131A)],
          ),
          borderRadius: BorderRadius.circular(26),
          boxShadow: const [BoxShadow(color: Color(0x20A20F16), blurRadius: 24, offset: Offset(0, 12))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('JIB SIGNATURE  /  BUSINESS', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.1)),
        const Text('متجرك على JIB', style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 6), Text(store!['name']?.toString() ?? 'متجري', style: const TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900)),
        SwitchListTile(contentPadding: EdgeInsets.zero, value: store!['is_open'] == true, onChanged: toggleOpen, title: const Text('المتجر مفتوح لاستقبال الطلبات', style: TextStyle(color: Colors.white)), activeColor: Colors.white, activeTrackColor: Colors.green),
      ])),
      const SizedBox(height: 18), Row(children: [
        Expanded(child: _Metric(title: 'الطلبات', value: '${orders.length}')),
        const SizedBox(width: 10), Expanded(child: _Metric(title: 'المنتجات', value: '${products.length}')),
      ]),
      const SizedBox(height: 20), const Text('الطلبات الأخيرة', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
      const Text('يمكنك قبول الطلب أو رفضه، ثم تحديثه أثناء التحضير.', style: TextStyle(color: Colors.black54, fontSize: 12)),
      if (orders.isEmpty) const Card(child: ListTile(title: Text('لا توجد طلبات بعد'), subtitle: Text('ستظهر طلبات زبنائك هنا.')))
      else ...orders.take(10).map(orderCard),
      const SizedBox(height: 20), const Text('المنتجات', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
      if (products.isEmpty) const Card(child: ListTile(title: Text('أضف أول منتج لمتجرك'), subtitle: Text('استعمل زر «منتج جديد» أسفل الشاشة.')))
      else ...products.map((p) => Card(child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: _merchantProductImage(p['image_url']),
        title: Text(p['name'].toString(), style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${p['price_mad']} د.م', style: const TextStyle(color: jibRed, fontWeight: FontWeight.w800)),
            if (p['image_is_ai_generated'] == true)
              const Text('صورة مولدة بالذكاء الاصطناعي', style: TextStyle(fontSize: 10, color: Color(0xFF82766F))),
          ],
        ),
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
