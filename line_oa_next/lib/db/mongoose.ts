import mongoose from 'mongoose';

const MONGODB_URI = process.env.MONGODB_URI ?? '';

if (!MONGODB_URI) {
  console.warn('[DB] MONGODB_URI not set — running without persistence');
}

// reuse connection across hot-reloads in dev
const globalWithMongoose = global as typeof global & { _mongooseConn?: typeof mongoose };

export async function connectDB(): Promise<void> {
  if (!MONGODB_URI) return;
  if (globalWithMongoose._mongooseConn?.connection.readyState === 1) return;
  try {
    globalWithMongoose._mongooseConn = await mongoose.connect(MONGODB_URI, { bufferCommands: false });
    console.log('[DB] MongoDB connected');
  } catch (err) {
    console.error('[DB] connection error:', err);
  }
}
