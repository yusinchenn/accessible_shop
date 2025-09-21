import 'package:flutter/material.dart';
import 'package:accessible_shop/utils/tts_helper.dart';

class AccountInfoPage extends StatelessWidget {
  const AccountInfoPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('帳號資訊')),
      body: const Center(child: Text('這是帳號資訊頁面')),
    );
  }
}
