// lib/pages/settings/settings_page.dart
//
// 簡單示範設定頁（未來可加入 TTS 開關、字體大小等）

import 'package:flutter/material.dart';
import 'package:accessible_shop/utils/tts_helper.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TtsHelper _ttsHelper = TtsHelper();

  @override
  void initState() {
    super.initState();
    _speakEnterPage();
  }

  Future<void> _speakEnterPage() async {
    await _ttsHelper.speak("進入設定頁面");
  }

  @override
  void dispose() {
    _ttsHelper.dispose();
    super.dispose();
  }

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
