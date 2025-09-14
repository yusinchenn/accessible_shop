import 'package:flutter/material.dart';

class OrderHistoryPage extends StatelessWidget {
  const OrderHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("📜 歷史訂單")),
      body: const Center(
        child: Text("這裡是歷史訂單頁面"),
      ),
    );
  }
}
