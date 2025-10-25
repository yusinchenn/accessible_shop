/// 模糊搜尋工具類
/// 用於計算字符串相似度，支援中文字符的模糊匹配
class FuzzySearchHelper {
  /// 計算兩個字符串的相似度（使用編輯距離算法）
  /// 返回值範圍：0.0 ~ 1.0，值越大表示越相似
  static double calculateSimilarity(String str1, String str2) {
    if (str1.isEmpty || str2.isEmpty) return 0.0;
    if (str1 == str2) return 1.0;

    final distance = _levenshteinDistance(str1, str2);
    final maxLength = str1.length > str2.length ? str1.length : str2.length;

    // 轉換為相似度分數 (0.0 ~ 1.0)
    return 1.0 - (distance / maxLength);
  }

  /// 計算編輯距離 (Levenshtein Distance)
  /// 返回將 str1 轉換為 str2 所需的最少編輯次數
  static int _levenshteinDistance(String str1, String str2) {
    final len1 = str1.length;
    final len2 = str2.length;

    // 創建 DP 表格
    final dp = List.generate(
      len1 + 1,
      (i) => List.filled(len2 + 1, 0),
    );

    // 初始化第一列和第一行
    for (int i = 0; i <= len1; i++) {
      dp[i][0] = i;
    }
    for (int j = 0; j <= len2; j++) {
      dp[0][j] = j;
    }

    // 填充 DP 表格
    for (int i = 1; i <= len1; i++) {
      for (int j = 1; j <= len2; j++) {
        if (str1[i - 1] == str2[j - 1]) {
          dp[i][j] = dp[i - 1][j - 1];
        } else {
          dp[i][j] = 1 + _min3(
            dp[i - 1][j],     // 刪除
            dp[i][j - 1],     // 插入
            dp[i - 1][j - 1], // 替換
          );
        }
      }
    }

    return dp[len1][len2];
  }

  /// 計算字符包含度
  /// 檢查 target 中包含多少 keyword 的字符（順序無關）
  /// 返回值範圍：0.0 ~ 1.0
  static double calculateCharacterCoverage(String keyword, String target) {
    if (keyword.isEmpty || target.isEmpty) return 0.0;

    final keywordChars = keyword.toLowerCase().split('');
    final targetLower = target.toLowerCase();

    int matchCount = 0;
    for (var char in keywordChars) {
      if (targetLower.contains(char)) {
        matchCount++;
      }
    }

    return matchCount / keywordChars.length;
  }

  /// 計算連續字符匹配度
  /// 檢查 keyword 的連續子字串在 target 中出現的程度
  /// 返回值：最長匹配子字串長度
  static int calculateLongestSubstringMatch(String keyword, String target) {
    if (keyword.isEmpty || target.isEmpty) return 0;

    final keywordLower = keyword.toLowerCase();
    final targetLower = target.toLowerCase();

    int maxLength = 0;

    // 嘗試所有可能的子字串
    for (int i = 0; i < keywordLower.length; i++) {
      for (int j = i + 1; j <= keywordLower.length; j++) {
        final substring = keywordLower.substring(i, j);
        if (targetLower.contains(substring) && substring.length > maxLength) {
          maxLength = substring.length;
        }
      }
    }

    return maxLength;
  }

  /// 綜合評分：結合多種匹配算法
  /// 返回值範圍：0.0 ~ 100.0
  static double calculateFuzzyScore(String keyword, String target) {
    if (keyword.isEmpty || target.isEmpty) return 0.0;

    final keywordLower = keyword.toLowerCase();
    final targetLower = target.toLowerCase();

    // 完全匹配
    if (targetLower == keywordLower) return 100.0;

    // 開頭匹配
    if (targetLower.startsWith(keywordLower)) return 95.0;

    // 包含匹配
    if (targetLower.contains(keywordLower)) return 90.0;

    // 相似度分數 (權重: 40%)
    final similarity = calculateSimilarity(keywordLower, targetLower);

    // 字符包含度 (權重: 30%)
    final coverage = calculateCharacterCoverage(keywordLower, targetLower);

    // 最長連續匹配 (權重: 30%)
    final longestMatch = calculateLongestSubstringMatch(keywordLower, targetLower);
    final matchRatio = longestMatch / keywordLower.length;

    // 綜合評分
    final fuzzyScore = (similarity * 40) + (coverage * 30) + (matchRatio * 30);

    // 如果分數太低，視為不匹配
    return fuzzyScore < 20 ? 0.0 : fuzzyScore;
  }

  /// 輔助函數：返回三個數中的最小值
  static int _min3(int a, int b, int c) {
    int min = a;
    if (b < min) min = b;
    if (c < min) min = c;
    return min;
  }
}
