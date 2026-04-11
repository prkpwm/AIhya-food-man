import { v4 as uuidv4 } from 'uuid';
import { Menu, Ingredient } from '../types';

const menus: Map<string, Menu> = new Map();
const ingredients: Map<string, Ingredient> = new Map();

export function getMenusByMerchant(merchantId: string): Menu[] {
  return [...menus.values()].filter((m) => m.merchantId === merchantId);
}
export function getMenu(id: string): Menu | null { return menus.get(id) ?? null; }
export function upsertMenu(data: Omit<Menu, 'id'> & { id?: string }): Menu {
  const menu: Menu = { ...data, id: data.id ?? uuidv4() };
  menus.set(menu.id, menu);
  return menu;
}
export function deleteMenu(id: string): boolean { return menus.delete(id); }

export function getIngredientsByMerchant(merchantId: string): Ingredient[] {
  return [...ingredients.values()].filter((i) => i.merchantId === merchantId);
}
export function upsertIngredient(data: Omit<Ingredient, 'id'> & { id?: string }): Ingredient {
  const ingredient: Ingredient = { ...data, id: data.id ?? uuidv4() };
  ingredients.set(ingredient.id, ingredient);
  return ingredient;
}
export function updateStock(id: string, quantity: number): Ingredient | null {
  const ingredient = ingredients.get(id);
  if (!ingredient) return null;
  const updated = { ...ingredient, quantity };
  ingredients.set(id, updated);
  return updated;
}
