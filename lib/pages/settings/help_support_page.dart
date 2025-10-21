import 'package:flutter/material.dart';
import 'package:accessible_shop/utils/tts_helper.dart';
import 'package:accessible_shop/utils/app_constants.dart';
import 'package:accessible_shop/widgets/global_gesture_wrapper.dart'; // 匯入全域手勢包裝器

class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({Key? key}) : super(key: key);

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      ttsHelper.speak("進入幫助與客服頁面");
    });
  }

  @override
  void dispose() {
    ttsHelper.speak("進入帳號頁面");
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlobalGestureScaffold(
      backgroundColor: AppColors.background, // 套用背景色
      appBar: AppBar(
        title: const Text('幫助與客服'),
        automaticallyImplyLeading: false,
      ),
      body: const Center(child: Text('這是幫助與客服頁面')),
    );
  }
}
