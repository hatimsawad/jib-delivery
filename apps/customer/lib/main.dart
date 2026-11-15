import 'package:flutter/material.dart';

void main() => runApp(const JibApp());

const jibRed = Color(0xFFE31E24);
const jibGreen = Color(0xFF00843D);
const ink = Color(0xFF171717);

class JibApp extends StatelessWidget {
  const JibApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JIB | جيب',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8F8F6),
        colorScheme: ColorScheme.fromSeed(seedColor: jibRed, primary: jibRed),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(backgroundColor: Colors.white, foregroundColor: ink, elevation: 0),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedCategory = 0;
  final categories = const ['الكل', 'مطاعم', 'بقالة', 'متاجر'];
  final featured = const [
    _Store('مذاق المدينة', 'برغر · طاكوس · وجبات', '25–35 دقيقة', '4.8', jibRed, '🍔'),
    _Store('سوق الحومة', 'خضر · فواكه · أساسيات', '15–25 دقيقة', '4.7', jibGreen, '🥑'),
    _Store('ركن الحلوى', 'حلويات · مشروبات', '20–30 دقيقة', '4.9', Color(0xFF8B5CF6), '🧁'),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 20,
          title: Row(children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: jibRed, borderRadius: BorderRadius.circular(13)), child: const Center(child: Text('J', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)))),
            const SizedBox(width: 10),
            const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('جيب JIB', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
              Text('كلشي قريب ليك', style: TextStyle(fontSize: 11, color: Colors.black54)),
            ]),
          ]),
          actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.shopping_bag_outlined)), const SizedBox(width: 8)],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [jibRed, Color(0xFFB51219)]),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('مرحبا بك فـ JIB 👋', style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 8),
                const Text('شنو بغيتي
نوصّلو ليك اليوم؟', style: TextStyle(color: Colors.white, fontSize: 27, height: 1.35, fontWeight: FontWeight.w900)),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                  child: const Row(children: [Icon(Icons.search, color: Colors.black45), SizedBox(width: 8), Text('قلب على مطعم أو منتوج...', style: TextStyle(color: Colors.black45))]),
                ),
              ]),
            ),
            const SizedBox(height: 22),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('اكتشف الفئات', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
              Text('الرباط', style: TextStyle(color: jibGreen, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 12),
            SizedBox(height: 43, child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) => ChoiceChip(
                label: Text(categories[index]),
                selected: selectedCategory == index,
                onSelected: (_) => setState(() => selectedCategory = index),
                selectedColor: jibRed.withValues(alpha: .12),
                labelStyle: TextStyle(color: selectedCategory == index ? jibRed : ink, fontWeight: FontWeight.bold),
                side: BorderSide(color: selectedCategory == index ? jibRed : const Color(0xFFE7E7E7)),
                showCheckmark: false,
              ),
            )),
            const SizedBox(height: 22),
            const Text('اختيارات قريبة منك', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            ...featured.map((store) => _StoreCard(store: store)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFEAF4ED), borderRadius: BorderRadius.circular(18)),
              child: const Row(children: [
                Icon(Icons.delivery_dining, color: jibGreen, size: 34),
                SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('التوصيل قريب ليك', style: TextStyle(fontWeight: FontWeight.w900, color: jibGreen)),
                  Text('أداء نقداً عند الاستلام متاح في النسخة الأولى.', style: TextStyle(fontSize: 12, color: Colors.black54)),
                ])),
              ]),
            ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: 0,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'الرئيسية'),
            NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'طلباتي'),
            NavigationDestination(icon: Icon(Icons.favorite_border), label: 'المفضلة'),
            NavigationDestination(icon: Icon(Icons.person_outline), label: 'حسابي'),
          ],
        ),
      ),
    );
  }
}

class _Store {
  final String name, subtitle, eta, rating, emoji;
  final Color color;
  const _Store(this.name, this.subtitle, this.eta, this.rating, this.color, this.emoji);
}

class _StoreCard extends StatelessWidget {
  final _Store store;
  const _StoreCard({required this.store});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(19), border: Border.all(color: const Color(0xFFEDEDED))),
    child: Row(children: [
      Container(width: 76, height: 76, decoration: BoxDecoration(color: store.color.withValues(alpha: .10), borderRadius: BorderRadius.circular(16)), child: Center(child: Text(store.emoji, style: const TextStyle(fontSize: 37)))),
      const SizedBox(width: 13),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(store.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        const SizedBox(height: 3),
        Text(store.subtitle, style: const TextStyle(color: Colors.black54, fontSize: 12)),
        const SizedBox(height: 8),
        Row(children: [const Icon(Icons.star, color: Color(0xFFFFB400), size: 15), Text(' ${store.rating}  ·  ', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)), const Icon(Icons.access_time, size: 13, color: Colors.black45), Text(' ${store.eta}', style: const TextStyle(fontSize: 11, color: Colors.black54))]),
      ])),
      const Icon(Icons.chevron_left, color: Colors.black38),
    ]),
  );
}
