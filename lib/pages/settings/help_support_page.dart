import 'package:flutter/material.dart';
import 'package:accessible_shop/utils/tts_helper.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('幫助與客服')),
      body: const Center(child: Text('這是幫助與客服頁面')),
    );
  }
}
