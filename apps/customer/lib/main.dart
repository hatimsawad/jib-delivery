import 'package:flutter/material.dart';

void main() => runApp(const JibApp());

const jibRed = Color(0xFFE31E24);
const jibGreen = Color(0xFF00843D);

class JibApp extends StatelessWidget {
  const JibApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'JIB | جيب',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: jibRed, primary: jibRed),
          scaffoldBackgroundColor: const Color(0xFFF8F8F6),
        ),
        home: const HomeScreen(),
      );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedCategory = 0;
  final categories = const ['الكل', 'مطاعم', 'بقالة', 'متاجر'];

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            title: const Row(
              children: [
                CircleAvatar(
                  backgroundColor: jibRed,
                  child: Text('J', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                ),
                SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('جيب JIB', style: TextStyle(fontWeight: FontWeight.w900)),
                    Text('كلشي قريب ليك', style: TextStyle(fontSize: 11, color: Colors.black54)),
                  ],
                ),
              ],
            ),
            actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.shopping_bag_outlined))],
          ),
          body: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: jibRed,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('مرحبا بك فـ JIB 👋', style: TextStyle(color: Colors.white70)),
                    SizedBox(height: 8),
                    Text('شنو بغيتي نوصّلو ليك اليوم؟',
                        style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900)),
                    SizedBox(height: 18),
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'قلب على مطعم أو منتوج...',
                        prefixIcon: Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)), borderSide: BorderSide.none),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const Text('اكتشف الفئات', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: List.generate(
                  categories.length,
                  (index) => ChoiceChip(
                    label: Text(categories[index]),
                    selected: selectedCategory == index,
                    onSelected: (_) => setState(() => selectedCategory = index),
                    selectedColor: jibRed.withValues(alpha: .14),
                    showCheckmark: false,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              const Text('اختيارات قريبة منك', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              const _StoreTile(icon: '🍔', name: 'مذاق المدينة', details: 'برغر · طاكوس · وجبات', time: '25–35 دقيقة', color: jibRed),
              const _StoreTile(icon: '🥑', name: 'سوق الحومة', details: 'خضر · فواكه · أساسيات', time: '15–25 دقيقة', color: jibGreen),
              const _StoreTile(icon: '🧁', name: 'ركن الحلوى', details: 'حلويات · مشروبات', time: '20–30 دقيقة', color: Color(0xFF8B5CF6)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFFEAF4ED), borderRadius: BorderRadius.circular(18)),
                child: const Row(
                  children: [
                    Icon(Icons.delivery_dining, color: jibGreen, size: 34),
                    SizedBox(width: 12),
                    Expanded(child: Text('الدفع نقداً عند الاستلام متاح في النسخة الأولى.',
                        style: TextStyle(color: jibGreen, fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: const NavigationBar(
            selectedIndex: 0,
            destinations: [
              NavigationDestination(icon: Icon(Icons.home_outlined), label: 'الرئيسية'),
              NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'طلباتي'),
              NavigationDestination(icon: Icon(Icons.favorite_border), label: 'المفضلة'),
              NavigationDestination(icon: Icon(Icons.person_outline), label: 'حسابي'),
            ],
          ),
        ),
      );
}

class _StoreTile extends StatelessWidget {
  const _StoreTile({required this.icon, required this.name, required this.details, required this.time, required this.color});

  final String icon;
  final String name;
  final String details;
  final String time;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFEDEDED)),
        ),
        child: Row(
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(color: color.withValues(alpha: .10), borderRadius: BorderRadius.circular(15)),
              alignment: Alignment.center,
              child: Text(icon, style: const TextStyle(fontSize: 34)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  Text(details, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                  Text(time, style: const TextStyle(color: jibGreen, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const Icon(Icons.chevron_left, color: Colors.black38),
          ],
        ),
      );
}
