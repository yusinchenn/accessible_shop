/// 付款方式模型
class PaymentMethod {
  final int id;
  final String name;
  final String description;

  const PaymentMethod({
    required this.id,
    required this.name,
    required this.description,
  });

  /// 範例付款方式
  static List<PaymentMethod> getSampleMethods() {
    return [
      const PaymentMethod(
        id: 1,
        name: '信用卡',
        description: 'Visa、Master、JCB',
      ),
      const PaymentMethod(
        id: 2,
        name: '貨到付款',
        description: '收到商品時支付現金',
      ),
      const PaymentMethod(
        id: 3,
        name: 'ATM轉帳',
        description: '虛擬帳號轉帳',
      ),
    ];
  }
}
