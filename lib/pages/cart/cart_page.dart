import 'package:flutter/material.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("🛒 購物車")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("這裡是購物車頁面"),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/checkout'),
              child: const Text("前往結帳"),
            ),
          ],
        ),
      ),
    );
  }
}
