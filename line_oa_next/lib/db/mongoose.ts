import mongoose from 'mongoose';

const MONGODB_URI = process.env.MONGODB_URI ?? '';

if (!MONGODB_URI) {
  console.warn('[DB] MONGODB_URI not set — running without persistence');
}

const globalWithMongoose = global as typeof global & { _mongoosePromise?: Promise<typeof mongoose> };

export async function connectDB(): Promise<void> {
  if (!MONGODB_URI) return;
  if (mongoose.connection.readyState >= 1) return;
  if (!globalWithMongoose._mongoosePromise) {
    globalWithMongoose._mongoosePromise = mongoose.connect(MONGODB_URI);
  }
  await globalWithMongoose._mongoosePromise;
}
