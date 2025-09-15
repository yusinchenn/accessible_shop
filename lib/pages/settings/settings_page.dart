// lib/pages/settings/settings_page.dart
//
// 簡單示範設定頁（未來可加入 TTS 開關、字體大小等）

import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  // 開發階段可以顯示一些預設設定項目
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          ListTile(
            leading: const Icon(Icons.volume_up),
            title: const Text('語音提示 (TTS)'),
            trailing: Switch(value: true, onChanged: (v) {}),
          ),
          ListTile(
            leading: const Icon(Icons.format_size),
            title: const Text('字體大小'),
            subtitle: const Text('中 (可調整)'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('應用版本'),
            subtitle: const Text('v0.1.0'),
          ),
        ],
      ),
    );
  }
}
