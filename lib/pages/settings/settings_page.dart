import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("⚙️ 設定")),
      body: const Center(
        child: Text("這裡是設定頁面 (字體大小 / 語音模式將放這裡)"),
      ),
    );
  }
}
