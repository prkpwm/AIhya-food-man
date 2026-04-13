import { Schema, model, models } from 'mongoose';

// ─── User ─────────────────────────────────────────────────────────────────────

const UserSchema = new Schema({
  _id: { type: String, required: true }, // userId = uuid
  email: { type: String, required: true, unique: true, lowercase: true },
  passwordHash: { type: String, required: true },
  name: { type: String, required: true },
  merchantId: { type: String, default: null }, // linked merchant
}, { timestamps: true });

export const UserModel = models.User ?? model('User', UserSchema);

// ─── Merchant ─────────────────────────────────────────────────────────────────

const MerchantSchema = new Schema({
  _id: { type: String, required: true }, // merchantId = uuid
  ownerId: { type: String, required: true, index: true }, // userId
  name: { type: String, required: true },
}, { timestamps: true });

export const MerchantModel = models.Merchant ?? model('Merchant', MerchantSchema);

// ─── Order ────────────────────────────────────────────────────────────────────

const OrderItemSchema = new Schema({
  menuId: String,
  menuName: String,
  quantity: Number,
  unitPrice: Number,
  spiceLevel: Number,
  customNote: { type: String, default: null },
}, { _id: false });

const OrderSchema = new Schema({
  _id: { type: String, required: true },
  merchantId: { type: String, required: true, index: true },
  customerId: { type: String, required: true, index: true },
  customerName: String,
  items: [OrderItemSchema],
  status: { type: String, default: 'pending', index: true },
  totalPrice: Number,
  estimatedWaitMinutes: Number,
  note: { type: String, default: null },
}, { timestamps: { createdAt: 'createdAt', updatedAt: 'updatedAt' } });

export const OrderModel = models.Order ?? model('Order', OrderSchema);

// ─── Menu ─────────────────────────────────────────────────────────────────────

const MenuSchema = new Schema({
  _id: { type: String, required: true },
  merchantId: { type: String, required: true, index: true },
  name: String,
  description: String,
  price: Number,
  imageUrl: { type: String, default: null },
  category: String,
  shopType: String,
  maxSpiceLevel: { type: Number, default: 0 },
  ingredientIds: [String],
  isAvailable: { type: Boolean, default: true },
  addons: { type: Array, default: [] },
  portionOptions: { type: Array, default: [] },
});

export const MenuModel = models.Menu ?? model('Menu', MenuSchema);

// ─── Ingredient ───────────────────────────────────────────────────────────────

const IngredientSchema = new Schema({
  _id: { type: String, required: true },
  merchantId: { type: String, required: true, index: true },
  name: String,
  quantity: Number,
  unit: String,
  lowStockThreshold: { type: Number, default: 0.5 },
});

export const IngredientModel = models.Ingredient ?? model('Ingredient', IngredientSchema);

// ─── Store Settings ───────────────────────────────────────────────────────────

const StoreSettingsSchema = new Schema({
  _id: { type: String, required: true }, // merchantId
  shopName: { type: String, default: '' },
  acceptCash: { type: Boolean, default: true },
  acceptBankTransfer: { type: Boolean, default: false },
  acceptPromptPay: { type: Boolean, default: false },
  acceptQrCode: { type: Boolean, default: false },
  bankName: { type: String, default: '' },
  bankAccount: { type: String, default: '' },
  accountName: { type: String, default: '' },
  promptPayNumber: { type: String, default: '' },
  qrCodeImageUrl: { type: String, default: null },
  qrCodeImageBase64: { type: String, default: null },
  vatEnabled: { type: Boolean, default: false },
});

export const StoreSettingsModel = models.StoreSettings ?? model('StoreSettings', StoreSettingsSchema);
