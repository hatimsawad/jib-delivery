import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const jibSupabaseUrl = 'https://ldgbyshgcifheditplnn.supabase.co';
const jibPublishableKey = 'sb_publishable_wvNMRZTBFX4viI2ypcdWjQ_YBqgi_TV';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: jibSupabaseUrl,
    publishableKey: jibPublishableKey,
  );
  runApp(const JibCustomerApp());
}

class JibCustomerApp extends StatelessWidget {
  const JibCustomerApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'JIB',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF172554)),
          scaffoldBackgroundColor: const Color(0xFFF6F7F9),
          useMaterial3: true,
          fontFamily: 'Roboto',
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
  late Future<List<Map<String, dynamic>>> _brandsFuture;
  Future<List<Map<String, dynamic>>>? _productsFuture;
  String? _selectedBrandId;
  String? _selectedBrandName;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _brandsFuture = _loadBrands();
  }

  Future<List<Map<String, dynamic>>> _loadBrands() async {
    final rows = await Supabase.instance.client
        .from('brands')
        .select('id,name,slug,logo_url,category')
        .eq('is_approved', true)
        .eq('is_active', true)
        .order('name');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<Map<String, dynamic>>> _loadProducts(String brandId) async {
    final rows = await Supabase.instance.client
        .from('products')
        .select('id,brand_id,name,category,reference_price_mad,official_source_url')
        .eq('brand_id', brandId)
        .eq('is_active', true)
        .order('name');
    return List<Map<String, dynamic>>.from(rows);
  }

  void _selectBrand(Map<String, dynamic> brand) {
    setState(() {
      _selectedBrandId = brand['id'] as String;
      _selectedBrandName = brand['name'] as String;
      _productsFuture = _loadProducts(_selectedBrandId!);
    });
  }

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('جيب JIB', style: TextStyle(fontWeight: FontWeight.w900)),
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            actions: [
              IconButton(
                tooltip: 'تحديث',
                onPressed: () => setState(() {
                  _brandsFuture = _loadBrands();
                  if (_selectedBrandId != null) {
                    _productsFuture = _loadProducts(_selectedBrandId!);
                  }
                }),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF172554),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('كل ما تحتاجه، يصلك لبابك',
                        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                    SizedBox(height: 8),
                    Text('تصفح العلامات والمنتجات في دليل JIB',
                        style: TextStyle(color: Color(0xFFDCE5FF))),
                    SizedBox(height: 4),
                    Text('الرباط • تمارة',
                        style: TextStyle(color: Color(0xFFDCE5FF), fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const Text('العلامات التجارية',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _brandsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: Padding(
                      padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
                  }
                  if (snapshot.hasError) {
                    return _ErrorPanel(
                      message: 'تعذر تحميل العلامات. تحقق من اتصال البيانات ثم أعد المحاولة.',
                      onRetry: () => setState(() => _brandsFuture = _loadBrands()),
                    );
                  }
                  final brands = snapshot.data ?? [];
                  if (brands.isEmpty) {
                    return const _InfoPanel(message: 'لا توجد علامات منشورة حالياً.');
                  }
                  return Column(
                    children: [
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'ابحث عن علامة تجارية',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (value) => setState(() => _search = value.trim().toLowerCase()),
                      ),
                      const SizedBox(height: 12),
                      ...brands.where((b) => (b['name'] as String).toLowerCase().contains(_search)).map((brand) {
                        final selected = _selectedBrandId == brand['id'];
                        final logo = brand['logo_url'] as String?;
                        return Card(
                          elevation: 0,
                          color: selected ? const Color(0xFFE8EDFF) : Colors.white,
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            onTap: () => _selectBrand(brand),
                            leading: CircleAvatar(
                              backgroundColor: Colors.white,
                              child: logo == null || logo.isEmpty
                                  ? const Icon(Icons.storefront_outlined)
                                  : ClipOval(
                                      child: Image.network(
                                        logo, width: 38, height: 38, fit: BoxFit.contain,
                                        errorBuilder: (_, __, ___) => const Icon(Icons.storefront_outlined),
                                      ),
                                    ),
                            ),
                            title: Text(brand['name'] as String,
                                style: const TextStyle(fontWeight: FontWeight.w800)),
                            subtitle: Text((brand['category'] ?? 'متجر') as String),
                            trailing: Icon(selected ? Icons.check_circle : Icons.chevron_left,
                                color: selected ? const Color(0xFF243B80) : Colors.grey),
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
              if (_selectedBrandId != null) ...[
                const SizedBox(height: 22),
                Text('منتجات ${_selectedBrandName ?? ''}',
                    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
                const SizedBox(height: 10),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _productsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: Padding(
                        padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
                    }
                    if (snapshot.hasError) {
                      return _ErrorPanel(
                        message: 'تعذر تحميل المنتجات.',
                        onRetry: () => setState(() => _productsFuture = _loadProducts(_selectedBrandId!)),
                      );
                    }
                    final products = snapshot.data ?? [];
                    if (products.isEmpty) {
                      return const _InfoPanel(message: 'لا توجد منتجات مسجلة لهذه العلامة بعد.');
                    }
                    return Column(
                      children: products.map((product) {
                        final price = product['reference_price_mad'];
                        return Card(
                          elevation: 0,
                          color: Colors.white,
                          margin: const EdgeInsets.only(bottom: 9),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFFF0F2F7),
                              child: Icon(Icons.inventory_2_outlined, color: Color(0xFF263A72)),
                            ),
                            title: Text(product['name'] as String,
                                style: const TextStyle(fontWeight: FontWeight.w800)),
                            subtitle: Text(price == null
                                ? 'السعر المرجعي غير متوفر'
                                : 'السعر المرجعي: ${(price as num).toStringAsFixed(2)} درهم'),
                            isThreeLine: true,
                            trailing: const Icon(Icons.info_outline, color: Colors.blueGrey),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                const _InfoPanel(
                  message: 'هذه أسعار وبيانات مرجعية. لا يمكن تأكيد الطلب قبل أن يضيف الفرع سعره الفعلي ويؤكد توفر المنتج.',
                ),
              ],
              const SizedBox(height: 20),
              const Card(
                elevation: 0,
                child: ListTile(
                  leading: Icon(Icons.receipt_long_outlined),
                  title: Text('طلباتي', style: TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text('سيظهر تتبع الطلبات بعد تفعيل الحساب ومسار الطلبات.'),
                ),
              ),
            ],
          ),
        ),
      );
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF3FA),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(message, style: const TextStyle(color: Color(0xFF34415E))),
      );
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEEEE),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(message, textAlign: TextAlign.center),
            TextButton(onPressed: onRetry, child: const Text('إعادة المحاولة')),
          ],
        ),
      );
}
