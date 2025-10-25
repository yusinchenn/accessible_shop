import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_constants.dart';
import '../../utils/tts_helper.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/database_service.dart';
import '../../services/order_automation_service.dart';
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
  double _walletAmount = 0.0; // 使用的錢包金額

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
            walletAmount: _walletAmount,
            onPaymentSelected: (payment) {
              setState(() => _selectedPayment = payment);
            },
            onWalletAmountChanged: (amount) {
              setState(() => _walletAmount = amount);
            },
            onNext: _nextStep,
            onPrevious: _previousStep,
          ),
          _Step5Complete(
            items: selectedItems,
            selectedCoupon: _selectedCoupon,
            selectedShipping: _selectedShipping,
            selectedPayment: _selectedPayment,
            walletAmount: _walletAmount,
          ),
        ],
      ),
    );
  }
}

/// 步驟1: 商品確認
class _Step1OrderConfirmation extends StatefulWidget {
  final List<CartItem> items;
  final VoidCallback onNext;

  const _Step1OrderConfirmation({
    required this.items,
    required this.onNext,
  });

  @override
  State<_Step1OrderConfirmation> createState() => _Step1OrderConfirmationState();
}

class _Step1OrderConfirmationState extends State<_Step1OrderConfirmation> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (accessibilityService.shouldUseCustomTTS) {
        _announceAllItems();
      }
    });
  }

  void _announceAllItems() {
    final subtotal = widget.items.fold<double>(
      0.0,
      (sum, item) => sum + (item.unitPrice * item.quantity),
    );

    // 建立完整的朗讀內容
    final StringBuffer announcement = StringBuffer();
    announcement.write('商品確認，共${widget.items.length}項商品。');

    for (int i = 0; i < widget.items.length; i++) {
      final item = widget.items[i];
      announcement.write('第${i + 1}項，');
      announcement.write('${item.name}，${item.specification}，');
      announcement.write('單價${item.unitPrice.toStringAsFixed(0)}元，');
      announcement.write('數量${item.quantity}，');
      announcement.write('小計${(item.unitPrice * item.quantity).toStringAsFixed(0)}元。');
    }

    announcement.write('商品總計${subtotal.toStringAsFixed(0)}元');

    ttsHelper.speak(announcement.toString());
  }

  @override
  Widget build(BuildContext context) {
    final subtotal = widget.items.fold<double>(
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
            itemCount: widget.items.length,
            itemBuilder: (context, index) {
              final item = widget.items[index];
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
                      label: '下一步按鈕',
                      description: '前往選擇優惠券',
                      onTap: widget.onNext,
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
class _Step2SelectCoupon extends StatefulWidget {
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
  State<_Step2SelectCoupon> createState() => _Step2SelectCouponState();
}

class _Step2SelectCouponState extends State<_Step2SelectCoupon> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (accessibilityService.shouldUseCustomTTS) {
        _announceAllCoupons();
      }
    });
  }

  void _announceAllCoupons() {
    final coupons = Coupon.getSampleCoupons();
    final subtotal = widget.items.fold<double>(
      0.0,
      (sum, item) => sum + (item.unitPrice * item.quantity),
    );

    final StringBuffer announcement = StringBuffer();
    announcement.write('選擇優惠券。');
    announcement.write('第1項，不套用優惠券。');

    for (int i = 0; i < coupons.length; i++) {
      final coupon = coupons[i];
      final isAvailable = subtotal >= coupon.minAmount;

      announcement.write('第${i + 2}項，');
      // 明確標示可使用或不可使用
      if (isAvailable) {
        announcement.write('可使用，');
      } else {
        announcement.write('不可使用，');
      }
      announcement.write('${coupon.name}，${coupon.description}。');
    }

    ttsHelper.speak(announcement.toString());
  }

  @override
  Widget build(BuildContext context) {
    final coupons = Coupon.getSampleCoupons();
    final subtotal = widget.items.fold<double>(
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
                label: '不使用優惠券${widget.selectedCoupon == null ? "，已選擇" : ""}',
                description: '點擊取消使用優惠券',
                onTap: () {
                  widget.onCouponSelected(null);
                  if (accessibilityService.shouldUseCustomTTS) {
                    ttsHelper.speak('已取消選擇優惠券');
                  }
                },
                child: Card(
                  color: widget.selectedCoupon == null ? AppColors.primary.withValues(alpha: 0.2) : null,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Icon(
                          widget.selectedCoupon == null ? Icons.radio_button_checked : Icons.radio_button_off,
                          color: widget.selectedCoupon == null ? AppColors.primary : Colors.grey,
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
                final isSelected = widget.selectedCoupon?.id == coupon.id;

                return AccessibleGestureWrapper(
                  label: '${!isAvailable ? "不可使用，" : ""}${coupon.name}，${coupon.description}，折扣 ${coupon.discount.toStringAsFixed(0)} 元${isSelected ? "，已選擇" : ""}',
                  description: isAvailable ? '點擊選擇此優惠券' : '點擊朗讀不可使用原因',
                  onTap: () {
                    if (isAvailable) {
                      // 可使用：選擇優惠券
                      widget.onCouponSelected(coupon);
                      if (accessibilityService.shouldUseCustomTTS) {
                        ttsHelper.speak('已選擇 ${coupon.name}');
                      }
                    } else {
                      // 不可使用：朗讀不可使用訊息
                      if (accessibilityService.shouldUseCustomTTS) {
                        ttsHelper.speak('不可使用，${coupon.name}，${coupon.description}，未達最低消費${coupon.minAmount.toStringAsFixed(0)}元');
                      }
                    }
                  },
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
                  label: '上一步按鈕',
                  description: '返回商品確認步驟',
                  onTap: widget.onPrevious,
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
                  label: '下一步按鈕',
                  description: '前往選擇配送方式',
                  onTap: widget.onNext,
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
class _Step3SelectShipping extends StatefulWidget {
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
  State<_Step3SelectShipping> createState() => _Step3SelectShippingState();
}

class _Step3SelectShippingState extends State<_Step3SelectShipping> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (accessibilityService.shouldUseCustomTTS) {
        _announceAllShippingMethods();
      }
    });
  }

  void _announceAllShippingMethods() {
    final shippingMethods = ShippingMethod.getSampleMethods();
    final StringBuffer announcement = StringBuffer();
    announcement.write('選擇配送方式，共${shippingMethods.length}種方式。');

    for (int i = 0; i < shippingMethods.length; i++) {
      final method = shippingMethods[i];
      announcement.write('第${i + 1}項，');
      announcement.write('${method.name}，${method.description}，');
      announcement.write('運費${method.fee.toStringAsFixed(0)}元。');
    }

    ttsHelper.speak(announcement.toString());
  }

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
              final isSelected = widget.selectedShipping?.id == method.id;

              return AccessibleGestureWrapper(
                label: '${method.name}，${method.description}，運費 ${method.fee.toStringAsFixed(0)} 元${isSelected ? "，已選擇" : ""}',
                description: '點擊選擇此配送方式',
                onTap: () {
                  widget.onShippingSelected(method);
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
                  label: '上一步按鈕',
                  description: '返回選擇優惠券步驟',
                  onTap: widget.onPrevious,
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
                  label: '下一步按鈕${widget.selectedShipping == null ? "，請先選擇配送方式" : ""}',
                  description: '前往選擇付款方式',
                  enabled: widget.selectedShipping != null,
                  onTap: widget.selectedShipping != null ? widget.onNext : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: widget.selectedShipping != null ? AppColors.primary : Colors.grey,
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
class _Step4SelectPayment extends StatefulWidget {
  final List<CartItem> items;
  final Coupon? selectedCoupon;
  final ShippingMethod? selectedShipping;
  final PaymentMethod? selectedPayment;
  final double walletAmount;
  final ValueChanged<PaymentMethod> onPaymentSelected;
  final ValueChanged<double> onWalletAmountChanged;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const _Step4SelectPayment({
    required this.items,
    required this.selectedCoupon,
    required this.selectedShipping,
    required this.selectedPayment,
    required this.walletAmount,
    required this.onPaymentSelected,
    required this.onWalletAmountChanged,
    required this.onNext,
    required this.onPrevious,
  });

  @override
  State<_Step4SelectPayment> createState() => _Step4SelectPaymentState();
}

class _Step4SelectPaymentState extends State<_Step4SelectPayment> {
  final TextEditingController _walletController = TextEditingController();
  double _availableBalance = 0.0;

  @override
  void initState() {
    super.initState();
    _walletController.text = widget.walletAmount > 0 ? widget.walletAmount.toStringAsFixed(0) : '';
    _loadWalletBalance();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (accessibilityService.shouldUseCustomTTS) {
        _announcePaymentInfo();
      }
    });
  }

  void _announcePaymentInfo() {
    final subtotal = widget.items.fold<double>(
      0.0,
      (sum, item) => sum + (item.unitPrice * item.quantity),
    );
    final discount = widget.selectedCoupon?.discount ?? 0.0;
    final shippingFee = widget.selectedShipping?.fee ?? 0.0;
    final total = subtotal - discount + shippingFee;
    final paymentMethods = PaymentMethod.getSampleMethods();

    final StringBuffer announcement = StringBuffer();
    announcement.write('選擇付款方式。費用明細如下，');
    announcement.write('商品小計${subtotal.toStringAsFixed(0)}元，');

    if (widget.selectedCoupon != null) {
      announcement.write('優惠券${widget.selectedCoupon!.name}折抵${discount.toStringAsFixed(0)}元，');
    }

    announcement.write('運費${widget.selectedShipping?.name ?? ""}${shippingFee.toStringAsFixed(0)}元，');
    announcement.write('總計${total.toStringAsFixed(0)}元。');
    announcement.write('付款方式有${paymentMethods.length}種，');

    for (int i = 0; i < paymentMethods.length; i++) {
      final method = paymentMethods[i];
      announcement.write('第${i + 1}項，${method.name}，${method.description}。');
    }

    ttsHelper.speak(announcement.toString());
  }

  @override
  void dispose() {
    _walletController.dispose();
    super.dispose();
  }

  /// 載入錢包餘額
  Future<void> _loadWalletBalance() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.userId;

    if (userId != null) {
      final databaseService = context.read<DatabaseService>();
      final balance = await databaseService.getWalletBalance(userId);

      if (mounted) {
        setState(() {
          _availableBalance = balance;
        });
      }
    }
  }

  /// 更新錢包使用金額
  void _updateWalletAmount(String value) {
    final subtotal = widget.items.fold<double>(
      0.0,
      (sum, item) => sum + (item.unitPrice * item.quantity),
    );
    final discount = widget.selectedCoupon?.discount ?? 0.0;
    final shippingFee = widget.selectedShipping?.fee ?? 0.0;
    final total = subtotal - discount + shippingFee;

    if (value.isEmpty) {
      widget.onWalletAmountChanged(0.0);
      return;
    }

    final amount = double.tryParse(value) ?? 0.0;

    // 檢查金額是否為正整數
    if (amount != amount.floor() || amount < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('金額必須為正整數', style: TextStyle(fontSize: 18)),
          duration: Duration(seconds: 2),
        ),
      );
      _walletController.text = widget.walletAmount > 0 ? widget.walletAmount.toStringAsFixed(0) : '';
      return;
    }

    // 檢查是否超過可用餘額
    if (amount > _availableBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('錢包餘額不足，可用 \$${_availableBalance.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 18)),
          duration: const Duration(seconds: 2),
        ),
      );
      _walletController.text = widget.walletAmount > 0 ? widget.walletAmount.toStringAsFixed(0) : '';
      return;
    }

    // 檢查是否超過訂單總金額
    if (amount > total) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('折抵金額不可超過訂單總金額 \$${total.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 18)),
          duration: const Duration(seconds: 2),
        ),
      );
      _walletController.text = widget.walletAmount > 0 ? widget.walletAmount.toStringAsFixed(0) : '';
      return;
    }

    widget.onWalletAmountChanged(amount);
  }

  @override
  Widget build(BuildContext context) {
    final paymentMethods = PaymentMethod.getSampleMethods();
    final subtotal = widget.items.fold<double>(
      0.0,
      (sum, item) => sum + (item.unitPrice * item.quantity),
    );
    final discount = widget.selectedCoupon?.discount ?? 0.0;
    final shippingFee = widget.selectedShipping?.fee ?? 0.0;
    final walletDiscount = widget.walletAmount;
    final total = subtotal - discount + shippingFee - walletDiscount;

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
                      if (widget.selectedCoupon != null)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('優惠券 (${widget.selectedCoupon!.name})'),
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
                          Text('運費 (${widget.selectedShipping?.name ?? ""})'),
                          Text('\$${shippingFee.toStringAsFixed(0)}'),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      // 錢包折抵輸入
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text('錢包折抵 (可用 \$${_availableBalance.toStringAsFixed(0)})'),
                          ),
                          SizedBox(
                            width: 100,
                            child: TextField(
                              controller: _walletController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(fontSize: AppFontSizes.body),
                              decoration: InputDecoration(
                                hintText: '0',
                                prefixText: '\$',
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: AppSpacing.xs,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onChanged: _updateWalletAmount,
                            ),
                          ),
                        ],
                      ),
                      if (walletDiscount > 0) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(''),
                            Text(
                              '-\$${walletDiscount.toStringAsFixed(0)}',
                              style: const TextStyle(color: Colors.green),
                            ),
                          ],
                        ),
                      ],
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
                final isSelected = widget.selectedPayment?.id == method.id;

                return AccessibleGestureWrapper(
                  label: '${method.name}，${method.description}${isSelected ? "，已選擇" : ""}',
                  description: '點擊選擇此付款方式',
                  onTap: () {
                    widget.onPaymentSelected(method);
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
                  label: '上一步按鈕',
                  description: '返回選擇配送方式步驟',
                  onTap: widget.onPrevious,
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
                  label: '確認結帳按鈕${widget.selectedPayment == null ? "，請先選擇付款方式" : ""}',
                  description: '完成付款並送出訂單',
                  enabled: widget.selectedPayment != null,
                  onTap: widget.selectedPayment != null ? widget.onNext : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: widget.selectedPayment != null ? AppColors.primary : Colors.grey,
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
  final double walletAmount;

  const _Step5Complete({
    required this.items,
    required this.selectedCoupon,
    required this.selectedShipping,
    required this.selectedPayment,
    required this.walletAmount,
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
      final automationService = Provider.of<OrderAutomationService>(context, listen: false);

      final discount = widget.selectedCoupon?.discount ?? 0.0;
      final shippingFee = widget.selectedShipping?.fee ?? 0.0;

      // 判斷是否為貨到付款
      final isCashOnDelivery = widget.selectedPayment!.id == 2;

      // 判斷配送方式類型
      String? deliveryType;
      if (widget.selectedShipping!.id == 1) {
        deliveryType = 'convenience_store'; // 超商取貨
      } else if (widget.selectedShipping!.id == 2) {
        deliveryType = 'home_delivery'; // 宅配
      }

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
        isCashOnDelivery: isCashOnDelivery,
        deliveryType: deliveryType,
      );

      // 扣除錢包餘額（如果有使用）
      if (widget.walletAmount > 0 && mounted) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final userId = authProvider.userId;

        if (userId != null) {
          final success = await db.useWalletBalance(userId, widget.walletAmount);
          if (!success) {
            if (kDebugMode) {
              print('⚠️ [CheckoutPage] 錢包扣款失敗，但訂單已建立');
            }
          }
        }
      }

      // 清除購物車中已結帳的項目
      // 購物車 Provider 會自動監聽資料庫變化並重新載入
      await db.clearSelectedCartItems();

      // 觸發訂單自動化服務
      await automationService.onOrderCreated(order);

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
    } catch (e, stackTrace) {
      setState(() {
        _isCreatingOrder = false;
      });

      // 印出完整的錯誤信息和堆疊追蹤
      if (kDebugMode) {
        print('❌ [CheckoutPage] 建立訂單失敗: $e');
        print('📍 [CheckoutPage] 堆疊追蹤: $stackTrace');
      }

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
            AccessibleGestureWrapper(
              label: '訂單摘要，商品數量${widget.items.length}項，付款方式${widget.selectedPayment?.name ?? "未選擇"}，配送方式${widget.selectedShipping?.name ?? "未選擇"}，總金額${order.total.toStringAsFixed(0)}元',
              description: '點擊可再次朗讀訂單摘要',
              onTap: () {
                if (accessibilityService.shouldUseCustomTTS) {
                  final summaryText = '訂單摘要，商品數量${widget.items.length}項，付款方式${widget.selectedPayment?.name ?? "未選擇"}，配送方式${widget.selectedShipping?.name ?? "未選擇"}，總金額${order.total.toStringAsFixed(0)}元';
                  ttsHelper.speak(summaryText);
                }
              },
              child: Card(
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
            ),
            const SizedBox(height: AppSpacing.lg),
            AccessibleGestureWrapper(
              label: '查看訂單按鈕',
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
              label: '回首頁按鈕',
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
