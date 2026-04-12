import { v4 as uuidv4 } from 'uuid';
import { Menu, Ingredient } from '../types';
import { connectDB } from '../db/mongoose';
import { MenuModel, IngredientModel } from '../db/models';

// ─── helpers ──────────────────────────────────────────────────────────────────

function docToMenu(doc: Record<string, unknown>): Menu {
  return {
    id: doc._id as string,
    merchantId: doc.merchantId as string,
    name: doc.name as string,
    description: doc.description as string,
    price: doc.price as number,
    imageUrl: (doc.imageUrl as string | null) ?? null,
    category: doc.category as string,
    shopType: doc.shopType as Menu['shopType'],
    maxSpiceLevel: doc.maxSpiceLevel as number,
    ingredientIds: (doc.ingredientIds as string[]) ?? [],
    isAvailable: doc.isAvailable as boolean,
    addons: (doc.addons as Menu['addons']) ?? [],
    portionOptions: (doc.portionOptions as Menu['portionOptions']) ?? [],
  };
}

function docToIngredient(doc: Record<string, unknown>): Ingredient {
  return {
    id: doc._id as string,
    merchantId: doc.merchantId as string,
    name: doc.name as string,
    quantity: doc.quantity as number,
    unit: doc.unit as string,
    lowStockThreshold: doc.lowStockThreshold as number,
  };
}

// ─── Menu CRUD ────────────────────────────────────────────────────────────────

export async function getMenusByMerchant(merchantId: string): Promise<Menu[]> {
  await connectDB();
  const docs = await MenuModel.find({ merchantId }).lean();
  return docs.map((d) => docToMenu(d as Record<string, unknown>));
}

export async function getMenu(id: string): Promise<Menu | null> {
  await connectDB();
  const doc = await MenuModel.findById(id).lean();
  return doc ? docToMenu(doc as Record<string, unknown>) : null;
}

export async function upsertMenu(data: Omit<Menu, 'id'> & { id?: string }): Promise<Menu> {
  await connectDB();
  const id = data.id ?? uuidv4();
  const doc = await MenuModel.findByIdAndUpdate(
    id,
    { ...data, _id: id },
    { upsert: true, new: true },
  ).lean();
  return docToMenu(doc as Record<string, unknown>);
}

export async function deleteMenu(id: string): Promise<boolean> {
  await connectDB();
  const res = await MenuModel.findByIdAndDelete(id);
  return res !== null;
}

// ─── Ingredient CRUD ──────────────────────────────────────────────────────────

export async function getIngredientsByMerchant(merchantId: string): Promise<Ingredient[]> {
  await connectDB();
  const docs = await IngredientModel.find({ merchantId }).lean();
  return docs.map((d) => docToIngredient(d as Record<string, unknown>));
}

export async function upsertIngredient(data: Omit<Ingredient, 'id'> & { id?: string }): Promise<Ingredient> {
  await connectDB();
  const id = data.id ?? uuidv4();
  const doc = await IngredientModel.findByIdAndUpdate(
    id,
    { ...data, _id: id },
    { upsert: true, new: true },
  ).lean();
  return docToIngredient(doc as Record<string, unknown>);
}

export async function updateStock(id: string, quantity: number): Promise<Ingredient | null> {
  await connectDB();
  const doc = await IngredientModel.findByIdAndUpdate(id, { quantity }, { new: true }).lean();
  return doc ? docToIngredient(doc as Record<string, unknown>) : null;
}

export async function countMenus(merchantId: string): Promise<number> {
  await connectDB();
  return MenuModel.countDocuments({ merchantId });
}

export async function countIngredients(merchantId: string): Promise<number> {
  await connectDB();
  return IngredientModel.countDocuments({ merchantId });
}
