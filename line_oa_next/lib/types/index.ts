export interface MenuAddon {
  id: string;
  name: string;
  price: number;
}

export interface MenuPortionOption {
  id: string;
  name: string;
  extraPrice: number;
}

export interface Menu {
  id: string;
  merchantId: string;
  name: string;
  description: string;
  price: number;
  imageUrl: string | null;
  category: string;
  shopType: ShopType;
  maxSpiceLevel: number;
  ingredientIds: string[];
  isAvailable: boolean;
  addons?: MenuAddon[];
  portionOptions?: MenuPortionOption[];
}

export type ShopType = 'streetFood' | 'restaurant' | 'buffet';

export interface Ingredient {
  id: string;
  merchantId: string;
  name: string;
  quantity: number;
  unit: string;
  lowStockThreshold: number;
}

export interface Order {
  id: string;
  merchantId: string;
  customerId: string;
  customerName: string;
  items: OrderItem[];
  status: OrderStatus;
  totalPrice: number;
  estimatedWaitMinutes: number;
  note: string | null;
  createdAt: Date;
  updatedAt: Date;
}

export interface OrderItem {
  menuId: string;
  menuName: string;
  quantity: number;
  unitPrice: number;
  spiceLevel: number;
  customNote: string | null;
}

export type OrderStatus =
  | 'pending'
  | 'confirmed'
  | 'preparing'
  | 'ready'
  | 'completed'
  | 'cancelled';

export interface ErrorResponse {
  code: string;
  en: string;
  th: string;
}

export interface User {
  id: string;
  email: string;
  name: string;
  merchantId: string | null;
}

export interface Merchant {
  id: string;
  ownerId: string;
  name: string;
}

export interface JwtPayload {
  userId: string;
  email: string;
  merchantId: string | null;
}
