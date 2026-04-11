import { seedData } from './data/seed';

let initialized = false;

export function ensureInit(): void {
  if (initialized) return;
  initialized = true;
  seedData();
}
