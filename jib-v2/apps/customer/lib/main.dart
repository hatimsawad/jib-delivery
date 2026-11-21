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
  SupabaseClient get _db => Supabase.instance.client;
  User? get _user => _db.auth.currentUser;
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  bool _register = false;
  bool _busy = false;
  String? _error;
  String? _notice;
  String _search = '';
  String? _selectedCategory;
  List<Map<String,dynamic>> _brands = [];
  List<Map<String,dynamic>> _branches = [];
  List<Map<String,dynamic>> _catalogProducts = [];
  List<Map<String,dynamic>> _branchProducts = [];
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
        .select('id,brand_id,name,category,reference_price_mad,official_source_url,image_url')
        .eq('is_active',true).order('name');
      final branches = await _db.from('branches')
        .select('id,name,address,city,merchant_id,merchants!inner(name,is_active)')
        .eq('is_active',true).eq('merchants.is_active',true).order('name');
      if (!mounted) return;
      setState(() {
        _brands = List<Map<String,dynamic>>.from(brands);
        _catalogProducts = List<Map<String,dynamic>>.from(products);
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
        .select('id,status,submitted_at,subtotal_mad,delivery_address,eta_minutes,merchant_accepted_at,preparation_started_at,preparation_completed_at,courier_offered_at,courier_accepted_at,picked_up_at,en_route_at,delivered_at')
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
    setState(() {
      _selectedBranch = branch['id'] as String;
      _selectedBranchName = branch['name'] as String;
      _branchProducts = [];
      _cart.clear();
      _busy = true;
      _error = null;
    });
    try {
      final rows = await _db.from('branch_products')
        .select('id,price_mad,availability,products!inner(id,name,category,brand_id,image_url)')
        .eq('branch_id',_selectedBranch!).eq('is_active',true)
        .eq('availability','available').eq('products.is_active',true).order('id');
      if (mounted) setState(() => _branchProducts = List<Map<String,dynamic>>.from(rows));
    } catch (e) {
      if (mounted) setState(() => _error = 'تعذر تحميل منتجات هذا الفرع.');
    } finally { if (mounted) setState(() => _busy = false); }
  }

  void _addToCart(Map<String,dynamic> row) {
    final id = row['id'] as String;
    final existing = _cart[id];
    setState(() {
      _cart[id] = {
        ...row,
        'quantity': ((existing?['quantity'] as int?) ?? 0) + 1,
      };
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
    if (_selectedBranch == null || _cart.isEmpty) { setState(() => _error = 'اختر فرعاً وأضف منتجات متاحة.'); return; }
    setState(() { _busy = true; _error = null; _notice = null; });
    try {
      final items = _cart.entries.map((e) => {
        'branch_product_id':e.key,'quantity':e.value['quantity'],
      }).toList();
      final orderId = await _db.rpc('submit_order',params:{
        'p_branch_id':_selectedBranch,
        'p_delivery_address':_address.text.trim(),
        'p_customer_phone':_phone.text.trim(),
        'p_items':items,
        'p_customer_note':null,
        'p_delivery_latitude':null,
        'p_delivery_longitude':null,
      });
      setState(() {
        _cart.clear();
        _notice = 'تم إرسال الطلب بنجاح. رقم الطلب: ${orderId.toString().substring(0,8)}';
      });
      await _loadCustomerData();
    } on PostgrestException catch (e) { setState(() => _error = e.message); }
    catch (e) { setState(() => _error = 'لم يتم إرسال الطلب. تحقق من توفر الفرع والمنتجات.'); }
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
  Widget build(BuildContext context) => Directionality(
    textDirection:TextDirection.rtl,
    child:Scaffold(
      appBar:AppBar(
        title:const Row(mainAxisSize:MainAxisSize.min,children:[_JibMark(size:38),SizedBox(width:9),Text('جيب JIB',style:TextStyle(fontWeight:FontWeight.w900))]),
        backgroundColor:Colors.white,surfaceTintColor:Colors.white,
        actions:[
          IconButton(onPressed:_loadPublicCatalog,icon:const Icon(Icons.refresh)),
          IconButton(onPressed:_user==null?_showAuth:_signOut,icon:Icon(_user==null?Icons.person_outline:Icons.logout)),
        ],
      ),
      body:ListView(padding:const EdgeInsets.fromLTRB(16,16,16,30),children:[
        Container(
          padding:const EdgeInsets.all(20),
          decoration:BoxDecoration(gradient:const LinearGradient(colors:[Color(0xFFE31E24),Color(0xFF00843D)]),border:Border.all(color:const Color(0xFF00843D)),borderRadius:BorderRadius.circular(22)),
          child:const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Row(children:[_JibMark(size:58),SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('JIB',style:TextStyle(color:Colors.white,fontSize:24,fontWeight:FontWeight.w900)),Text('Jib وتكايس على jib',style:TextStyle(color:Colors.white70,fontSize:13,fontWeight:FontWeight.w700))]))]),
            SizedBox(height:16),
            Text('كل شي تحبه في مكان واحد',style:TextStyle(color:Colors.white,fontSize:22,fontWeight:FontWeight.w900)),
            SizedBox(height:8),
            Text('تسوق من العلامات والمتاجر القريبة منك في الرباط وتمارة',style:TextStyle(color:Color(0xFFFFF4DC))),
          ]),
        ),
        if (_error!=null) _message(_error!,true),
        if (_notice!=null) _message(_notice!,false),
        const SizedBox(height:18),
        TextField(
          decoration:InputDecoration(hintText:'ابحث عن منتج أو علامة تجارية',prefixIcon:const Icon(Icons.search),filled:true,fillColor:Colors.white,
            border:OutlineInputBorder(borderRadius:BorderRadius.circular(14),borderSide:BorderSide.none)),
          onChanged:(v)=>setState(()=>_search=v.trim().toLowerCase()),
        ),
        const SizedBox(height:14),
        const Text('تسوق حسب القسم',style:TextStyle(fontSize:18,fontWeight:FontWeight.w900)),
        const SizedBox(height:8),
        Wrap(spacing:8,runSpacing:8,children:[
          ChoiceChip(label:const Text('الكل'),selected:_selectedCategory==null,onSelected:(_)=>setState(()=>_selectedCategory=null),
            selectedColor:const Color(0xFFE2F1E7),labelStyle:const TextStyle(fontWeight:FontWeight.bold)),
          ..._catalogCategories.map((category)=>ChoiceChip(
            label:Text(_categoryLabel(category)),selected:_selectedCategory==category,
            onSelected:(selected)=>setState(()=>_selectedCategory=selected?category:null),
            selectedColor:const Color(0xFFE2F1E7),labelStyle:const TextStyle(fontWeight:FontWeight.bold),
          )),
        ]),
        const SizedBox(height:16),
        Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
          const Text('اكتشف المنتجات',style:TextStyle(fontSize:19,fontWeight:FontWeight.w900)),
          Text('${_filteredCatalogProducts.length} منتج',style:const TextStyle(color:Color(0xFF65736A))),
        ]),
        if (_catalogProducts.isEmpty) const _InfoPanel('يتم تحميل المنتجات أو لا توجد بيانات متاحة حالياً.'),
        const SizedBox(height:8),
        Wrap(spacing:10,runSpacing:10,children:_filteredCatalogProducts.map((p){
          final price=p['reference_price_mad'];
          final image=(p['image_url'] as String?)?.trim();
          final brand=_brands.where((b)=>b['id']==p['brand_id']).toList();
          return SizedBox(width:(MediaQuery.of(context).size.width-54)/2,child:Card(
            elevation:0,color:Colors.white,clipBehavior:Clip.antiAlias,
            shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(15),side:const BorderSide(color:Color(0xFFD7E2DA))),
            child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Container(height:112,width:double.infinity,color:const Color(0xFFF7F8F7),
                child:image==null||image.isEmpty
                  ?const Icon(Icons.inventory_2_outlined,size:38,color:Color(0xFF00843D))
                  :Image.network(image,fit:BoxFit.contain,errorBuilder:(_,_,_)=>const Icon(Icons.inventory_2_outlined,size:38,color:Color(0xFF00843D)))),
              Padding(padding:const EdgeInsets.all(10),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                Text(p['name'] as String,maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(fontWeight:FontWeight.w800)),
                const SizedBox(height:5),
                Text(brand.isEmpty?'JIB':brand.first['name'] as String,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:11,color:Color(0xFF65736A))),
                const SizedBox(height:6),
                Text(price==null?'السعر المرجعي غير متوفر':'${(price as num).toStringAsFixed(2)} درهم',style:const TextStyle(color:Color(0xFF00843D),fontWeight:FontWeight.w900)),
                const Text('السعر النهائي حسب الفرع',style:TextStyle(fontSize:10,color:Color(0xFF7B817B))),
              ])),
            ]),
          ));
        }).toList()),
        const SizedBox(height:18),
        ExpansionTile(
          tilePadding:EdgeInsets.zero,
          title:Text('تصفح حسب العلامة التجارية (${_brands.length})',style:const TextStyle(fontSize:18,fontWeight:FontWeight.w900)),
          children:[
            if (_brands.isEmpty) const _InfoPanel('لا توجد علامات تجارية متاحة حالياً.'),
            ..._brands.where((b)=>(b['name'] as String).toLowerCase().contains(_search)).map((b){
              final selected=_selectedBrand==b['id'];
              final logo=(b['logo_url'] as String?)?.trim();
              return Card(elevation:0,color:selected?const Color(0xFFE7F0E8):Colors.white,child:ListTile(
                onTap:()=>setState(()=>_selectedBrand=selected?null:b['id'] as String),
                leading:CircleAvatar(backgroundColor:const Color(0xFF00843D),child:logo==null||logo.isEmpty
                  ?Text((b['name'] as String).substring(0,1).toUpperCase(),style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w900))
                  :Image.network(logo,width:34,height:34,errorBuilder:(_,_,_)=>Text((b['name'] as String).substring(0,1).toUpperCase(),style:const TextStyle(color:Colors.white)))),
                title:Text(b['name'] as String,style:const TextStyle(fontWeight:FontWeight.bold)),
                subtitle:Text((b['category']??'') as String),
                trailing:Icon(selected?Icons.check_circle:Icons.chevron_left,color:const Color(0xFF00843D)),
              ));
            }),
          ],
        ),

        const SizedBox(height:22),
        const Text('فروع تستقبل الطلبات',style:TextStyle(fontSize:19,fontWeight:FontWeight.w900)),
        const SizedBox(height:8),
        if (_branches.isEmpty) const _InfoPanel('لا توجد فروع نشطة ومفعّلة لاستقبال الطلبات حالياً.'),
        ..._branches.map((b)=>Card(
          elevation:0,color:_selectedBranch==b['id']?const Color(0xFFE7F0E8):Colors.white,
          child:ListTile(
            onTap:_busy?null:()=>_chooseBranch(b),
            leading:const Icon(Icons.storefront_outlined),
            title:Text(b['name'] as String,style:const TextStyle(fontWeight:FontWeight.bold)),
            subtitle:Text('${b['address']} — ${b['city']}'),
            trailing:const Icon(Icons.chevron_left),
          ),
        )),
        if (_selectedBranch!=null) ...[
          const SizedBox(height:10),
          Text('منتجات متاحة لدى $_selectedBranchName',style:const TextStyle(fontSize:17,fontWeight:FontWeight.bold)),
          if (_busy) const Center(child:CircularProgressIndicator()),
          if (!_busy && _branchProducts.isEmpty) const _InfoPanel('هذا الفرع لم يؤكد توفر منتجات للبيع بعد.'),
          ..._branchProducts.map((row){
            final product=Map<String,dynamic>.from(row['products'] as Map);
            final image=(product['image_url'] as String?)?.trim();
            return Card(elevation:0,child:ListTile(
              leading:Container(width:54,height:54,decoration:BoxDecoration(color:const Color(0xFFF7F8F7),borderRadius:BorderRadius.circular(10)),
                child:image==null||image.isEmpty?const Icon(Icons.inventory_2_outlined,color:Color(0xFF00843D)):Image.network(image,fit:BoxFit.contain,errorBuilder:(_,_,_)=>const Icon(Icons.inventory_2_outlined,color:Color(0xFF00843D)))),
              title:Text(product['name'] as String),
              subtitle:Text('${row['price_mad']} درهم'),
              trailing:IconButton(onPressed:()=>_addToCart(row),icon:const Icon(Icons.add_circle,color:Color(0xFF00843D))),
            ));
          }),
          if (_cart.isNotEmpty) ...[
            const SizedBox(height:14),
            const Text('سلة الطلب',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
            ..._cart.entries.map((e){
              final p=Map<String,dynamic>.from(e.value['products'] as Map);
              return ListTile(
                title:Text(p['name'] as String),
                subtitle:Text('${e.value['price_mad']} درهم × ${e.value['quantity']}'),
                trailing:Row(mainAxisSize:MainAxisSize.min,children:[
                  IconButton(onPressed:()=>_changeQuantity(e.key,-1),icon:const Icon(Icons.remove_circle_outline)),
                  Text('${e.value['quantity']}'),
                  IconButton(onPressed:()=>_changeQuantity(e.key,1),icon:const Icon(Icons.add_circle_outline)),
                ]),
              );
            }),
            Text('المجموع الفرعي: ${_subtotal.toStringAsFixed(2)} درهم',style:const TextStyle(fontWeight:FontWeight.bold)),
            const SizedBox(height:10),
            TextField(controller:_address,decoration:const InputDecoration(labelText:'عنوان التوصيل',border:OutlineInputBorder())),
            const SizedBox(height:10),
            TextField(controller:_phone,keyboardType:TextInputType.phone,decoration:const InputDecoration(labelText:'رقم الهاتف',border:OutlineInputBorder())),
            const SizedBox(height:10),
            FilledButton(onPressed:_busy?null:_submitOrder,child:Text(_busy?'جارٍ الإرسال...':'تأكيد الطلب')),
            const _InfoPanel('يتم احتساب المجموع من سعر الفرع المؤكد. رسوم التوصيل وطريقة الدفع لم يتم تفعيلهما بعد.'),
          ],
        ],
        if (_user!=null) ...[
          const SizedBox(height:24),
          const Text('طلباتي',style:TextStyle(fontSize:19,fontWeight:FontWeight.w900)),
          ..._myOrders.map((o)=>Card(elevation:0,child:Padding(
            padding:const EdgeInsets.all(12),
            child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text('طلب #${(o['id'] as String).substring(0,8)}',style:const TextStyle(fontWeight:FontWeight.bold)),
              Text('${_status(o['status'] as String)} • ${o['subtotal_mad']} درهم'),
              Text('مضى على الطلب: ${DateTime.now().difference(DateTime.parse(o['submitted_at'] as String)).inMinutes} دقيقة'),
              if(o['eta_minutes']!=null) Text('تقدير المتجر للتحضير: ${o['eta_minutes']} دقيقة'),
              ...[
                ['merchant_accepted_at','قبول المتجر'],
                ['preparation_started_at','بدء التحضير'],
                ['preparation_completed_at','اكتمال التحضير'],
                ['courier_offered_at','إرسال عرض للمندوب'],
                ['courier_accepted_at','قبول المندوب'],
                ['picked_up_at','استلام الطلب'],
                ['en_route_at','بدء التوصيل'],
                ['delivered_at','التسليم'],
              ].where((stage)=>o[stage[0]]!=null).map((stage)=>Text('${stage[1]}: ${DateTime.parse(o[stage[0]] as String).toLocal()}')),
            ]),
          ))),
        ],
      ]),
    ),
  );

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
