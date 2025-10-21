import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_constants.dart';
import '../../utils/tts_helper.dart';
import '../../providers/cart_provider.dart';
import '../../services/database_service.dart';
import '../../services/accessibility_service.dart';
import '../../models/cart_item.dart';
import '../../models/coupon.dart';
import '../../models/shipping_method.dart';
import '../../models/payment_method.dart';
import '../../models/order.dart';
import '../../widgets/global_gesture_wrapper.dart'; // 匯入全域手勢包裝器
import '../../widgets/accessible_gesture_wrapper.dart'; // 匯入無障礙手勢包裝器

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

  // 在進入結帳頁面時複製選取的商品列表，避免受購物車更新影響
  List<CartItem>? _checkoutItems;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 初始化無障礙服務
      accessibilityService.initialize(context);

      // 只在自訂模式播放歡迎語音
      if (accessibilityService.shouldUseCustomTTS) {
        ttsHelper.speak("進入結帳頁面");
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 只在第一次進入時複製商品列表
    if (_checkoutItems == null) {
      final cartData = Provider.of<ShoppingCartData>(context, listen: false);
      _checkoutItems = List.from(cartData.selectedItems);
    }
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
    // 只在自訂模式播放步驟語音
    if (accessibilityService.shouldUseCustomTTS) {
      ttsHelper.speak(steps[_currentStep]);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 使用複製的商品列表，不監聽購物車變化
    final selectedItems = _checkoutItems ?? [];

    if (selectedItems.isEmpty) {
      return GlobalGestureScaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('結帳'),
          automaticallyImplyLeading: false,
        ),
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
        automaticallyImplyLeading: false,
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
              final itemSubtotal = (item.unitPrice * item.quantity).toStringAsFixed(0);
              return AccessibleSpeakWrapper(
                label: '${item.name}，規格 ${item.specification}，單價 ${item.unitPrice.toStringAsFixed(0)} 元，數量 ${item.quantity}，小計 $itemSubtotal 元',
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
                              '小計: \$$itemSubtotal',
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
              AccessibleSpeakWrapper(
                label: '商品總計 ${subtotal.toStringAsFixed(0)} 元',
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
                    child: AccessibleGestureWrapper(
                      label: '下一步',
                      description: '前往選擇優惠券',
                      onTap: onNext,
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
              AccessibleGestureWrapper(
                label: '不使用優惠券${selectedCoupon == null ? "，已選擇" : ""}',
                description: '點擊取消使用優惠券',
                onTap: () {
                  onCouponSelected(null);
                  if (accessibilityService.shouldUseCustomTTS) {
                    ttsHelper.speak('已取消選擇優惠券');
                  }
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

                return AccessibleGestureWrapper(
                  label: '${coupon.name}，${coupon.description}，折扣 ${coupon.discount.toStringAsFixed(0)} 元${isSelected ? "，已選擇" : ""}${!isAvailable ? "，未達最低消費金額" : ""}',
                  description: isAvailable ? '點擊選擇此優惠券' : '此優惠券未達使用門檻',
                  enabled: isAvailable,
                  onTap: isAvailable
                      ? () {
                          onCouponSelected(coupon);
                          if (accessibilityService.shouldUseCustomTTS) {
                            ttsHelper.speak('已選擇 ${coupon.name}');
                          }
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
                child: AccessibleGestureWrapper(
                  label: '上一步',
                  description: '返回商品確認步驟',
                  onTap: onPrevious,
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
                child: AccessibleGestureWrapper(
                  label: '下一步',
                  description: '前往選擇配送方式',
                  onTap: onNext,
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

              return AccessibleGestureWrapper(
                label: '${method.name}，${method.description}，運費 ${method.fee.toStringAsFixed(0)} 元${isSelected ? "，已選擇" : ""}',
                description: '點擊選擇此配送方式',
                onTap: () {
                  onShippingSelected(method);
                  if (accessibilityService.shouldUseCustomTTS) {
                    ttsHelper.speak('已選擇 ${method.name}');
                  }
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
                child: AccessibleGestureWrapper(
                  label: '上一步',
                  description: '返回選擇優惠券步驟',
                  onTap: onPrevious,
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
                child: AccessibleGestureWrapper(
                  label: '下一步${selectedShipping == null ? "，請先選擇配送方式" : ""}',
                  description: '前往選擇付款方式',
                  enabled: selectedShipping != null,
                  onTap: selectedShipping != null ? onNext : null,
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

                return AccessibleGestureWrapper(
                  label: '${method.name}，${method.description}${isSelected ? "，已選擇" : ""}',
                  description: '點擊選擇此付款方式',
                  onTap: () {
                    onPaymentSelected(method);
                    if (accessibilityService.shouldUseCustomTTS) {
                      ttsHelper.speak('已選擇 ${method.name}');
                    }
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
                child: AccessibleGestureWrapper(
                  label: '上一步',
                  description: '返回選擇配送方式步驟',
                  onTap: onPrevious,
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
                child: AccessibleGestureWrapper(
                  label: '確認結帳${selectedPayment == null ? "，請先選擇付款方式" : ""}',
                  description: '完成付款並送出訂單',
                  enabled: selectedPayment != null,
                  onTap: selectedPayment != null ? onNext : null,
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
class _Step5Complete extends StatefulWidget {
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
  State<_Step5Complete> createState() => _Step5CompleteState();
}

class _Step5CompleteState extends State<_Step5Complete> {
  Order? _createdOrder;
  bool _isCreatingOrder = true;

  @override
  void initState() {
    super.initState();
    _createOrder();
  }

  /// 建立訂單
  Future<void> _createOrder() async {
    try {
      final db = Provider.of<DatabaseService>(context, listen: false);

      final subtotal = widget.items.fold<double>(
        0.0,
        (sum, item) => sum + (item.unitPrice * item.quantity),
      );
      final discount = widget.selectedCoupon?.discount ?? 0.0;
      final shippingFee = widget.selectedShipping?.fee ?? 0.0;

      // 建立訂單
      final order = await db.createOrder(
        cartItems: widget.items,
        couponId: widget.selectedCoupon?.id,
        couponName: widget.selectedCoupon?.name,
        discount: discount,
        shippingMethodId: widget.selectedShipping!.id,
        shippingMethodName: widget.selectedShipping!.name,
        shippingFee: shippingFee,
        paymentMethodId: widget.selectedPayment!.id,
        paymentMethodName: widget.selectedPayment!.name,
      );

      // 清除購物車中已結帳的項目
      // 購物車 Provider 會自動監聽資料庫變化並重新載入
      await db.clearSelectedCartItems();

      setState(() {
        _createdOrder = order;
        _isCreatingOrder = false;
      });

      // 朗讀結帳完成訊息（只在自訂模式）
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (accessibilityService.shouldUseCustomTTS) {
          ttsHelper.speak('結帳完成，訂單編號 ${order.orderNumber}，感謝您的購買');
        }
      });
    } catch (e) {
      setState(() {
        _isCreatingOrder = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('建立訂單失敗: $e', style: const TextStyle(fontSize: 24)),
            backgroundColor: Colors.red,
          ),
        );
        if (accessibilityService.shouldUseCustomTTS) {
          ttsHelper.speak('建立訂單失敗');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCreatingOrder) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: AppSpacing.lg),
            Text('正在建立訂單...', style: AppTextStyles.subtitle),
          ],
        ),
      );
    }

    if (_createdOrder == null) {
      return const Center(
        child: Text('建立訂單失敗', style: AppTextStyles.title),
      );
    }

    final order = _createdOrder!;

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
            const SizedBox(height: AppSpacing.sm),
            AccessibleSpeakWrapper(
              label: '訂單編號 ${order.orderNumber}',
              child: Text(
                '訂單編號: ${order.orderNumber}',
                style: const TextStyle(
                  fontSize: AppFontSizes.subtitle,
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
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
                        Text('${widget.items.length} 項'),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('付款方式'),
                        Text(widget.selectedPayment?.name ?? '未選擇'),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('配送方式'),
                        Text(widget.selectedShipping?.name ?? '未選擇'),
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
                          '\$${order.total.toStringAsFixed(0)}',
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
            AccessibleGestureWrapper(
              label: '查看訂單',
              description: '前往歷史訂單頁面',
              onTap: () {
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
            AccessibleGestureWrapper(
              label: '回首頁',
              description: '返回首頁',
              onTap: () {
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
