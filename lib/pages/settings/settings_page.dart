// lib/pages/settings/settings_page.dart
//
// 簡單示範設定頁（未來可加入 TTS 開關、字體大小等）

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
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
    await _flutterTts.speak("進入設定頁面");
  }

  @override
  void dispose() {
    _flutterTts.stop();
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
