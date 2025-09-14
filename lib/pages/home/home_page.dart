import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("🏠 首頁")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("這是首頁 (商品清單將顯示在這裡)"),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/product'),
              child: const Text("前往商品詳細頁"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/cart'),
              child: const Text("前往購物車"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/settings'),
              child: const Text("前往設定"),
            ),
          ],
        ),
      ),
    );
  }
}
