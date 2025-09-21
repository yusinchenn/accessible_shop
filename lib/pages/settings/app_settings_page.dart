import 'package:flutter/material.dart';
import 'package:accessible_shop/utils/tts_helper.dart';

class AppSettingsPage extends StatelessWidget {
  const AppSettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('App 設定')),
      body: const Center(child: Text('這是 App 設定頁面')),
    );
  }
}
