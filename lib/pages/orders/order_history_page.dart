// lib/pages/orders/order_history_page.dart
//
// 訂單歷史頁 (暫時以空/有資料 flag 示範)

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({Key? key}) : super(key: key);

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  final bool _hasOrders = false; // 開發測試改成 true 可顯示範例
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
    await _flutterTts.speak("進入訂單頁面");
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('歷史訂單')),
      body: _hasOrders
          ? ListView(
              padding: const EdgeInsets.all(12),
              children: const [
                ListTile(
                  title: Text('訂單 #20250901'),
                  subtitle: Text('2025-09-01'),
                  trailing: Text('\$129.99'),
                ),
                Divider(),
                ListTile(
                  title: Text('訂單 #20250815'),
                  subtitle: Text('2025-08-15'),
                  trailing: Text('\$79.99'),
                ),
              ],
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.list_alt, size: 80, color: Colors.teal),
                  SizedBox(height: 16),
                  Text(
                    '目前沒有訂單',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('你的訂單紀錄會出現在這裡。', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
    );
  }
}
