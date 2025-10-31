import 'package:flutter/material.dart';

/// 語音命令解析器
/// 負責解析語音識別結果並執行對應的導航操作
class VoiceCommandParser {
  static final VoiceCommandParser _instance = VoiceCommandParser._internal();
  factory VoiceCommandParser() => _instance;
  VoiceCommandParser._internal();

  /// 解析並執行語音命令
  /// [text] 語音識別的文字
  /// [context] BuildContext 用於導航
  /// 返回 true 表示成功識別並執行命令，false 表示無法識別
  bool parseAndExecute(String text, BuildContext context) {
    if (!context.mounted) return false;

    final command = text.trim().toLowerCase();

    // 導航命令：返回上一頁
    if (_matchBackCommand(command)) {
      Navigator.of(context).pop();
      return true;
    }

    // 導航命令：回首頁
    if (_matchHomeCommand(command)) {
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
      return true;
    }

    // 導航命令：訂單
    if (_matchOrdersCommand(command)) {
      Navigator.of(context).pushNamed('/orders');
      return true;
    }

    // 導航命令：搜尋
    if (_matchSearchCommand(command)) {
      Navigator.of(context).pushNamed('/search_input');
      return true;
    }

    // 導航命令：購物車
    if (_matchCartCommand(command)) {
      Navigator.of(context).pushNamed('/cart');
      return true;
    }

    // 導航命令：設定
    if (_matchSettingsCommand(command)) {
      Navigator.of(context).pushNamed('/settings');
      return true;
    }

    // 導航命令：錢包
    if (_matchWalletCommand(command)) {
      Navigator.of(context).pushNamed('/wallet');
      return true;
    }

    // 導航命令：通知
    if (_matchNotificationsCommand(command)) {
      Navigator.of(context).pushNamed('/notifications');
      return true;
    }

    // 導航命令：短影音
    if (_matchShortVideosCommand(command)) {
      Navigator.of(context).pushNamed('/short_videos');
      return true;
    }

    // 無法識別的命令
    return false;
  }

  /// 匹配返回上一頁命令
  bool _matchBackCommand(String command) {
    final keywords = [
      '上一頁',
      '返回',
      '回去',
      '回上一頁',
      '回到上一頁',
      '上一個',
      '前一頁',
      '退回',
      '後退',
    ];
    return _containsAny(command, keywords);
  }

  /// 匹配首頁命令
  bool _matchHomeCommand(String command) {
    final keywords = [
      '首頁',
      '回首頁',
      '主頁',
      '回主頁',
      '回到首頁',
      '回到主頁',
      '打開首頁',
      '去首頁',
      '前往首頁',
      '主畫面',
      '首页',
    ];
    return _containsAny(command, keywords);
  }

  /// 匹配訂單命令
  bool _matchOrdersCommand(String command) {
    final keywords = [
      '訂單',
      '我的訂單',
      '打開訂單',
      '去訂單',
      '前往訂單',
      '查看訂單',
      '訂单',
      '看訂單',
      '訂購紀錄',
      '購買紀錄',
      '訂單紀錄',
      '訂單記錄',
    ];
    return _containsAny(command, keywords);
  }

  /// 匹配搜尋命令
  bool _matchSearchCommand(String command) {
    final keywords = [
      '搜尋',
      '搜索',
      '搜寻',
      '找商品',
      '尋找',
      '查找',
      '打開搜尋',
      '去搜尋',
      '前往搜尋',
      '我要搜尋',
      '我要搜索',
      '我要找',
      '搜',
    ];
    return _containsAny(command, keywords);
  }

  /// 匹配購物車命令
  bool _matchCartCommand(String command) {
    final keywords = [
      '購物車',
      '我的購物車',
      '打開購物車',
      '去購物車',
      '前往購物車',
      '查看購物車',
      '购物车',
      '看購物車',
      '購物籃',
      '菜籃',
      '购物篮',
    ];
    return _containsAny(command, keywords);
  }

  /// 匹配設定命令
  bool _matchSettingsCommand(String command) {
    final keywords = [
      '設定',
      '設置',
      '设置',
      '设定',
      '我的設定',
      '打開設定',
      '去設定',
      '前往設定',
      '系統設定',
    ];
    return _containsAny(command, keywords);
  }

  /// 匹配錢包命令
  bool _matchWalletCommand(String command) {
    final keywords = [
      '錢包',
      '我的錢包',
      '打開錢包',
      '去錢包',
      '前往錢包',
      '查看錢包',
      '钱包',
      '看錢包',
      '電子錢包',
    ];
    return _containsAny(command, keywords);
  }

  /// 匹配通知命令
  bool _matchNotificationsCommand(String command) {
    final keywords = [
      '通知',
      '我的通知',
      '打開通知',
      '去通知',
      '前往通知',
      '查看通知',
      '看通知',
      '消息',
      '訊息',
      '通告',
    ];
    return _containsAny(command, keywords);
  }

  /// 匹配短影音命令
  bool _matchShortVideosCommand(String command) {
    final keywords = [
      '短影音',
      '影片',
      '影音',
      '視頻',
      '视频',
      '打開短影音',
      '去短影音',
      '前往短影音',
      '看影片',
      '看視頻',
      '短片',
    ];
    return _containsAny(command, keywords);
  }

  /// 檢查命令是否包含任一關鍵字
  bool _containsAny(String command, List<String> keywords) {
    return keywords.any((keyword) => command.contains(keyword));
  }
}

/// 全域語音命令解析器實例
final voiceCommandParser = VoiceCommandParser();
