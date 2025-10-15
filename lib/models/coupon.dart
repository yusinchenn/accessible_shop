/// 優惠券模型
class Coupon {
  final int id;
  final String name;
  final String description;
  final double discount; // 折扣金額
  final double minAmount; // 最低消費金額

  const Coupon({
    required this.id,
    required this.name,
    required this.description,
    required this.discount,
    required this.minAmount,
  });

  /// 範例優惠券資料
  static List<Coupon> getSampleCoupons() {
    return [
      const Coupon(
        id: 1,
        name: '新會員優惠',
        description: '滿1000折100',
        discount: 100,
        minAmount: 1000,
      ),
      const Coupon(
        id: 2,
        name: '運動季折扣',
        description: '滿2000折300',
        discount: 300,
        minAmount: 2000,
      ),
      const Coupon(
        id: 3,
        name: 'VIP專屬',
        description: '滿3000折500',
        discount: 500,
        minAmount: 3000,
      ),
    ];
  }
}
