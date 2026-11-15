// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
void main() => runApp(const CourierApp());
class CourierApp extends StatelessWidget {
  const CourierApp({super.key});
  @override Widget build(BuildContext context) => MaterialApp(debugShowCheckedModeBanner:false, theme:ThemeData(useMaterial3:true,colorScheme:ColorScheme.fromSeed(seedColor:const Color(0xFF00843D))), home:const CourierHome());
}
class CourierHome extends StatelessWidget {
  const CourierHome({super.key});
  @override Widget build(BuildContext context) => Directionality(textDirection:TextDirection.rtl,child:Scaffold(backgroundColor:const Color(0xFFF7F8F6),appBar:AppBar(title:const Text('جيب · السائق',style:TextStyle(fontWeight:FontWeight.w900)),),body:ListView(padding:const EdgeInsets.all(18),children:[Container(padding:const EdgeInsets.all(22),decoration:BoxDecoration(color:const Color(0xFF00843D),borderRadius:BorderRadius.circular(22)),child:const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('مرحبا بك في فريق JIB',style:TextStyle(color:Colors.white70)),SizedBox(height:8),Text('خدمتك قريبة،\nوالطريق واضح.',style:TextStyle(color:Colors.white,fontSize:27,fontWeight:FontWeight.w900))])),const SizedBox(height:20),const Text('حالة الاتصال',style:TextStyle(fontSize:18,fontWeight:FontWeight.w900)),const SizedBox(height:10),const Card(child:ListTile(leading:Icon(Icons.pause_circle_outline,color:Colors.orange,size:32),title:Text('غير متصل حالياً'),subtitle:Text('سيظهر زر الاتصال بعد تسجيل الدخول والتحقق من الحساب.'))),const SizedBox(height:18),const Text('طلبات التوصيل',style:TextStyle(fontSize:18,fontWeight:FontWeight.w900)),const Card(child:Padding(padding:EdgeInsets.all(22),child:Column(children:[Icon(Icons.delivery_dining,size:48,color:Colors.black38),SizedBox(height:8),Text('لا توجد طلبات للعرض',style:TextStyle(fontWeight:FontWeight.bold)),Text('قائمة الطلبات ستظهر بعد ربط النظام والتحقق من السائق.',textAlign:TextAlign.center,style:TextStyle(color:Colors.black54,fontSize:12))])))])));
}
