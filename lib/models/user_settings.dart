import 'package:isar/isar.dart';

part 'user_settings.g.dart';

@Collection()
class UserSettings {
  Id id = Isar.autoIncrement;

  bool ttsEnabled = true;          // 是否開啟語音播報
  double ttsSpeed = 1.0;           // 語速
  double fontSize = 16.0;          // 字體大小
  String? preferredLanguage;       // 偏好語言 (未來擴充)
}
