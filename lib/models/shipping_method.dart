/// 配送方式模型
class ShippingMethod {
  final int id;
  final String name;
  final String description;
  final double fee; // 運費

  const ShippingMethod({
    required this.id,
    required this.name,
    required this.description,
    required this.fee,
  });

  /// 範例配送方式
  static List<ShippingMethod> getSampleMethods() {
    return [
      const ShippingMethod(
        id: 1,
        name: '超商取貨',
        description: '7-11或全家門市取貨',
        fee: 60,
      ),
      const ShippingMethod(
        id: 2,
        name: '宅配',
        description: '送貨到府',
        fee: 100,
      ),
      const ShippingMethod(
        id: 3,
        name: '郵局',
        description: '郵局寄送',
        fee: 80,
      ),
    ];
  }
}
