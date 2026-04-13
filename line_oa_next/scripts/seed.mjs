/**
 * Seed script — creates the default test user + merchant in MongoDB
 * Run: node scripts/seed.mjs
 * (loads .env.local automatically)
 */

import { readFileSync } from 'fs';
import { createHash } from 'crypto';
import mongoose from 'mongoose';
import bcrypt from 'bcryptjs';

// ─── Load .env.local manually ─────────────────────────────────────────────────
try {
  const env = readFileSync('.env.local', 'utf8');
  for (const line of env.split('\n')) {
    const [k, ...v] = line.split('=');
    if (k && v.length) process.env[k.trim()] = v.join('=').trim();
  }
} catch { /* no .env.local — rely on process.env */ }

const MONGODB_URI = process.env.MONGODB_URI;
if (!MONGODB_URI) { console.error('MONGODB_URI not set'); process.exit(1); }

// ─── Schemas ──────────────────────────────────────────────────────────────────

const User = mongoose.model('User', new mongoose.Schema({
  _id: String, email: String, passwordHash: String, name: String, merchantId: String,
}, { timestamps: true }));

const Merchant = mongoose.model('Merchant', new mongoose.Schema({
  _id: String, ownerId: String, name: String,
  plan: { type: String, default: 'gold' },
  planExpiresAt: Date,
}, { timestamps: true }));

const StoreSettings = mongoose.model('StoreSettings', new mongoose.Schema({
  _id: String, shopName: String,
  acceptCash: Boolean, acceptBankTransfer: Boolean,
  acceptPromptPay: Boolean, acceptQrCode: Boolean,
  bankName: String, bankAccount: String,
  accountName: String, promptPayNumber: String,
  vatEnabled: Boolean,
}));

// ─── Seed data ────────────────────────────────────────────────────────────────

const USER_ID      = 'user-seed-001';
const MERCHANT_ID  = 'merchant-001';
const EMAIL        = 'test01@lineoa.com';
const PASSWORD     = '123456';

async function seed() {
  await mongoose.connect(MONGODB_URI);
  console.log('✅ Connected to MongoDB\n');

  // ── User ──────────────────────────────────────────────────────────────────
  const existing = await User.findOne({ email: EMAIL });
  if (existing) {
    console.log(`ℹ️  User "${EMAIL}" already exists (id: ${existing._id}) — skipping create`);
  } else {
    const passwordHash = await bcrypt.hash(PASSWORD, 10);
    await User.create({ _id: USER_ID, email: EMAIL, passwordHash, name: 'Admin Test', merchantId: MERCHANT_ID });
    console.log(`✅ Created user: ${EMAIL}`);
  }

  // ── Merchant ──────────────────────────────────────────────────────────────
  await Merchant.findOneAndUpdate(
    { _id: MERCHANT_ID },
    { $setOnInsert: { _id: MERCHANT_ID, ownerId: USER_ID, name: 'Hiya Ruya', plan: 'gold', planExpiresAt: new Date('2027-12-31') } },
    { upsert: true }
  );
  console.log(`✅ Upserted merchant: ${MERCHANT_ID} (plan: gold)`);

  // ── StoreSettings ─────────────────────────────────────────────────────────
  await StoreSettings.findOneAndUpdate(
    { _id: MERCHANT_ID },
    { $setOnInsert: {
      _id: MERCHANT_ID, shopName: 'Hiya Ruya',
      acceptCash: true, acceptBankTransfer: true,
      acceptPromptPay: true, acceptQrCode: true,
      bankName: 'Kbank', bankAccount: 'xxxxxxxxxxxxxxxxxxxx',
      accountName: 'Hiya Ruya', promptPayNumber: '0999999999',
      vatEnabled: false,
    }},
    { upsert: true }
  );
  console.log(`✅ Upserted store settings: ${MERCHANT_ID}`);

  console.log('\n─────────────────────────────');
  console.log('Seed complete');
  console.log(`  Email:       ${EMAIL}`);
  console.log(`  Password:    ${PASSWORD}`);
  console.log(`  MerchantId:  ${MERCHANT_ID}`);
  console.log(`  Plan:        gold`);
  console.log('─────────────────────────────');

  await mongoose.disconnect();
}

seed().catch(e => { console.error(e); process.exit(1); });
