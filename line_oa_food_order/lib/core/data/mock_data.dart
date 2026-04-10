import 'package:line_oa_food_order/core/models/ingredient_model.dart';
import 'package:line_oa_food_order/core/models/menu_model.dart';
import 'package:line_oa_food_order/core/models/order_model.dart';
import 'package:line_oa_food_order/core/models/user_model.dart';

// ─── User ────────────────────────────────────────────────────────────────────

final mockUser = UserModel(
  id: 'user-001',
  email: 'test01@lineoa.com',
  password: '123456',
  shopName: 'ร้านข้าวผัดแม่มาลี',
  lineChannelId: 'CH-TEST-001',
  lineChannelSecret: 'secret-test-001',
  tier: SubscriptionTier.free,
  subscriptionExpiry: DateTime(2026, 12, 31),
);

// ─── Ingredients ─────────────────────────────────────────────────────────────

final mockIngredients = <IngredientModel>[
  const IngredientModel(id: 'ing-001', name: 'หมูสับ', quantity: 2.5, unit: 'กก.', lowStockThreshold: 0.5),
  const IngredientModel(id: 'ing-002', name: 'หมูแดง', quantity: 1.0, unit: 'กก.', lowStockThreshold: 0.3),
  const IngredientModel(id: 'ing-003', name: 'หมูกรอบ', quantity: 0.8, unit: 'กก.', lowStockThreshold: 0.3),
  const IngredientModel(id: 'ing-004', name: 'กุ้ง', quantity: 0.0, unit: 'กก.', lowStockThreshold: 0.5),
  const IngredientModel(id: 'ing-005', name: 'ไก่', quantity: 3.0, unit: 'กก.', lowStockThreshold: 0.5),
  const IngredientModel(id: 'ing-006', name: 'ไข่ไก่', quantity: 30.0, unit: 'ฟอง', lowStockThreshold: 5.0),
  const IngredientModel(id: 'ing-007', name: 'กระเพรา', quantity: 0.2, unit: 'กก.', lowStockThreshold: 0.1),
  const IngredientModel(id: 'ing-008', name: 'ผักบุ้ง', quantity: 1.5, unit: 'กก.', lowStockThreshold: 0.3),
  const IngredientModel(id: 'ing-009', name: 'เส้นผัดไทย', quantity: 2.0, unit: 'กก.', lowStockThreshold: 0.5),
  const IngredientModel(id: 'ing-010', name: 'เส้นใหญ่', quantity: 1.5, unit: 'กก.', lowStockThreshold: 0.5),
  const IngredientModel(id: 'ing-011', name: 'ข้าวสวย', quantity: 10.0, unit: 'กก.', lowStockThreshold: 2.0),
  const IngredientModel(id: 'ing-012', name: 'น้ำมันหอย', quantity: 0.5, unit: 'ลิตร', lowStockThreshold: 0.1),
];

// ─── Menus ───────────────────────────────────────────────────────────────────

final mockMenus = <MenuModel>[
  MenuModel(
    id: 'menu-001',
    merchantId: 'merchant-001',
    name: 'กระเพราหมูสับ',
    description: 'กระเพราหมูสับผัดเผ็ด หอมกระเพรา เสิร์ฟพร้อมข้าวสวย',
    price: 60,
    imageUrl: 'https://images.openai.com/static-rsc-4/b4C5IE7Tpv_Ep7wnqXD7HypX6DpTnb3pEI1EBW9KQgV_kR-gKYq7y8gzTU3pwsIpVi127pZ2XEtfkLNaWTk4_0AXBcPjUCLeyc99iGMV8zvD-QINZjo1uOAdsubyYvYzI4aVsfp92u9k99GAl07KHHbLbEHuS0mY8rp1lpIc7c9mvCXF51G01BWaOlM1AEI8?purpose=inline',
    category: 'กระเพรา',
    shopType: ShopType.streetFood,
    maxSpiceLevel: 5,
    ingredientIds: ['ing-001', 'ing-007', 'ing-011'],
    isAvailable: true,
  ),
  MenuModel(
    id: 'menu-002',
    merchantId: 'merchant-001',
    name: 'กระเพราไก่',
    description: 'กระเพราไก่ผัดเผ็ด เสิร์ฟพร้อมข้าวสวยและไข่ดาว',
    price: 60,
    imageUrl: 'https://images.openai.com/static-rsc-4/RxTk3sZohYoPdvwvzm_D-s9T6AhC18rTzgsPmwkkaxwezuGcxQv6EtVdqLy_kl1ElksSe2WxVaJkmwx2A5k7RFa9qOa5Ur2UNnQRuuz5wYl-M3N66mKPdMukEDpK7fuSzA7zRmQALtOYyfYT4P6OzJSoIOMxBdxZzZeAOTb5HQq5uZJLud7g0zExkKDLog7O?purpose=inline',
    category: 'กระเพรา',
    shopType: ShopType.streetFood,
    maxSpiceLevel: 5,
    ingredientIds: ['ing-005', 'ing-007', 'ing-011'],
    isAvailable: true,
  ),
  MenuModel(
    id: 'menu-003',
    merchantId: 'merchant-001',
    name: 'กระเพรากุ้ง',
    description: 'กระเพรากุ้งสด',
    price: 80,
    imageUrl: 'https://images.openai.com/static-rsc-4/LWhFKf3jUTsmen3Y9wpEb-qgfdPZzHBhEwQpxB5FjuzstkfaYb9IGG_y2XzcfQZTh7CQMP97UCS3X27hA8eTL-HwQ9X9C0fsL7jnNJONeqizZrPmN5kBLwATbRuxtudGBmmetS2aSbX6rnP2vbPHJNzZvqbNsO5EOfuU70S1aWyfMPuNv7lkhjXrQbwt0bbU?purpose=inline',
    category: 'กระเพรา',
    shopType: ShopType.streetFood,
    maxSpiceLevel: 5,
    ingredientIds: ['ing-004', 'ing-007', 'ing-011'],
    isAvailable: false, // กุ้งหมด
  ),
  MenuModel(
    id: 'menu-004',
    merchantId: 'merchant-001',
    name: 'ผัดไทยกุ้งสด',
    description: 'ผัดไทยกุ้งสดใส่ถั่วงอก มะนาว ถั่วลิสง',
    price: 90,
    imageUrl: 'https://images.openai.com/static-rsc-4/FUkiLfBDDtxHS4tYfHPreB7nPLNTpLodRCckLkmidP1lx2unoADESUCPId6vIUbrg1XjaJF0J7rhFk7OdSB_3FVBmZfCA4-tGMLzvld8P9aSDqZQfdtuCqHuWqtmhXmCnlLw_RofFUZuW4vbWV9sSaQ7YhrIC_hRiv_lyvb64Gc?purpose=inline',
    category: 'ผัดไทย',
    shopType: ShopType.streetFood,
    maxSpiceLevel: 3,
    ingredientIds: ['ing-004', 'ing-009', 'ing-006'],
    isAvailable: false, // กุ้งหมด
  ),
  MenuModel(
    id: 'menu-005',
    merchantId: 'merchant-001',
    name: 'ต้มยำกุ้ง',
    description: 'ต้มยำกุ้งสด รสเปรี้ยวเผ็ด หอมตะไคร้ ใบมะกรูด',
    price: 120,
    imageUrl: 'https://images.openai.com/static-rsc-4/PF5Nbp9Ni2IiuYHTmLlbDTf0miX8siMpOvQQBadsAKth_P77ojAKwrRD6JIPfk4cnswFVGwesePXRXiLvUz2Dk53LQVcOWhUoaDQpbRla78F5of2CUfWD73wGLaFlQ0H6se-axcfa6THGpNdxNk-MlMLBm5snC1cC0sVjfd2S2TFuj8XG5aNMqqn7_CROOpb?purpose=inline',
    category: 'ต้มยำ',
    shopType: ShopType.streetFood,
    maxSpiceLevel: 4,
    ingredientIds: ['ing-004', 'ing-011'],
    isAvailable: false, // กุ้งหมด
  ),
  MenuModel(
    id: 'menu-006',
    merchantId: 'merchant-001',
    name: 'แกงเขียวหวานไก่',
    description: 'แกงเขียวหวานไก่ กะทิสด มะเขือ ใบโหระพา',
    price: 80,
    imageUrl: 'https://images.openai.com/static-rsc-4/JyI_93GqEApry9v94R7CueY17nAqb4FkNukQGEOYVFzeViedR9eaHoaF8xVVptMx7ycLeyflPOnDlIUyiOUEfQ0ull-j6YN5T4QuK_Rl_fOkw9jAMtfIQv_TXWVGsEB74KykMW538iL4xlfKtch8UHLLwUeIVXeUA34wRvn3foXjqJrYYeEzsX4lDV1tpYCF?purpose=inline',
    category: 'แกง',
    shopType: ShopType.streetFood,
    maxSpiceLevel: 3,
    ingredientIds: ['ing-005', 'ing-011'],
    isAvailable: true,
  ),
  MenuModel(
    id: 'menu-007',
    merchantId: 'merchant-001',
    name: 'ส้มตำไทย',
    description: 'ส้มตำมะละกอสด รสเปรี้ยวเผ็ด มะนาว น้ำปลา พริก ถั่วลิสง',
    price: 50,
    imageUrl: 'https://images.openai.com/static-rsc-4/KqeYr35dnhchqj5qn0S0XU34nSKpTGxNzLq4lPUq6trtWgvpQ6SE-HS1T9wckfcsc7FBCuZc9h6WfH2w-JhYj6s1y_9LHYdVK22jUwSbZT6feHQd-NdWt0tB7jgQQcjBJUMGpqtI-uyKD-Sld0evnvhqTANCqVtEXWelj-VdfBh8witDwWCJ0oTxrI44Zqut?purpose=inline',
    category: 'ยำ',
    shopType: ShopType.streetFood,
    maxSpiceLevel: 5,
    ingredientIds: ['ing-008', 'ing-011'],
    isAvailable: true,
  ),
  MenuModel(
    id: 'menu-008',
    merchantId: 'merchant-001',
    name: 'ราดหน้าหมูแดงหมูกรอบ',
    description: 'ราดหน้าเส้นใหญ่ หมูแดง หมูกรอบ',
    price: 75,
    imageUrl: 'https://images.openai.com/static-rsc-4/0IZ_Q3EF8dYCAnopyXhYX3WToBicRNcm4A8aN2QeWcT8UdzjnPYnzj6RvIQk080-mq-XoNVRRsexLdBubm7lzMoKgTihv0a3CE-uPQ_RAkGlZVceVJ9XelM6iZMxk7P3Y0G_QkJGFeAjqcs8sa9nwe2kkB8UUYRTbYwumLzMcTGYyElqwF2bK6s-sS1AvLZy?purpose=inline',
    category: 'ราดหน้า',
    shopType: ShopType.streetFood,
    maxSpiceLevel: 2,
    ingredientIds: ['ing-002', 'ing-003', 'ing-010'],
    isAvailable: true,
  ),
  MenuModel(
    id: 'menu-009',
    merchantId: 'merchant-001',
    name: 'หมูปิ้ง',
    description: 'หมูปิ้งหมักเครื่องเทศ หอมหวาน ย่างไฟ เสิร์ฟพร้อมข้าวเหนียว',
    price: 40,
    imageUrl: 'https://images.openai.com/static-rsc-4/z8sff6Eqv6isDIfsYkYrjSJvwDag8Y8xnP5odNqw5KY-PHlNEO5Nizfm-SkVt_9Qg9LmFV0ijRYjpqRitBXFOxsscLTNCYzMbupfnGQGhK4t-IzyxH4CoxoYy2nXLs_capF--eP-lQvD-5TmXBSnufHzAak_vQ7SO42oIENz5wM_GPeoz4ZO76PpaOIZV1os?purpose=inline',
    category: 'ปิ้งย่าง',
    shopType: ShopType.streetFood,
    maxSpiceLevel: 1,
    ingredientIds: ['ing-001', 'ing-011'],
    isAvailable: true,
  ),
  MenuModel(
    id: 'menu-010',
    merchantId: 'merchant-001',
    name: 'ข้าวเหนียวมะม่วง',
    description: 'ข้าวเหนียวมะม่วงสุก กะทิสด หอมหวาน',
    price: 65,
    imageUrl: 'https://images.openai.com/static-rsc-4/Zf7x6pSro7xPHxl4oFzXW9PFy6TLoQnALv8mMkKDp8PuOT2A4lO9SwNS9-nY8pf6-QVRdWSHrMqvGA7gMXM2zz1BcnSfR3TNisEJOKuVXlidaEHVttA0U4DooSyqDuPrbWqD6yr7QFW7OCnOxJsc-fpkSeKCcv8c0sw8an8watYwoUVY7pU_3dxbkn-nwSxu?purpose=inline',
    category: 'ของหวาน',
    shopType: ShopType.streetFood,
    maxSpiceLevel: 0,
    ingredientIds: ['ing-011'],
    isAvailable: true,
  ),
];

// ─── Orders ──────────────────────────────────────────────────────────────────

final mockOrders = <OrderModel>[
  OrderModel(
    id: 'order-001',
    customerId: 'cust-001',
    customerName: 'คุณสมชาย',
    items: [
      const OrderItemModel(menuId: 'menu-001', menuName: 'กระเพราหมูสับ', quantity: 2, unitPrice: 60, spiceLevel: 3),
      const OrderItemModel(menuId: 'menu-004', menuName: 'ข้าวผัดหมู', quantity: 1, unitPrice: 55, spiceLevel: 1),
    ],
    status: OrderStatus.preparing,
    createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
    estimatedWaitMinutes: 5,
  ),
  OrderModel(
    id: 'order-002',
    customerId: 'cust-002',
    customerName: 'คุณสมหญิง',
    items: [
      const OrderItemModel(menuId: 'menu-002', menuName: 'กระเพราไก่', quantity: 1, unitPrice: 60, spiceLevel: 5, customNote: 'ไม่ใส่พริก'),
      const OrderItemModel(menuId: 'menu-007', menuName: 'ผัดผักบุ้งไฟแดง', quantity: 1, unitPrice: 50, spiceLevel: 2),
    ],
    status: OrderStatus.pending,
    createdAt: DateTime.now().subtract(const Duration(minutes: 3)),
    estimatedWaitMinutes: 15,
  ),
  OrderModel(
    id: 'order-003',
    customerId: 'cust-003',
    customerName: 'คุณวิชัย',
    items: [
      const OrderItemModel(menuId: 'menu-008', menuName: 'ราดหน้าหมูแดงหมูกรอบ', quantity: 1, unitPrice: 75, spiceLevel: 0),
    ],
    status: OrderStatus.ready,
    createdAt: DateTime.now().subtract(const Duration(minutes: 20)),
    estimatedWaitMinutes: 0,
  ),
  OrderModel(
    id: 'order-004',
    customerId: 'cust-004',
    customerName: 'คุณนภา',
    items: [
      const OrderItemModel(menuId: 'menu-001', menuName: 'กระเพราหมูสับ', quantity: 3, unitPrice: 60, spiceLevel: 4),
      const OrderItemModel(menuId: 'menu-005', menuName: 'ข้าวผัดไก่', quantity: 2, unitPrice: 55, spiceLevel: 1),
    ],
    status: OrderStatus.completed,
    createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    estimatedWaitMinutes: 0,
  ),
  OrderModel(
    id: 'order-005',
    customerId: 'cust-005',
    customerName: 'คุณประสิทธิ์',
    items: [
      const OrderItemModel(menuId: 'menu-001', menuName: 'กระเพราหมูสับ', quantity: 1, unitPrice: 60, spiceLevel: 2),
    ],
    status: OrderStatus.confirmed,
    createdAt: DateTime.now().subtract(const Duration(minutes: 7)),
    estimatedWaitMinutes: 10,
  ),
];
