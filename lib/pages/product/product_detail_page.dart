import 'package:flutter/material.dart';

class ProductDetailPage extends StatelessWidget {
  final int? productId; // 可選，未來可傳入商品 ID

  const ProductDetailPage({super.key, this.productId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("📄 商品詳細頁")),
      body: Center(
        child: Text("這裡是商品詳細資訊頁面 (商品ID: ${productId ?? '未提供'})"),
      ),
    );
  }
}
