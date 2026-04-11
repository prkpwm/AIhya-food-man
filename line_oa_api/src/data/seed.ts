import * as menuService from '../services/menu.service';
import * as orderService from '../services/order.service';
import { Menu, Ingredient } from '../types';
import { env } from '../config/env';
import * as fs from 'fs';
import * as path from 'path';

const MERCHANT_ID = 'merchant-001';

function imageUrl(menuId: string, fallback: string): string {
  const localPath = path.join(process.cwd(), 'public', 'images', `${menuId}.jpg`);
  const isLocal = fs.existsSync(localPath);
  return isLocal ? `${env.renderExternalUrl || `http://localhost:${env.port}`}/images/${menuId}.jpg` : fallback;
}

export function seedData(): void {
  // ─── Ingredients ───────────────────────────────────────────────────────────
  const ingredients: Omit<Ingredient, 'id'>[] = [
    { merchantId: MERCHANT_ID, name: 'หมูสับ',      quantity: 2.5,  unit: 'กก.',  lowStockThreshold: 0.5 },
    { merchantId: MERCHANT_ID, name: 'หมูแดง',      quantity: 1.0,  unit: 'กก.',  lowStockThreshold: 0.3 },
    { merchantId: MERCHANT_ID, name: 'หมูกรอบ',     quantity: 0.8,  unit: 'กก.',  lowStockThreshold: 0.3 },
    { merchantId: MERCHANT_ID, name: 'กุ้ง',        quantity: 0.0,  unit: 'กก.',  lowStockThreshold: 0.5 },
    { merchantId: MERCHANT_ID, name: 'ไก่',         quantity: 3.0,  unit: 'กก.',  lowStockThreshold: 0.5 },
    { merchantId: MERCHANT_ID, name: 'ไข่ไก่',      quantity: 30.0, unit: 'ฟอง',  lowStockThreshold: 5.0 },
    { merchantId: MERCHANT_ID, name: 'กระเพรา',     quantity: 0.2,  unit: 'กก.',  lowStockThreshold: 0.1 },
    { merchantId: MERCHANT_ID, name: 'ผักบุ้ง',     quantity: 1.5,  unit: 'กก.',  lowStockThreshold: 0.3 },
    { merchantId: MERCHANT_ID, name: 'เส้นผัดไทย',  quantity: 2.0,  unit: 'กก.',  lowStockThreshold: 0.5 },
    { merchantId: MERCHANT_ID, name: 'เส้นใหญ่',    quantity: 1.5,  unit: 'กก.',  lowStockThreshold: 0.5 },
    { merchantId: MERCHANT_ID, name: 'ข้าวสวย',     quantity: 10.0, unit: 'กก.',  lowStockThreshold: 2.0 },
    { merchantId: MERCHANT_ID, name: 'น้ำมันหอย',   quantity: 0.5,  unit: 'ลิตร', lowStockThreshold: 0.1 },
  ];

  const ingMap: Record<string, string> = {};
  ingredients.forEach((ing, i) => {
    const saved = menuService.upsertIngredient({ ...ing, id: `ing-${String(i + 1).padStart(3, '0')}` });
    ingMap[`ing-${String(i + 1).padStart(3, '0')}`] = saved.id;
  });

  // ─── Menus ─────────────────────────────────────────────────────────────────
  const menus: Omit<Menu, 'id'>[] = [
    {
      merchantId: MERCHANT_ID, name: 'กระเพราหมูสับ', category: 'กระเพรา', shopType: 'streetFood',
      description: 'กระเพราหมูสับผัดเผ็ด หอมกระเพรา เสิร์ฟพร้อมข้าวสวย',
      price: 60, maxSpiceLevel: 5, isAvailable: true,
      imageUrl: imageUrl('menu-001', 'https://images.openai.com/static-rsc-4/b4C5IE7Tpv_Ep7wnqXD7HypX6DpTnb3pEI1EBW9KQgV_kR-gKYq7y8gzTU3pwsIpVi127pZ2XEtfkLNaWTk4_0AXBcPjUCLeyc99iGMV8zvD-QINZjo1uOAdsubyYvYzI4aVsfp92u9k99GAl07KHHbLbEHuS0mY8rp1lpIc7c9mvCXF51G01BWaOlM1AEI8?purpose=inline'),
      ingredientIds: ['ing-001', 'ing-007', 'ing-011'],
    },
    {
      merchantId: MERCHANT_ID, name: 'กระเพราไก่', category: 'กระเพรา', shopType: 'streetFood',
      description: 'กระเพราไก่ผัดเผ็ด เสิร์ฟพร้อมข้าวสวยและไข่ดาว',
      price: 60, maxSpiceLevel: 5, isAvailable: true,
      imageUrl: imageUrl('menu-002', 'https://images.openai.com/static-rsc-4/RxTk3sZohYoPdvwvzm_D-s9T6AhC18rTzgsPmwkkaxwezuGcxQv6EtVdqLy_kl1ElksSe2WxVaJkmwx2A5k7RFa9qOa5Ur2UNnQRuuz5wYl-M3N66mKPdMukEDpK7fuSzA7zRmQALtOYyfYT4P6OzJSoIOMxBdxZzZeAOTb5HQq5uZJLud7g0zExkKDLog7O?purpose=inline'),
      ingredientIds: ['ing-005', 'ing-007', 'ing-011'],
    },
    {
      merchantId: MERCHANT_ID, name: 'กระเพรากุ้ง', category: 'กระเพรา', shopType: 'streetFood',
      description: 'กระเพรากุ้งสด', price: 80, maxSpiceLevel: 5, isAvailable: false,
      imageUrl: imageUrl('menu-003', 'https://images.openai.com/static-rsc-4/LWhFKf3jUTsmen3Y9wpEb-qgfdPZzHBhEwQpxB5FjuzstkfaYb9IGG_y2XzcfQZTh7CQMP97UCS3X27hA8eTL-HwQ9X9C0fsL7jnNJONeqizZrPmN5kBLwATbRuxtudGBmmetS2aSbX6rnP2vbPHJNzZvqbNsO5EOfuU70S1aWyfMPuNv7lkhjXrQbwt0bbU?purpose=inline'),
      ingredientIds: ['ing-004', 'ing-007', 'ing-011'],
    },
    {
      merchantId: MERCHANT_ID, name: 'ผัดไทยกุ้งสด', category: 'ผัดไทย', shopType: 'streetFood',
      description: 'ผัดไทยกุ้งสดใส่ถั่วงอก มะนาว ถั่วลิสง', price: 90, maxSpiceLevel: 3, isAvailable: false,
      imageUrl: imageUrl('menu-004', 'https://images.openai.com/static-rsc-4/FUkiLfBDDtxHS4tYfHPreB7nPLNTpLodRCckLkmidP1lx2unoADESUCPId6vIUbrg1XjaJF0J7rhFk7OdSB_3FVBmZfCA4-tGMLzvld8P9aSDqZQfdtuCqHuWqtmhXmCnlLw_RofFUZuW4vbWV9sSaQ7YhrIC_hRiv_lyvb64Gc?purpose=inline'),
      ingredientIds: ['ing-004', 'ing-009', 'ing-006'],
    },
    {
      merchantId: MERCHANT_ID, name: 'ต้มยำกุ้ง', category: 'ต้มยำ', shopType: 'streetFood',
      description: 'ต้มยำกุ้งสด รสเปรี้ยวเผ็ด หอมตะไคร้ ใบมะกรูด', price: 120, maxSpiceLevel: 4, isAvailable: false,
      imageUrl: imageUrl('menu-005', 'https://images.openai.com/static-rsc-4/PF5Nbp9Ni2IiuYHTmLlbDTf0miX8siMpOvQQBadsAKth_P77ojAKwrRD6JIPfk4cnswFVGwesePXRXiLvUz2Dk53LQVcOWhUoaDQpbRla78F5of2CUfWD73wGLaFlQ0H6se-axcfa6THGpNdxNk-MlMLBm5snC1cC0sVjfd2S2TFuj8XG5aNMqqn7_CROOpb?purpose=inline'),
      ingredientIds: ['ing-004', 'ing-011'],
    },
    {
      merchantId: MERCHANT_ID, name: 'แกงเขียวหวานไก่', category: 'แกง', shopType: 'streetFood',
      description: 'แกงเขียวหวานไก่ กะทิสด มะเขือ ใบโหระพา', price: 80, maxSpiceLevel: 3, isAvailable: true,
      imageUrl: imageUrl('menu-006', 'https://images.openai.com/static-rsc-4/JyI_93GqEApry9v94R7CueY17nAqb4FkNukQGEOYVFzeViedR9eaHoaF8xVVptMx7ycLeyflPOnDlIUyiOUEfQ0ull-j6YN5T4QuK_Rl_fOkw9jAMtfIQv_TXWVGsEB74KykMW538iL4xlfKtch8UHLLwUeIVXeUA34wRvn3foXjqJrYYeEzsX4lDV1tpYCF?purpose=inline'),
      ingredientIds: ['ing-005', 'ing-011'],
    },
    {
      merchantId: MERCHANT_ID, name: 'ส้มตำไทย', category: 'ยำ', shopType: 'streetFood',
      description: 'ส้มตำมะละกอสด รสเปรี้ยวเผ็ด มะนาว น้ำปลา พริก ถั่วลิสง', price: 50, maxSpiceLevel: 5, isAvailable: true,
      imageUrl: imageUrl('menu-007', 'https://images.openai.com/static-rsc-4/KqeYr35dnhchqj5qn0S0XU34nSKpTGxNzLq4lPUq6trtWgvpQ6SE-HS1T9wckfcsc7FBCuZc9h6WfH2w-JhYj6s1y_9LHYdVK22jUwSbZT6feHQd-NdWt0tB7jgQQcjBJUMGpqtI-uyKD-Sld0evnvhqTANCqVtEXWelj-VdfBh8witDwWCJ0oTxrI44Zqut?purpose=inline'),
      ingredientIds: ['ing-008', 'ing-011'],
    },
    {
      merchantId: MERCHANT_ID, name: 'ราดหน้าหมูแดงหมูกรอบ', category: 'ราดหน้า', shopType: 'streetFood',
      description: 'ราดหน้าเส้นใหญ่ หมูแดง หมูกรอบ', price: 75, maxSpiceLevel: 2, isAvailable: true,
      imageUrl: imageUrl('menu-008', 'https://images.openai.com/static-rsc-4/0IZ_Q3EF8dYCAnopyXhYX3WToBicRNcm4A8aN2QeWcT8UdzjnPYnzj6RvIQk080-mq-XoNVRRsexLdBubm7lzMoKgTihv0a3CE-uPQ_RAkGlZVceVJ9XelM6iZMxk7P3Y0G_QkJGFeAjqcs8sa9nwe2kkB8UUYRTbYwumLzMcTGYyElqwF2bK6s-sS1AvLZy?purpose=inline'),
      ingredientIds: ['ing-002', 'ing-003', 'ing-010'],
    },
    {
      merchantId: MERCHANT_ID, name: 'หมูปิ้ง', category: 'ปิ้งย่าง', shopType: 'streetFood',
      description: 'หมูปิ้งหมักเครื่องเทศ หอมหวาน ย่างไฟ เสิร์ฟพร้อมข้าวเหนียว', price: 40, maxSpiceLevel: 1, isAvailable: true,
      imageUrl: imageUrl('menu-009', 'https://images.openai.com/static-rsc-4/z8sff6Eqv6isDIfsYkYrjSJvwDag8Y8xnP5odNqw5KY-PHlNEO5Nizfm-SkVt_9Qg9LmFV0ijRYjpqRitBXFOxsscLTNCYzMbupfnGQGhK4t-IzyxH4CoxoYy2nXLs_capF--eP-lQvD-5TmXBSnufHzAak_vQ7SO42oIENz5wM_GPeoz4ZO76PpaOIZV1os?purpose=inline'),
      ingredientIds: ['ing-001', 'ing-011'],
    },
    {
      merchantId: MERCHANT_ID, name: 'ข้าวเหนียวมะม่วง', category: 'ของหวาน', shopType: 'streetFood',
      description: 'ข้าวเหนียวมะม่วงสุก กะทิสด หอมหวาน', price: 65, maxSpiceLevel: 0, isAvailable: true,
      imageUrl: imageUrl('menu-010', 'https://images.openai.com/static-rsc-4/Zf7x6pSro7xPHxl4oFzXW9PFy6TLoQnALv8mMkKDp8PuOT2A4lO9SwNS9-nY8pf6-QVRdWSHrMqvGA7gMXM2zz1BcnSfR3TNisEJOKuVXlidaEHVttA0U4DooSyqDuPrbWqD6yr7QFW7OCnOxJsc-fpkSeKCcv8c0sw8an8watYwoUVY7pU_3dxbkn-nwSxu?purpose=inline'),
      ingredientIds: ['ing-011'],
    },
  ];

  menus.forEach((menu, i) => {
    menuService.upsertMenu({ ...menu, id: `menu-${String(i + 1).padStart(3, '0')}` });
  });

  // ─── Orders ────────────────────────────────────────────────────────────────
  orderService.createOrder(MERCHANT_ID, 'cust-001', 'คุณสมชาย', [
    { menuId: 'menu-001', menuName: 'กระเพราหมูสับ', quantity: 2, unitPrice: 60, spiceLevel: 3, customNote: null },
  ]);
  orderService.createOrder(MERCHANT_ID, 'cust-002', 'คุณสมหญิง', [
    { menuId: 'menu-002', menuName: 'กระเพราไก่', quantity: 1, unitPrice: 60, spiceLevel: 5, customNote: 'ไม่ใส่พริก' },
  ]);
  orderService.createOrder(MERCHANT_ID, 'cust-003', 'คุณวิชัย', [
    { menuId: 'menu-008', menuName: 'ราดหน้าหมูแดงหมูกรอบ', quantity: 1, unitPrice: 75, spiceLevel: 0, customNote: null },
  ]);
}
