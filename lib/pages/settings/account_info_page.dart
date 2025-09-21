import 'package:flutter/material.dart';
import 'package:accessible_shop/utils/tts_helper.dart';

class AccountInfoPage extends StatefulWidget {
  const AccountInfoPage({Key? key}) : super(key: key);

  @override
  State<AccountInfoPage> createState() => _AccountInfoPageState();
}

class _AccountInfoPageState extends State<AccountInfoPage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      ttsHelper.speak("進入帳號資訊頁面");
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
      appBar: AppBar(title: const Text('帳號資訊')),
      body: const Center(child: Text('這是帳號資訊頁面')),
    );
  }
}
