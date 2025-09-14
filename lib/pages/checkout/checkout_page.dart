import 'package:flutter/material.dart';

class CheckoutPage extends StatelessWidget {
  const CheckoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("💳 結帳")),
      body: const Center(
        child: Text("這裡是結帳頁面"),
      ),
    );
  }
}
