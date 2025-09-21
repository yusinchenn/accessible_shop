import 'package:flutter/material.dart';
import 'package:accessible_shop/utils/tts_helper.dart';

class AppSettingsPage extends StatefulWidget {
  const AppSettingsPage({Key? key}) : super(key: key);

  @override
  State<AppSettingsPage> createState() => _AppSettingsPageState();
}

class _AppSettingsPageState extends State<AppSettingsPage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      ttsHelper.speak("進入App設定頁面");
    });
  }

  @override
  void dispose() {
    ttsHelper.speak("進入帳號頁面");
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('App 設定')),
      body: const Center(child: Text('這是 App 設定頁面')),
    );
  }
}
