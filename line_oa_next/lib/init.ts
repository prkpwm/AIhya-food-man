import { seedData } from './data/seed';

let seedPromise: Promise<void> | null = null;

export function ensureInit(): void {
  if (!seedPromise) {
    seedPromise = seedData().catch((err) => console.error('[init] seed error:', err));
  }
}
