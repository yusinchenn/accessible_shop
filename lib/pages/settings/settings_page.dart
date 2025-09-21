// lib/pages/settings/settings_page.dart
//
// 簡單示範設定頁（未來可加入 TTS 開關、字體大小等）

import 'package:flutter/material.dart';
import 'package:accessible_shop/utils/tts_helper.dart';
import 'package:accessible_shop/pages/settings/account_info_page.dart';
import 'package:accessible_shop/pages/settings/app_settings_page.dart';
import 'package:accessible_shop/pages/settings/help_support_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      ttsHelper.speak("進入帳號頁面");
    });
  }

  void _speak(String text) {
    ttsHelper.speak(text);
  }

  Future<void> _navigate(Widget page) async {
    await ttsHelper.stop();
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    // 回首頁時不做任何 TTS，讓首頁自動朗讀
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('帳號')),
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _speak("帳號資訊"),
              onDoubleTap: () => _navigate(const AccountInfoPage()),
              child: Container(
                color: Colors.blue[50],
                alignment: Alignment.center,
                child: const Text(
                  '帳號資訊',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          Divider(height: 1, thickness: 1),
          Expanded(
            child: GestureDetector(
              onTap: () => _speak("App 設定"),
              onDoubleTap: () => _navigate(const AppSettingsPage()),
              child: Container(
                color: Colors.green[50],
                alignment: Alignment.center,
                child: const Text(
                  'App 設定',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          Divider(height: 1, thickness: 1),
          Expanded(
            child: GestureDetector(
              onTap: () => _speak("幫助與客服"),
              onDoubleTap: () => _navigate(const HelpSupportPage()),
              child: Container(
                color: Colors.orange[50],
                alignment: Alignment.center,
                child: const Text(
                  '幫助與客服',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
