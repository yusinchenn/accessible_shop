/// ai_agent_tools.dart
/// AI Agent 工具定義
/// 定義所有可用的 Function Calling Tools
library;

/// AI Agent 可用的工具列表
class AIAgentTools {
  /// 取得所有可用的 Tools（符合 OpenAI Function Calling 格式）
  static List<Map<String, dynamic>> getAllTools() {
    return [
      searchProductsTool,
      getProductDetailTool,
      addToCartTool,
      getCartItemsTool,
      updateCartQuantityTool,
      removeFromCartTool,
      checkoutTool,
      getOrdersTool,
      getOrderDetailTool,
      getNotificationsTool,
    ];
  }

  /// 1. 搜尋商品
  static const Map<String, dynamic> searchProductsTool = {
    'type': 'function',
    'function': {
      'name': 'search_products',
      'description': '搜尋商品，支援商品名稱、描述、分類、店家名稱等多欄位智能搜尋',
      'parameters': {
        'type': 'object',
        'properties': {
          'keyword': {
            'type': 'string',
            'description': '搜尋關鍵字',
          },
        },
        'required': ['keyword'],
      },
    },
  };

  /// 2. 取得商品詳細資訊
  static const Map<String, dynamic> getProductDetailTool = {
    'type': 'function',
    'function': {
      'name': 'get_product_detail',
      'description': '取得商品詳細資訊，包括價格、描述、庫存、評分、所屬商家等完整資料',
      'parameters': {
        'type': 'object',
        'properties': {
          'product_id': {
            'type': 'integer',
            'description': '商品ID',
          },
        },
        'required': ['product_id'],
      },
    },
  };

  /// 3. 加入購物車
  static const Map<String, dynamic> addToCartTool = {
    'type': 'function',
    'function': {
      'name': 'add_to_cart',
      'description':
          '將商品加入購物車。可指定規格（尺寸、顏色）和數量。如果用戶沒有明確指定規格，應詢問用戶需要什麼規格。',
      'parameters': {
        'type': 'object',
        'properties': {
          'product_id': {
            'type': 'integer',
            'description': '商品ID',
          },
          'size': {
            'type': 'string',
            'description': '尺寸規格',
            'enum': ['通用尺寸', 'S', 'M', 'L', 'XL'],
          },
          'color': {
            'type': 'string',
            'description': '顏色規格',
            'enum': ['預設顏色', '黑色', '白色', '灰色', '藍色', '紅色'],
          },
          'quantity': {
            'type': 'integer',
            'description': '數量（預設為1）',
            'minimum': 1,
          },
        },
        'required': ['product_id', 'size', 'color'],
      },
    },
  };

  /// 4. 查看購物車
  static const Map<String, dynamic> getCartItemsTool = {
    'type': 'function',
    'function': {
      'name': 'get_cart_items',
      'description': '取得購物車中的所有項目，包括商品名稱、規格、數量、價格等資訊',
      'parameters': {
        'type': 'object',
        'properties': {},
      },
    },
  };

  /// 5. 更新購物車數量
  static const Map<String, dynamic> updateCartQuantityTool = {
    'type': 'function',
    'function': {
      'name': 'update_cart_quantity',
      'description': '更新購物車中指定項目的數量',
      'parameters': {
        'type': 'object',
        'properties': {
          'cart_item_id': {
            'type': 'integer',
            'description': '購物車項目ID',
          },
          'quantity': {
            'type': 'integer',
            'description': '新的數量',
            'minimum': 1,
          },
        },
        'required': ['cart_item_id', 'quantity'],
      },
    },
  };

  /// 6. 移除購物車項目
  static const Map<String, dynamic> removeFromCartTool = {
    'type': 'function',
    'function': {
      'name': 'remove_from_cart',
      'description': '從購物車中移除指定項目',
      'parameters': {
        'type': 'object',
        'properties': {
          'cart_item_id': {
            'type': 'integer',
            'description': '購物車項目ID',
          },
        },
        'required': ['cart_item_id'],
      },
    },
  };

  /// 7. 結帳
  static const Map<String, dynamic> checkoutTool = {
    'type': 'function',
    'function': {
      'name': 'checkout',
      'description':
          '為購物車中已選取的項目建立訂單並完成結帳。會自動按商家分組建立多個訂單。如果用戶有特殊配送需求（如超商取貨），應詢問必要資訊。',
      'parameters': {
        'type': 'object',
        'properties': {
          'shipping_method_id': {
            'type': 'integer',
            'description': '配送方式ID（1: 宅配, 2: 超商取貨）。預設為1（宅配）',
          },
          'payment_method_id': {
            'type': 'integer',
            'description': '付款方式ID（1: 信用卡, 2: ATM轉帳, 3: 貨到付款）。預設為1（信用卡）',
          },
          'coupon_id': {
            'type': 'integer',
            'description': '優惠券ID（可選）',
          },
          'delivery_type': {
            'type': 'string',
            'description': '配送類型資訊（例如：超商取貨的店號）',
          },
        },
        'required': [],
      },
    },
  };

  /// 8. 查詢訂單
  static const Map<String, dynamic> getOrdersTool = {
    'type': 'function',
    'function': {
      'name': 'get_orders',
      'description':
          '取得用戶的訂單列表。可選擇性篩選訂單狀態或物流狀態。如果不指定篩選條件，則返回所有訂單。',
      'parameters': {
        'type': 'object',
        'properties': {
          'main_status': {
            'type': 'string',
            'description': '主要訂單狀態篩選',
            'enum': [
              'pendingPayment',
              'pendingShipment',
              'pendingDelivery',
              'completed',
              'returnRefund',
              'invalid',
            ],
          },
          'logistics_status': {
            'type': 'string',
            'description': '物流狀態篩選（僅適用於待收貨訂單）',
            'enum': [
              'none',
              'inTransit',
              'arrivedAtPickupPoint',
              'signed',
            ],
          },
        },
        'required': [],
      },
    },
  };

  /// 9. 取得訂單詳情
  static const Map<String, dynamic> getOrderDetailTool = {
    'type': 'function',
    'function': {
      'name': 'get_order_detail',
      'description': '取得訂單的詳細資訊，包括訂單項目、金額明細、配送資訊、付款資訊等',
      'parameters': {
        'type': 'object',
        'properties': {
          'order_id': {
            'type': 'integer',
            'description': '訂單ID',
          },
        },
        'required': ['order_id'],
      },
    },
  };

  /// 10. 查詢通知
  static const Map<String, dynamic> getNotificationsTool = {
    'type': 'function',
    'function': {
      'name': 'get_notifications',
      'description': '取得通知列表。可選擇只顯示未讀通知，或顯示所有通知。',
      'parameters': {
        'type': 'object',
        'properties': {
          'unread_only': {
            'type': 'boolean',
            'description': '是否只顯示未讀通知（預設為false，顯示所有通知）',
          },
          'type': {
            'type': 'string',
            'description': '通知類型篩選',
            'enum': ['order', 'promotion', 'system', 'reward'],
          },
        },
        'required': [],
      },
    },
  };
}
