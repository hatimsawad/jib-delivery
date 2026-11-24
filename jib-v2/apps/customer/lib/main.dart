import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _url = 'https://ldgbyshgcifheditplnn.supabase.co';
const _key = 'sb_publishable_wvNMRZTBFX4viI2ypcdWjQ_YBqgi_TV';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: _url, publishableKey: _key);
  runApp(const JibCustomerApp());
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
      boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 7, offset: Offset(0, 3))],
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

class JibCustomerApp extends StatelessWidget {
  const JibCustomerApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'JIB', debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE31E24), primary: const Color(0xFFE31E24), secondary: const Color(0xFF00843D), tertiary: const Color(0xFF00843D)),
      scaffoldBackgroundColor: const Color(0xFFF7F8F7), useMaterial3: true, fontFamily: 'Roboto',
    ),
    home: const CustomerHome(),
  );
}

class CustomerHome extends StatefulWidget {
  const CustomerHome({super.key});
  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  static const Set<String> _foodCategories = {
    'food','grocery','drinks','dairy','meat','produce','bakery','frozen-food',
    'breakfast','burgers','desserts','prepared-food','menus','fries','sauces','sharing',
    'wraps','mccafe','happy-meal','menu-mabrouk','duo-mabrouk',
    'moroccan-breakfast','salads',
  };

  SupabaseClient get _db => Supabase.instance.client;
  User? get _user => _db.auth.currentUser;
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  bool _register = false;
  int _tabIndex = 0;
  bool _busy = false;
  String? _error;
  String? _notice;
  String _search = '';
  String? _selectedCategory;
  List<Map<String,dynamic>> _brands = [];
  List<Map<String,dynamic>> _branches = [];
  List<Map<String,dynamic>> _catalogProducts = [];
  List<Map<String,dynamic>> _myOrders = [];
  String? _selectedBrand;
  String? _selectedBranch;
  String? _selectedBranchName;
  final Map<String,Map<String,dynamic>> _cart = {};
  StreamSubscription? _authSubscription;

  @override
  void initState() {
    super.initState();
    _loadPublicCatalog();
    _authSubscription = _db.auth.onAuthStateChange.listen((data) {
      if (!mounted) return;
      setState(() {
        if (data.event == AuthChangeEvent.signedOut) {
          _myOrders = [];
          _cart.clear();
          _notice = null;
        }
      });
      if (data.session != null) _loadCustomerData();
    });
    if (_user != null) _loadCustomerData();
  }

  List<String> get _catalogCategories => _catalogProducts.map((p) => p['category'] as String?).whereType<String>().toSet().toList()..sort();

  num? _customerReferencePrice(Map<String,dynamic> product) {
    final base = product['reference_price_mad'] as num?;
    if (base == null) return null;
    final notes = (product['reference_notes'] as String? ?? '').toLowerCase();
    final alreadyIncludesMarkup = notes.contains('(+2 mad)') ||
      notes.contains('jib reference price') ||
      notes.contains('سعر jib المرجعي') ||
      notes.contains('السعر المرجعي + 2') ||
      notes.contains('السعر المرجعي التاريخي + 2');
    return alreadyIncludesMarkup ? base : base + 2;
  }

  List<Map<String,dynamic>> get _filteredCatalogProducts => _catalogProducts.where((p) {
    final brandMatches = _selectedBrand == null || p['brand_id'] == _selectedBrand;
    final categoryMatches = _selectedCategory == null || p['category'] == _selectedCategory;
    final name = (p['name'] as String).toLowerCase();
    final searchMatches = _search.isEmpty || name.contains(_search) ||
      _brands.any((b) => b['id'] == p['brand_id'] && (b['name'] as String).toLowerCase().contains(_search));
    return brandMatches && categoryMatches && searchMatches;
  }).toList();

  String _categoryLabel(String category) {
    switch (category) {
      case 'burgers': return 'البرغر';
      case 'breakfast': return 'الفطور';
      case 'desserts': return 'الحلويات';
      case 'drinks': return 'المشروبات';
      case 'dairy': return 'الألبان';
      case 'meat': return 'اللحوم';
      case 'produce': return 'الخضر والفواكه';
      case 'bakery': return 'المخبوزات';
      case 'frozen-food': return 'المجمدات';
      case 'personal-care': return 'العناية الشخصية';
      case 'household': return 'المنزل';
      case 'grocery': return 'المواد الغذائية';
      case 'menus': return 'الوجبات';
      case 'prepared-food': return 'وجبات جاهزة';
      case 'fries': return 'البطاطس';
      case 'sauces': return 'الصلصات';
      case 'sharing': return 'للمشاركة';
      case 'wraps': return 'الراب';
      case 'mccafe': return 'مقهى';
      case 'happy-meal': return 'هابي ميل';
      default: return category.replaceAll('-', ' ');
    }
  }

  Future<void> _loadPublicCatalog() async {
    try {
      final brands = await _db.from('brands').select('id,name,slug,logo_url,category')
        .eq('is_approved',true).eq('is_active',true).order('name');
      final products = await _db.from('products')
        .select('id,brand_id,name,category,reference_price_mad,reference_notes,official_source_url,image_url')
        .eq('is_active',true).inFilter('category',_foodCategories.toList()).order('name');
      final foodBrandIds = List<Map<String,dynamic>>.from(products)
        .map((p) => p['brand_id'] as String?).whereType<String>().toSet();
      final activeApprovedBrandIds = List<Map<String,dynamic>>.from(brands)
        .map((b) => b['id'] as String).toSet();
      final visibleFoodBrandIds = foodBrandIds.intersection(activeApprovedBrandIds);
      final branches = await _db.from('branches')
        .select('id,name,address,city,merchant_id,merchants!inner(name,is_active,brand_id,is_direct_purchase)')
        .eq('is_active',true).eq('city','Rabat').eq('merchants.is_active',true)
        .eq('merchants.is_direct_purchase',true).order('name');
      if (!mounted) return;
      setState(() {
        _brands = List<Map<String,dynamic>>.from(brands)
          .where((b) => visibleFoodBrandIds.contains(b['id'])).toList();
        _catalogProducts = List<Map<String,dynamic>>.from(products)
          .where((p) => visibleFoodBrandIds.contains(p['brand_id'])).toList();
        _branches = List<Map<String,dynamic>>.from(branches);
      });
    } catch (e) {
      if (mounted) setState(() => _error = 'تعذر الاتصال بكتالوج JIB. تحقق من إعدادات واجهة البيانات.');
    }
  }

  Future<void> _loadCustomerData() async {
    if (_user == null) return;
    try {
      final rows = await _db.from('orders')
        .select('id,status,submitted_at,subtotal_mad,delivery_fee_mad,delivery_address,eta_minutes,courier_offered_at,courier_accepted_at,picked_up_at,en_route_at,delivered_at')
        .eq('customer_id',_user!.id).order('submitted_at',ascending:false).limit(20);
      if (mounted) setState(() => _myOrders = List<Map<String,dynamic>>.from(rows));
    } catch (_) {}
  }

  Future<void> _authenticate() async {
    setState(() { _busy = true; _error = null; _notice = null; });
    try {
      if (_register) {
        final result = await _db.auth.signUp(
          email: _email.text.trim(), password: _password.text,
          data: {'full_name':_name.text.trim(),'phone':_phone.text.trim()},
        );
        if (result.session == null) {
          setState(() => _notice = 'تم إنشاء الحساب. تحقق من بريدك الإلكتروني لتأكيده ثم سجّل الدخول.');
        } else {
          await _loadCustomerData();
          if (mounted) setState(() {});
        }
      } else {
        await _db.auth.signInWithPassword(email:_email.text.trim(),password:_password.text);
        await _loadCustomerData();
        if (mounted) setState(() {});
      }
    } on AuthException catch (e) { setState(() => _error = e.message); }
    catch (e) { setState(() => _error = 'تعذر إكمال تسجيل الدخول.'); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _chooseBranch(Map<String,dynamic> branch) async {
    final merchant = branch['merchants'] as Map?;
    final storeBrandId = merchant?['brand_id'] as String?;
    if (storeBrandId == null) { setState(() => _error = 'هذا الفرع غير مرتبط بعلامة تجارية في JIB.'); return; }
    final hasOtherBrand = _cart.values.any((row) => (row['product'] as Map)['brand_id'] != storeBrandId);
    if (hasOtherBrand) { setState(() => _error = 'الطلب الواحد يكون من متجر واحد. أفرغ السلة قبل تغيير المتجر.'); return; }
    setState(() {
      _selectedBranch = branch['id'] as String;
      _selectedBranchName = branch['name'] as String;
      _selectedBrand = storeBrandId;
      _error = null;
      _notice = 'تم اختيار $_selectedBranchName. المندوب سيشتري المنتجات من هذا الفرع.';
    });
  }

  void _addToCart(Map<String,dynamic> product) {
    final id = product['id'] as String;
    final price = _customerReferencePrice(product);
    if (price == null) { setState(() => _error = 'لا يمكن إضافة المنتج لأن سعره المرجعي غير متوفر.'); return; }
    final brandId = product['brand_id'] as String?;
    if (brandId == null) { setState(() => _error = 'هذا المنتج غير مرتبط بمتجر معتمد.'); return; }
    final hasOtherBrand = _cart.values.any((row) => (row['product'] as Map)['brand_id'] != brandId);
    if (hasOtherBrand) { setState(() => _error = 'الطلب الواحد يكون من متجر واحد. أفرغ السلة قبل إضافة منتجات متجر آخر.'); return; }
    if (_selectedBranch != null) {
      final selected = _branches.where((b) => b['id'] == _selectedBranch).toList();
      final selectedBrandId = selected.isEmpty ? null : (selected.first['merchants'] as Map?)?['brand_id'];
      if (selectedBrandId != brandId) { setState(() => _error = 'المنتج لا ينتمي إلى فرع الشراء المحدد.'); return; }
    }
    final existing = _cart[id];
    setState(() {
      _selectedBrand = brandId;
      _error = null;
      _cart[id] = {'product': product, 'price_mad': price, 'quantity': ((existing?['quantity'] as int?) ?? 0) + 1};
      _notice = 'تمت إضافة ${product['name']} إلى السلة.';
    });
  }

  void _changeQuantity(String id, int delta) {
    final current = _cart[id];
    if (current == null) return;
    final next = (current['quantity'] as int) + delta;
    setState(() {
      if (next <= 0) { _cart.remove(id); }
      else { _cart[id] = {...current,'quantity':next}; }
    });
  }

  num get _subtotal => _cart.values.fold<num>(0,(sum,row) =>
    sum + ((row['price_mad'] as num?) ?? 0) * (row['quantity'] as int));

  Future<void> _submitOrder() async {
    if (_user == null) { setState(() => _error = 'سجّل الدخول أولاً لإرسال الطلب.'); return; }
    if (_selectedBranch == null || _cart.isEmpty) { setState(() => _error = 'أضف المنتجات واختر فرع الشراء في الرباط.'); return; }
    if (_address.text.trim().length < 5 || _phone.text.trim().length < 8) { setState(() => _error = 'أدخل عنوان التوصيل ورقم هاتف صحيحاً.'); return; }
    setState(() { _busy = true; _error = null; _notice = null; });
    try {
      final items = _cart.entries.map((e) => {'product_id': e.key, 'quantity': e.value['quantity']}).toList();
      final orderId = await _db.rpc('submit_purchase_order',params:{
        'p_branch_id':_selectedBranch,
        'p_delivery_address':_address.text.trim(),
        'p_customer_phone':_phone.text.trim(),
        'p_items':items,
        'p_customer_note':null,
        'p_delivery_latitude':null,
        'p_delivery_longitude':null,
      });
      setState(() { _cart.clear(); _notice = 'تم إرسال طلب الشراء بنجاح. رقم الطلب: ${orderId.toString().substring(0,8)}'; });
      await _loadCustomerData();
    } on PostgrestException catch (e) { setState(() => _error = e.message); }
    catch (e) { setState(() => _error = e.toString().replaceFirst('Exception: ', '')); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _sendPasswordReset() async {
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'أدخل بريدك الإلكتروني أولاً لإرسال رابط استعادة كلمة المرور.');
      return;
    }
    setState(() { _busy = true; _error = null; _notice = null; });
    try {
      await _db.auth.resetPasswordForEmail(email);
      if (mounted) setState(() => _notice = 'إذا كان البريد مسجلاً، فستصلك رسالة لاستعادة كلمة المرور. افحص البريد غير المرغوب فيه أيضاً.');
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signOut() async {
    await _db.auth.signOut();
    setState(() { _myOrders=[]; _cart.clear(); _notice=null; });
  }

  String _status(String value) => switch(value) {
    'customer_submitted'=>'تم إرسال الطلب','merchant_accepted'=>'قبله المتجر','merchant_rejected'=>'رفضه المتجر',
    'preparing'=>'قيد التحضير','ready_for_pickup'=>'جاهز للاستلام','courier_offered'=>'جارٍ البحث عن مندوب',
    'courier_accepted'=>'تم قبول المندوب','picked_up'=>'استلمه المندوب','en_route'=>'في الطريق إليك',
    'delivered'=>'تم التسليم','cancelled'=>'ملغى',_=>value,
  };

  @override
  void dispose() {
    _authSubscription?.cancel();
    _email.dispose();_password.dispose();_name.dispose();_phone.dispose();_address.dispose();super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final productWidth = width < 390 ? 154.0 : 174.0;
    Widget titleRow(String title, {String? action, VoidCallback? onAction}) => Row(children: [
      Expanded(child: Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Color(0xFF18231D)))),
      if (action != null) TextButton(onPressed: onAction, child: Text(action, style: const TextStyle(color: Color(0xFF00843D), fontWeight: FontWeight.w800))),
    ]);
    Widget productCard(Map<String,dynamic> p) {
      final price = _customerReferencePrice(p);
      final image = (p['image_url'] as String?)?.trim();
      final brand = _brands.where((b) => b['id'] == p['brand_id']).toList();
      return SizedBox(width: productWidth, child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE8ECE8)), boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 5))]),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Stack(children: [
            Container(height: 128, width: double.infinity, color: const Color(0xFFF4F6F2), child: image == null || image.isEmpty
              ? const Icon(Icons.fastfood_rounded, size: 46, color: Color(0xFFB7C8BA))
              : Image.network(image, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.fastfood_rounded, size: 46, color: Color(0xFFB7C8BA)))),
            Positioned(top: 8, right: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: Colors.white.withOpacity(.94), borderRadius: BorderRadius.circular(30)), child: const Text('JIB', style: TextStyle(color: Color(0xFFE31E24), fontWeight: FontWeight.w900, fontSize: 10)))),
          ]),
          Padding(padding: const EdgeInsets.all(11), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p['name'] as String, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, height: 1.2)),
            const SizedBox(height: 4),
            Text(brand.isEmpty ? 'JIB' : brand.first['name'] as String, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: Color(0xFF78837B))),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: Text(price == null ? 'السعر غير متوفر' : price.toStringAsFixed(2) + ' د.م', style: const TextStyle(color: Color(0xFF00843D), fontWeight: FontWeight.w900, fontSize: 13))),
              InkWell(onTap: price == null ? null : () => _addToCart(p), borderRadius: BorderRadius.circular(11), child: Container(width: 34, height: 34, decoration: BoxDecoration(color: price == null ? const Color(0xFFE8ECE8) : const Color(0xFFE31E24), borderRadius: BorderRadius.circular(11)), child: const Icon(Icons.add_rounded, color: Colors.white))),
            ]),
          ])),
        ]),
      ));
    }
    Widget branchTile(Map<String,dynamic> b) {
      final selected = _selectedBranch == b['id'];
      return Container(margin: const EdgeInsets.only(bottom: 9), decoration: BoxDecoration(color: selected ? const Color(0xFFEAF5ED) : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: selected ? const Color(0xFF00843D) : const Color(0xFFE7ECE8))), child: ListTile(
        onTap: _busy ? null : () => _chooseBranch(b),
        leading: Container(width: 42, height: 42, decoration: BoxDecoration(color: const Color(0xFFFFEEEE), borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.storefront_rounded, color: Color(0xFFE31E24))),
        title: Text(b['name'] as String, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
        subtitle: Text((b['address'] ?? '').toString() + ' — ' + (b['city'] ?? '').toString(), maxLines: 2, style: const TextStyle(fontSize: 11)),
        trailing: Icon(selected ? Icons.check_circle_rounded : Icons.chevron_left_rounded, color: const Color(0xFF00843D)),
      ));
    }
    Widget homePage() => RefreshIndicator(onRefresh: _loadPublicCatalog, child: ListView(padding: const EdgeInsets.fromLTRB(16, 10, 16, 24), children: [
      Container(padding: const EdgeInsets.fromLTRB(18, 17, 18, 19), decoration: BoxDecoration(gradient: const LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [Color(0xFFE31E24), Color(0xFFB91720), Color(0xFF00843D)]), borderRadius: BorderRadius.circular(26), boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 18, offset: Offset(0, 8))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [const _JibMark(size: 50), const SizedBox(width: 11), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('JIB', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: 1.2)), Text('Jib وتكايس على jib', style: TextStyle(color: Color(0xFFFFE6E6), fontSize: 11, fontWeight: FontWeight.w700))])), Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7), decoration: BoxDecoration(color: Colors.white.withOpacity(.16), borderRadius: BorderRadius.circular(30)), child: const Row(children: [Icon(Icons.location_on_rounded, color: Colors.white, size: 14), SizedBox(width: 4), Text('الرباط', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11))]))]),
        const SizedBox(height: 22),
        const Text('كل شي تحبه\nفي مكان واحد', style: TextStyle(color: Colors.white, fontSize: 27, height: 1.12, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        const Text('اختار اللي بغيتي، وجيبها حتى لباب دارك.', style: TextStyle(color: Color(0xFFFFF1E8), fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 17),
        Container(height: 46, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)), child: TextField(decoration: const InputDecoration(hintText: 'شنو باغي اليوم؟', hintStyle: TextStyle(fontSize: 13), prefixIcon: Icon(Icons.search_rounded, color: Color(0xFFE31E24)), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 13)), onChanged: (v) => setState(() => _search = v.trim().toLowerCase()))),
      ])),
      if (_error != null) _message(_error!, true),
      if (_notice != null) _message(_notice!, false),
      const SizedBox(height: 22),
      titleRow('تسوق حسب القسم'),
      const SizedBox(height: 12),
      SizedBox(height: 91, child: ListView(scrollDirection: Axis.horizontal, children: [
        _categoryBubble('الكل', Icons.grid_view_rounded, _selectedCategory == null, () => setState(() => _selectedCategory = null)),
        ..._catalogCategories.map((c) => _categoryBubble(_categoryLabel(c), _categoryIcon(c), _selectedCategory == c, () => setState(() => _selectedCategory = _selectedCategory == c ? null : c)),
      ])),
      const SizedBox(height: 18),
      titleRow('علامات تجارية مختارة', action: 'عرض الكل', onAction: () => setState(() => _tabIndex = 1)),
      const SizedBox(height: 11),
      SizedBox(height: 91, child: _brands.isEmpty ? const _InfoPanel('ستظهر العلامات التجارية المعتمدة هنا.') : ListView(scrollDirection: Axis.horizontal, children: _brands.take(12).map((b) {
        final logo = (b['logo_url'] as String?)?.trim();
        return GestureDetector(onTap: () => setState(() { _selectedBrand = b['id'] as String; _tabIndex = 1; }), child: SizedBox(width: 82, child: Column(children: [
          Container(width: 58, height: 58, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE8ECE8))), child: ClipRRect(borderRadius: BorderRadius.circular(17), child: logo == null || logo.isEmpty ? Center(child: Text((b['name'] as String).substring(0,1), style: const TextStyle(color: Color(0xFFE31E24), fontSize: 22, fontWeight: FontWeight.w900))) : Image.network(logo, fit: BoxFit.contain, errorBuilder: (_,__,___) => const Icon(Icons.storefront_rounded, color: Color(0xFF00843D))))),
          const SizedBox(height: 5), Text(b['name'] as String, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
        ])));
      }).toList())),
      const SizedBox(height: 20),
      titleRow('الأكثر طلباً', action: 'كل المنتجات', onAction: () => setState(() { _selectedCategory = null; _selectedBrand = null; _tabIndex = 1; })),
      const SizedBox(height: 12),
      if (_catalogProducts.isEmpty) const _InfoPanel('يتم تحميل المنتجات أو لا توجد منتجات معتمدة حالياً.'),
      if (_filteredCatalogProducts.isEmpty && _catalogProducts.isNotEmpty) const _InfoPanel('لا توجد نتائج مطابقة لبحثك.'),
      if (_filteredCatalogProducts.isNotEmpty) SizedBox(height: 255, child: ListView(scrollDirection: Axis.horizontal, children: _filteredCatalogProducts.take(12).map((p) => Padding(padding: const EdgeInsets.only(left: 11), child: productCard(p))).toList())),
      const SizedBox(height: 18),
      Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: const Color(0xFFEAF5ED), borderRadius: BorderRadius.circular(18)), child: const Row(children: [Icon(Icons.delivery_dining_rounded, color: Color(0xFF00843D), size: 34), SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('التوصيل مع JIB', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF174C2A))), SizedBox(height: 3), Text('المندوب يشتري طلبك بنفسه من الفرع الذي تختاره.', style: TextStyle(fontSize: 11, color: Color(0xFF42634C)))]))])),
    ]));

    Widget storesPage() => ListView(padding: const EdgeInsets.fromLTRB(16, 18, 16, 24), children: [
      const Text('المتاجر والمنتجات', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
      const SizedBox(height: 5), const Text('تصفح العلامات التجارية والمنتجات الغذائية المتاحة.', style: TextStyle(color: Color(0xFF78837B), fontSize: 12)),
      const SizedBox(height: 15),
      TextField(decoration: InputDecoration(hintText: 'ابحث عن منتج أو متجر', prefixIcon: const Icon(Icons.search), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)), onChanged: (v) => setState(() => _search = v.trim().toLowerCase())),
      const SizedBox(height: 14),
      Wrap(spacing: 8, runSpacing: 8, children: [ChoiceChip(label: const Text('كل الأقسام'), selected: _selectedCategory == null, onSelected: (_) => setState(() => _selectedCategory = null)), ..._catalogCategories.map((c) => ChoiceChip(label: Text(_categoryLabel(c)), selected: _selectedCategory == c, onSelected: (_) => setState(() => _selectedCategory = _selectedCategory == c ? null : c))]),
      const SizedBox(height: 16),
      titleRow('العلامات التجارية'),
      const SizedBox(height: 8),
      ..._brands.map((b) => Card(elevation: 0, color: _selectedBrand == b['id'] ? const Color(0xFFEAF5ED) : Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), child: ListTile(onTap: () => setState(() => _selectedBrand = _selectedBrand == b['id'] ? null : b['id'] as String), leading: const CircleAvatar(backgroundColor: Color(0xFFFFEEEE), child: Icon(Icons.storefront_rounded, color: Color(0xFFE31E24))), title: Text(b['name'] as String, style: const TextStyle(fontWeight: FontWeight.w800)), trailing: Icon(_selectedBrand == b['id'] ? Icons.check_circle : Icons.chevron_left, color: const Color(0xFF00843D)))),
      const SizedBox(height: 15),
      titleRow('المنتجات (' + _filteredCatalogProducts.length.toString() + ')'),
      const SizedBox(height: 10),
      Wrap(spacing: 10, runSpacing: 12, children: _filteredCatalogProducts.map(productCard).toList()),
      const SizedBox(height: 18),
      titleRow('اختر فرع الشراء'),
      const SizedBox(height: 8),
      if (_branches.isEmpty) const _InfoPanel('لا توجد فروع نشطة تستقبل الطلبات حالياً.'),
      ..._branches.map(branchTile),
    ]);

    Widget cartPage() => ListView(padding: const EdgeInsets.fromLTRB(16, 18, 16, 28), children: [
      const Text('سلة مشترياتك', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
      const SizedBox(height: 5), const Text('راجع اختياراتك قبل إرسال الطلب.', style: TextStyle(color: Color(0xFF78837B), fontSize: 12)),
      const SizedBox(height: 18),
      if (_cart.isEmpty) Container(padding: const EdgeInsets.symmetric(vertical: 38, horizontal: 20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)), child: const Column(children: [Icon(Icons.shopping_bag_outlined, size: 54, color: Color(0xFFB8C6BC)), SizedBox(height: 12), Text('السلة فارغة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)), SizedBox(height: 5), Text('أضف المنتجات التي تريدها وسنضعها هنا.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF78837B), fontSize: 12))])),
      ..._cart.entries.map((e) {
        final p = Map<String,dynamic>.from(e.value['product'] as Map);
        final img = (p['image_url'] as String?)?.trim();
        return Container(margin: const EdgeInsets.only(bottom: 9), padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(17), border: Border.all(color: const Color(0xFFE8ECE8))), child: Row(children: [
          ClipRRect(borderRadius: BorderRadius.circular(12), child: SizedBox(width: 64, height: 64, child: img == null || img.isEmpty ? const ColoredBox(color: Color(0xFFF3F5F2), child: Icon(Icons.fastfood, color: Color(0xFF9EAD9F))) : Image.network(img, fit: BoxFit.cover, errorBuilder: (_,__,___) => const ColoredBox(color: Color(0xFFF3F5F2), child: Icon(Icons.fastfood, color: Color(0xFF9EAD9F)))))),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(p['name'] as String, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)), const SizedBox(height: 5), Text(e.value['price_mad'].toString() + ' د.م', style: const TextStyle(color: Color(0xFF00843D), fontWeight: FontWeight.w900))])),
          Row(mainAxisSize: MainAxisSize.min, children: [IconButton(visualDensity: VisualDensity.compact, onPressed: () => _changeQuantity(e.key, -1), icon: const Icon(Icons.remove_circle_outline, size: 20)), Text(e.value['quantity'].toString(), style: const TextStyle(fontWeight: FontWeight.w900)), IconButton(visualDensity: VisualDensity.compact, onPressed: () => _changeQuantity(e.key, 1), icon: const Icon(Icons.add_circle, color: Color(0xFFE31E24), size: 20))]),
        ]));
      }),
      if (_cart.isNotEmpty) ...[
        Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)), child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('المجموع الفرعي', style: TextStyle(color: Color(0xFF68756C))), Text(_subtotal.toStringAsFixed(2) + ' د.م', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17))]),
          const SizedBox(height: 7), const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('رسوم التوصيل', style: TextStyle(color: Color(0xFF68756C))), Text('تحدد حسب المسافة', style: TextStyle(color: Color(0xFF9A6B20), fontWeight: FontWeight.w800, fontSize: 11))]),
        ])),
        const SizedBox(height: 14),
        const Text('فرع الشراء', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
        const SizedBox(height: 7),
        if (_selectedBranch == null) const _InfoPanel('اختر فرع الشراء قبل إرسال الطلب.'),
        ..._branches.where((b) { final m = b['merchants'] as Map?; return _cart.values.every((r) => (r['product'] as Map)['brand_id'] == m?['brand_id']); }).map(branchTile),
        const SizedBox(height: 12),
        TextField(controller: _address, maxLines: 2, decoration: InputDecoration(labelText: 'عنوان التوصيل بالتفصيل', prefixIcon: const Icon(Icons.location_on_outlined), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none))),
        const SizedBox(height: 10),
        TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: 'رقم الهاتف', prefixIcon: const Icon(Icons.phone_outlined), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none))),
        const SizedBox(height: 13),
        SizedBox(height: 52, child: FilledButton.icon(onPressed: _busy || _selectedBranch == null ? null : _submitOrder, icon: const Icon(Icons.check_circle_outline), label: Text(_busy ? 'جارٍ إرسال الطلب...' : 'إرسال طلب الشراء'), style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE31E24), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))))),
        const SizedBox(height: 8), const Text('رسوم التوصيل تُحدد حسب المسافة؛ لا يظهر الإجمالي النهائي قبل اعتمادها.', style: TextStyle(fontSize: 10, color: Color(0xFF78837B))),
      ],
    ]);

    Widget ordersPage() => ListView(padding: const EdgeInsets.fromLTRB(16, 18, 16, 28), children: [
      const Text('طلباتي', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
      const SizedBox(height: 5), const Text('تابع حالة مشترياتك خطوة بخطوة.', style: TextStyle(color: Color(0xFF78837B), fontSize: 12)),
      const SizedBox(height: 15),
      if (_user == null) Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), child: Column(children: [const Icon(Icons.person_outline, size: 45, color: Color(0xFF00843D)), const SizedBox(height: 10), const Text('سجل الدخول لمتابعة طلباتك', style: TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height: 10), FilledButton(onPressed: _showAuth, child: const Text('تسجيل الدخول'))])),
      if (_user != null && _myOrders.isEmpty) const _InfoPanel('لا توجد طلبات بعد. ابدأ التسوق واكتشف منتجات JIB.'),
      ..._myOrders.map((o) => Container(margin: const EdgeInsets.only(bottom: 11), padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE8ECE8))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Expanded(child: Text('طلب #' + (o['id'] as String).substring(0,8), style: const TextStyle(fontWeight: FontWeight.w900))), Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: const Color(0xFFEAF5ED), borderRadius: BorderRadius.circular(30)), child: Text(_status(o['status'] as String), style: const TextStyle(color: Color(0xFF00843D), fontSize: 10, fontWeight: FontWeight.w900)))]),
        const Divider(height: 20),
        Text('المنتجات: ' + o['subtotal_mad'].toString() + ' د.م', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
        Text('التوصيل: ' + (o['delivery_fee_mad'] == null ? 'قيد التحديد' : o['delivery_fee_mad'].toString() + ' د.م'), style: const TextStyle(fontSize: 12, color: Color(0xFF68756C))),
        Text('مضى على الطلب ' + DateTime.now().difference(DateTime.parse(o['submitted_at'] as String)).inMinutes.toString() + ' دقيقة', style: const TextStyle(fontSize: 11, color: Color(0xFF78837B))),
        const SizedBox(height: 10),
        ...[['merchant_accepted_at','قبول المتجر'],['preparation_started_at','بدء التحضير'],['preparation_completed_at','اكتمال التحضير'],['courier_offered_at','البحث عن مندوب'],['courier_accepted_at','قبول المندوب'],['picked_up_at','استلام الطلب'],['en_route_at','بدء التوصيل'],['delivered_at','التسليم']].where((s) => o[s[0]] != null).map((s) => Padding(padding: const EdgeInsets.only(bottom: 4), child: Row(children: [const Icon(Icons.check_circle, color: Color(0xFF00843D), size: 14), const SizedBox(width: 7), Text(s[1] + ' • ' + DateTime.parse(o[s[0]] as String).toLocal().toString(), style: const TextStyle(fontSize: 10, color: Color(0xFF68756C)))]))),
      ]))),
    ]);

    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      backgroundColor: const Color(0xFFF6F7F4),
      appBar: AppBar(backgroundColor: const Color(0xFFF6F7F4), surfaceTintColor: Colors.transparent, elevation: 0, title: Row(children: [const _JibMark(size: 38), const SizedBox(width: 9), const Text('JIB', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)), const Spacer(), IconButton(onPressed: _loadPublicCatalog, icon: const Icon(Icons.refresh_rounded)), IconButton(onPressed: _user == null ? _showAuth : _signOut, icon: Icon(_user == null ? Icons.person_outline_rounded : Icons.logout_rounded))])),
      body: IndexedStack(index: _tabIndex, children: [homePage(), storesPage(), cartPage(), ordersPage()]),
      bottomNavigationBar: NavigationBar(height: 68, backgroundColor: Colors.white, indicatorColor: const Color(0xFFFFE8E8), selectedIndex: _tabIndex, onDestinationSelected: (i) => setState(() => _tabIndex = i), destinations: [
        const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded, color: Color(0xFFE31E24)), label: 'الرئيسية'),
        const NavigationDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront_rounded, color: Color(0xFFE31E24)), label: 'المتاجر'),
        NavigationDestination(icon: Badge(isLabelVisible: _cart.isNotEmpty, label: Text(_cart.length.toString()), child: const Icon(Icons.shopping_bag_outlined)), selectedIcon: const Icon(Icons.shopping_bag_rounded, color: Color(0xFFE31E24)), label: 'السلة'),
        const NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long_rounded, color: Color(0xFFE31E24)), label: 'طلباتي'),
      ]),
    ));
  }

  Widget _categoryBubble(String label, IconData icon, bool selected, VoidCallback onTap) => GestureDetector(onTap: onTap, child: Container(width: 76, margin: const EdgeInsets.only(left: 9), child: Column(children: [
    Container(width: 58, height: 58, decoration: BoxDecoration(color: selected ? const Color(0xFFE31E24) : Colors.white, borderRadius: BorderRadius.circular(19), border: Border.all(color: selected ? const Color(0xFFE31E24) : const Color(0xFFE8ECE8))), child: Icon(icon, color: selected ? Colors.white : const Color(0xFF00843D), size: 25)),
    const SizedBox(height: 6), Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: selected ? const Color(0xFFE31E24) : const Color(0xFF536057))),
  ])));

  IconData _categoryIcon(String c) => switch(c) {
    'burgers' => Icons.lunch_dining_rounded,
    'breakfast' || 'moroccan-breakfast' => Icons.egg_alt_rounded,
    'desserts' => Icons.cake_rounded,
    'drinks' => Icons.local_cafe_rounded,
    'bakery' => Icons.bakery_dining_rounded,
    'meat' => Icons.set_meal_rounded,
    'produce' => Icons.eco_rounded,
    'menus' || 'prepared-food' => Icons.restaurant_menu_rounded,
    'fries' => Icons.fastfood_rounded,
    _ => Icons.restaurant_rounded,
  };

  void _showAuth() => showModalBottomSheet(
    context:context,isScrollControlled:true,builder:(ctx)=>StatefulBuilder(builder:(ctx,setSheet)=>Padding(
      padding:EdgeInsets.fromLTRB(20,20,20,MediaQuery.of(ctx).viewInsets.bottom+20),
      child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
        Text(_register?'إنشاء حساب زبون':'تسجيل الدخول',style:const TextStyle(fontSize:20,fontWeight:FontWeight.bold)),
        if (_register) TextField(controller:_name,decoration:const InputDecoration(labelText:'الاسم الكامل')),
        TextField(controller:_email,keyboardType:TextInputType.emailAddress,decoration:const InputDecoration(labelText:'البريد الإلكتروني')),
        TextField(controller:_password,obscureText:true,decoration:const InputDecoration(labelText:'كلمة المرور')),
        if (_register) TextField(controller:_phone,keyboardType:TextInputType.phone,decoration:const InputDecoration(labelText:'رقم الهاتف')),
        if (!_register) Align(alignment:Alignment.centerLeft,child:TextButton(onPressed:_busy?null:()async{await _sendPasswordReset();setSheet(()=>{});},child:const Text('نسيت كلمة المرور؟'))),
        const SizedBox(height:12),
        FilledButton(onPressed:_busy?null:()async{await _authenticate();if(ctx.mounted && _user!=null)Navigator.pop(ctx);setSheet(()=>{});},
          child:Text(_busy?'جارٍ التنفيذ...':_register?'إنشاء الحساب':'دخول')),
        TextButton(onPressed:()=>setSheet(()=>_register=!_register),
          child:Text(_register?'لدي حساب بالفعل':'إنشاء حساب جديد')),
        if (_error!=null) Text(_error!,style:const TextStyle(color:Colors.red)),
        if (_notice!=null) Text(_notice!,style:const TextStyle(color:Colors.green)),
      ])),
    )),
  );

  Widget _message(String value,bool isError)=>Container(
    margin:const EdgeInsets.only(top:12),padding:const EdgeInsets.all(12),
    decoration:BoxDecoration(color:isError?const Color(0xFFFFEEEE):const Color(0xFFE8F5E9),borderRadius:BorderRadius.circular(12)),
    child:Text(value,style:TextStyle(color:isError?Colors.red:Colors.green.shade800)),
  );
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel(this.message);
  final String message;
  @override
  Widget build(BuildContext context)=>Container(
    margin:const EdgeInsets.symmetric(vertical:6),padding:const EdgeInsets.all(14),
    decoration:BoxDecoration(color:const Color(0xFFEFF3FA),borderRadius:BorderRadius.circular(14)),
    child:Text(message,style:const TextStyle(color:Color(0xFF34415E))),
  );
}
