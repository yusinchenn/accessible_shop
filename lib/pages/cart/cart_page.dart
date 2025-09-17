// lib/pages/cart/cart_page.dart
//
// 簡單購物車頁（目前以假狀態顯示：空 / 有資料）
// 若你實作了 Cart 的資料模型與 Provider，這裡可以改用 Provider 顯示實際資料。

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class CartPage extends StatefulWidget {
  const CartPage({Key? key}) : super(key: key);

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final bool _hasItems = false; // 開發測試時可改成 true
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _speakEnterPage();
  }

  Future<void> _speakEnterPage() async {
    await _flutterTts.setLanguage("zh-TW");
    await _flutterTts.setSpeechRate(0.45);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.speak("進入購物車頁面");
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('購物車')),
      body: _hasItems
          ? ListView(
              padding: const EdgeInsets.all(12),
              children: const [
                ListTile(
                  title: Text('範例商品 A'),
                  subtitle: Text('數量：1'),
                  trailing: Text('￥99.00'),
                ),
                Divider(),
                ListTile(
                  title: Text('範例商品 B'),
                  subtitle: Text('數量：2'),
                  trailing: Text('￥59.98'),
                ),
                SizedBox(height: 20),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: ElevatedButton(onPressed: null, child: Text('前往結帳')),
                ),
              ],
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.shopping_cart, size: 80, color: Colors.teal),
                  SizedBox(height: 16),
                  Text(
                    '你的購物車是空的',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('快去加入喜歡的商品吧！', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
    );
  }
}
