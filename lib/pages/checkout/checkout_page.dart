import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_constants.dart';
import '../../utils/tts_helper.dart';
import '../../providers/cart_provider.dart';
import '../../models/cart_item.dart';
import '../../models/coupon.dart';
import '../../models/shipping_method.dart';
import '../../models/payment_method.dart';
import '../../widgets/global_gesture_wrapper.dart'; // 匯入全域手勢包裝器

/// 結帳主頁面
class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  Coupon? _selectedCoupon;
  ShippingMethod? _selectedShipping;
  PaymentMethod? _selectedPayment;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ttsHelper.speak("進入結帳頁面");
    });
  }

  void _nextStep() {
    if (_currentStep < 4) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _announceStep();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _announceStep();
    }
  }

  void _announceStep() {
    final steps = ['商品確認', '選擇優惠券', '選擇配送方式', '選擇付款方式', '結帳完成'];
    ttsHelper.speak(steps[_currentStep]);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartData = Provider.of<ShoppingCartData>(context);
    final selectedItems = cartData.selectedItems;

    if (selectedItems.isEmpty) {
      return GlobalGestureScaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('結帳')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('沒有選取商品', style: AppTextStyles.title),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('返回購物車'),
              ),
            ],
          ),
        ),
      );
    }

    return GlobalGestureScaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('結帳 - 步驟 ${_currentStep + 1}/5'),
        centerTitle: true,
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _Step1OrderConfirmation(
            items: selectedItems,
            onNext: _nextStep,
          ),
          _Step2SelectCoupon(
            items: selectedItems,
            selectedCoupon: _selectedCoupon,
            onCouponSelected: (coupon) {
              setState(() => _selectedCoupon = coupon);
            },
            onNext: _nextStep,
            onPrevious: _previousStep,
          ),
          _Step3SelectShipping(
            selectedShipping: _selectedShipping,
            onShippingSelected: (shipping) {
              setState(() => _selectedShipping = shipping);
            },
            onNext: _nextStep,
            onPrevious: _previousStep,
          ),
          _Step4SelectPayment(
            items: selectedItems,
            selectedCoupon: _selectedCoupon,
            selectedShipping: _selectedShipping,
            selectedPayment: _selectedPayment,
            onPaymentSelected: (payment) {
              setState(() => _selectedPayment = payment);
            },
            onNext: _nextStep,
            onPrevious: _previousStep,
          ),
          _Step5Complete(
            items: selectedItems,
            selectedCoupon: _selectedCoupon,
            selectedShipping: _selectedShipping,
            selectedPayment: _selectedPayment,
          ),
        ],
      ),
    );
  }
}

/// 步驟1: 商品確認
class _Step1OrderConfirmation extends StatelessWidget {
  final List<CartItem> items;
  final VoidCallback onNext;

  const _Step1OrderConfirmation({
    required this.items,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final subtotal = items.fold<double>(
      0.0,
      (sum, item) => sum + (item.unitPrice * item.quantity),
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: const Text(
            '確認訂單商品',
            style: AppTextStyles.title,
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return GestureDetector(
                onTap: () {
                  ttsHelper.speak(
                    '${item.name}，${item.specification}，單價${item.unitPrice.toStringAsFixed(0)}元，數量${item.quantity}，小計${(item.unitPrice * item.quantity).toStringAsFixed(0)}元',
                  );
                },
                child: Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name, style: AppTextStyles.subtitle),
                        const SizedBox(height: AppSpacing.xs),
                        Text('規格: ${item.specification}', style: AppTextStyles.body),
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('單價: \$${item.unitPrice.toStringAsFixed(0)}'),
                            Text('x ${item.quantity}'),
                            Text(
                              '小計: \$${(item.unitPrice * item.quantity).toStringAsFixed(0)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          color: AppColors.cardBackground,
          child: Column(
            children: [
              GestureDetector(
                onTap: () {
                  ttsHelper.speak('商品總計${subtotal.toStringAsFixed(0)}元');
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('商品總計:', style: AppTextStyles.subtitle),
                    Text(
                      '\$${subtotal.toStringAsFixed(0)}',
                      style: AppTextStyles.subtitle,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => ttsHelper.speak('下一步'),
                      onDoubleTap: onNext,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          '下一步',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: AppFontSizes.subtitle,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 步驟2: 選擇優惠券
class _Step2SelectCoupon extends StatelessWidget {
  final List<CartItem> items;
  final Coupon? selectedCoupon;
  final ValueChanged<Coupon?> onCouponSelected;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const _Step2SelectCoupon({
    required this.items,
    required this.selectedCoupon,
    required this.onCouponSelected,
    required this.onNext,
    required this.onPrevious,
  });

  @override
  Widget build(BuildContext context) {
    final coupons = Coupon.getSampleCoupons();
    final subtotal = items.fold<double>(
      0.0,
      (sum, item) => sum + (item.unitPrice * item.quantity),
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: const Text(
            '選擇優惠券',
            style: AppTextStyles.title,
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            children: [
              GestureDetector(
                onTap: () {
                  ttsHelper.speak('不使用優惠券');
                },
                onDoubleTap: () {
                  onCouponSelected(null);
                  ttsHelper.speak('已取消選擇優惠券');
                },
                child: Card(
                  color: selectedCoupon == null ? AppColors.primary.withValues(alpha: 0.2) : null,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Icon(
                          selectedCoupon == null ? Icons.radio_button_checked : Icons.radio_button_off,
                          color: selectedCoupon == null ? AppColors.primary : Colors.grey,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        const Text('不使用優惠券', style: AppTextStyles.subtitle),
                      ],
                    ),
                  ),
                ),
              ),
              ...coupons.map((coupon) {
                final isAvailable = subtotal >= coupon.minAmount;
                final isSelected = selectedCoupon?.id == coupon.id;

                return GestureDetector(
                  onTap: () {
                    ttsHelper.speak(
                      '${coupon.name}，${coupon.description}，${isAvailable ? "可使用" : "未達最低消費金額"}',
                    );
                  },
                  onDoubleTap: isAvailable
                      ? () {
                          onCouponSelected(coupon);
                          ttsHelper.speak('已選擇${coupon.name}');
                        }
                      : null,
                  child: Card(
                    color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : null,
                    child: Opacity(
                      opacity: isAvailable ? 1.0 : 0.5,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          children: [
                            Icon(
                              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                              color: isAvailable
                                  ? (isSelected ? AppColors.primary : Colors.grey)
                                  : Colors.grey,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(coupon.name, style: AppTextStyles.subtitle),
                                  Text(coupon.description, style: AppTextStyles.body),
                                  if (!isAvailable)
                                    Text(
                                      '未達最低消費 \$${coupon.minAmount.toStringAsFixed(0)}',
                                      style: TextStyle(color: Colors.red, fontSize: AppFontSizes.small),
                                    ),
                                ],
                              ),
                            ),
                            Text(
                              '-\$${coupon.discount.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          color: AppColors.cardBackground,
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => ttsHelper.speak('上一步'),
                  onDoubleTap: onPrevious,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      '上一步',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: AppFontSizes.subtitle,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: GestureDetector(
                  onTap: () => ttsHelper.speak('下一步'),
                  onDoubleTap: onNext,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      '下一步',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: AppFontSizes.subtitle,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 步驟3: 選擇配送方式
class _Step3SelectShipping extends StatelessWidget {
  final ShippingMethod? selectedShipping;
  final ValueChanged<ShippingMethod> onShippingSelected;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const _Step3SelectShipping({
    required this.selectedShipping,
    required this.onShippingSelected,
    required this.onNext,
    required this.onPrevious,
  });

  @override
  Widget build(BuildContext context) {
    final shippingMethods = ShippingMethod.getSampleMethods();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: const Text(
            '選擇配送方式',
            style: AppTextStyles.title,
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            children: shippingMethods.map((method) {
              final isSelected = selectedShipping?.id == method.id;

              return GestureDetector(
                onTap: () {
                  ttsHelper.speak(
                    '${method.name}，${method.description}，運費${method.fee.toStringAsFixed(0)}元',
                  );
                },
                onDoubleTap: () {
                  onShippingSelected(method);
                  ttsHelper.speak('已選擇${method.name}');
                },
                child: Card(
                  color: isSelected ? AppColors.primary.withOpacity(0.2) : null,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                          color: isSelected ? AppColors.primary : Colors.grey,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(method.name, style: AppTextStyles.subtitle),
                              Text(method.description, style: AppTextStyles.body),
                            ],
                          ),
                        ),
                        Text(
                          '運費: \$${method.fee.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          color: AppColors.cardBackground,
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => ttsHelper.speak('上一步'),
                  onDoubleTap: onPrevious,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      '上一步',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: AppFontSizes.subtitle,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: GestureDetector(
                  onTap: () => ttsHelper.speak('下一步'),
                  onDoubleTap: selectedShipping != null ? onNext : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: selectedShipping != null ? AppColors.primary : Colors.grey,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      '下一步',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: AppFontSizes.subtitle,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 步驟4: 選擇付款方式
class _Step4SelectPayment extends StatelessWidget {
  final List<CartItem> items;
  final Coupon? selectedCoupon;
  final ShippingMethod? selectedShipping;
  final PaymentMethod? selectedPayment;
  final ValueChanged<PaymentMethod> onPaymentSelected;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const _Step4SelectPayment({
    required this.items,
    required this.selectedCoupon,
    required this.selectedShipping,
    required this.selectedPayment,
    required this.onPaymentSelected,
    required this.onNext,
    required this.onPrevious,
  });

  @override
  Widget build(BuildContext context) {
    final paymentMethods = PaymentMethod.getSampleMethods();
    final subtotal = items.fold<double>(
      0.0,
      (sum, item) => sum + (item.unitPrice * item.quantity),
    );
    final discount = selectedCoupon?.discount ?? 0.0;
    final shippingFee = selectedShipping?.fee ?? 0.0;
    final total = subtotal - discount + shippingFee;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: const Text(
            '選擇付款方式',
            style: AppTextStyles.title,
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            children: [
              // 費用明細
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('費用明細', style: AppTextStyles.subtitle),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('商品小計'),
                          Text('\$${subtotal.toStringAsFixed(0)}'),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      if (selectedCoupon != null)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('優惠券 (${selectedCoupon!.name})'),
                            Text(
                              '-\$${discount.toStringAsFixed(0)}',
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('運費 (${selectedShipping?.name ?? ""})'),
                          Text('\$${shippingFee.toStringAsFixed(0)}'),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '總計',
                            style: TextStyle(
                              fontSize: AppFontSizes.title,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '\$${total.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: AppFontSizes.title,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // 付款方式選擇
              ...paymentMethods.map((method) {
                final isSelected = selectedPayment?.id == method.id;

                return GestureDetector(
                  onTap: () {
                    ttsHelper.speak('${method.name}，${method.description}');
                  },
                  onDoubleTap: () {
                    onPaymentSelected(method);
                    ttsHelper.speak('已選擇${method.name}');
                  },
                  child: Card(
                    color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : null,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                            color: isSelected ? AppColors.primary : Colors.grey,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(method.name, style: AppTextStyles.subtitle),
                                Text(method.description, style: AppTextStyles.body),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          color: AppColors.cardBackground,
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => ttsHelper.speak('上一步'),
                  onDoubleTap: onPrevious,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      '上一步',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: AppFontSizes.subtitle,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: GestureDetector(
                  onTap: () => ttsHelper.speak('確認結帳'),
                  onDoubleTap: selectedPayment != null ? onNext : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: selectedPayment != null ? AppColors.primary : Colors.grey,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      '確認結帳',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: AppFontSizes.subtitle,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 步驟5: 結帳完成
class _Step5Complete extends StatelessWidget {
  final List<CartItem> items;
  final Coupon? selectedCoupon;
  final ShippingMethod? selectedShipping;
  final PaymentMethod? selectedPayment;

  const _Step5Complete({
    required this.items,
    required this.selectedCoupon,
    required this.selectedShipping,
    required this.selectedPayment,
  });

  @override
  Widget build(BuildContext context) {
    final subtotal = items.fold<double>(
      0.0,
      (sum, item) => sum + (item.unitPrice * item.quantity),
    );
    final discount = selectedCoupon?.discount ?? 0.0;
    final shippingFee = selectedShipping?.fee ?? 0.0;
    final total = subtotal - discount + shippingFee;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ttsHelper.speak('結帳完成，感謝您的購買');
    });

    return PopScope(
      canPop: false,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
            const SizedBox(height: AppSpacing.md),
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 100,
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              '結帳完成！',
              style: TextStyle(
                fontSize: AppFontSizes.title,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    const Text('訂單摘要', style: AppTextStyles.subtitle),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('商品數量'),
                        Text('${items.length} 項'),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('付款方式'),
                        Text(selectedPayment?.name ?? '未選擇'),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('配送方式'),
                        Text(selectedShipping?.name ?? '未選擇'),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '總金額',
                          style: TextStyle(
                            fontSize: AppFontSizes.subtitle,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '\$${total.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: AppFontSizes.subtitle,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            GestureDetector(
              onTap: () => ttsHelper.speak('查看訂單'),
              onDoubleTap: () {
                ttsHelper.speak('前往歷史訂單頁面');
                Navigator.pushReplacementNamed(context, '/orders');
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: const Text(
                  '查看訂單',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: AppFontSizes.subtitle,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            GestureDetector(
              onTap: () => ttsHelper.speak('回首頁'),
              onDoubleTap: () {
                ttsHelper.speak('返回首頁');
                Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: const Text(
                  '回首頁',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: AppFontSizes.subtitle,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}
