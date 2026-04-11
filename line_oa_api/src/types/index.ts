// ─── User ─────────────────────────────────────────────────────────────────────

export interface User {
  id: string;
  email: string;
  shopName: string;
  lineChannelId: string;
  lineChannelSecret: string;
  lineChannelAccessToken: string;
  tier: SubscriptionTier;
  subscriptionExpiry: Date | null;
  dailyCustomerCount: number;
  createdAt: Date;
}

export type SubscriptionTier = 'free' | 'silver' | 'gold' | 'platinum';

export const DAILY_LIMIT: Record<SubscriptionTier, number> = {
  free: 20,
  silver: 100,
  gold: 500,
  platinum: -1,
};

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

// ─── Menu ─────────────────────────────────────────────────────────────────────

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
  addons?: MenuAddon[];           // optional top-ups (checkboxes, multi-select)
  portionOptions?: MenuPortionOption[]; // optional portion types (radio, single-select)
}

export type ShopType = 'streetFood' | 'restaurant' | 'buffet';

// ─── Ingredient ───────────────────────────────────────────────────────────────

export interface Ingredient {
  id: string;
  merchantId: string;
  name: string;
  quantity: number;
  unit: string;
  lowStockThreshold: number;
}

// ─── Order ────────────────────────────────────────────────────────────────────

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

// ─── API Response ─────────────────────────────────────────────────────────────

export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
}

export interface ErrorResponse {
  code: string;
  en: string;
  th: string;
}
