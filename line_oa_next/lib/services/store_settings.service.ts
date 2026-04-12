import { connectDB } from '../db/mongoose';
import { StoreSettingsModel } from '../db/models';

export interface StoreSettings {
  merchantId: string;
  shopName: string;
  acceptCash: boolean;
  acceptBankTransfer: boolean;
  acceptPromptPay: boolean;
  acceptQrCode: boolean;
  bankName: string;
  bankAccount: string;
  accountName: string;
  promptPayNumber: string;
  qrCodeImageUrl: string | null;
  qrCodeImageBase64: string | null;
  vatEnabled: boolean;
}

function docToSettings(doc: Record<string, unknown>): StoreSettings {
  return {
    merchantId: doc._id as string,
    shopName: (doc.shopName as string) ?? '',
    acceptCash: (doc.acceptCash as boolean) ?? true,
    acceptBankTransfer: (doc.acceptBankTransfer as boolean) ?? false,
    acceptPromptPay: (doc.acceptPromptPay as boolean) ?? false,
    acceptQrCode: (doc.acceptQrCode as boolean) ?? false,
    bankName: (doc.bankName as string) ?? '',
    bankAccount: (doc.bankAccount as string) ?? '',
    accountName: (doc.accountName as string) ?? '',
    promptPayNumber: (doc.promptPayNumber as string) ?? '',
    qrCodeImageUrl: (doc.qrCodeImageUrl as string | null) ?? null,
    qrCodeImageBase64: (doc.qrCodeImageBase64 as string | null) ?? null,
    vatEnabled: (doc.vatEnabled as boolean) ?? false,
  };
}

export async function getStoreSettings(merchantId: string): Promise<StoreSettings> {
  await connectDB();
  const doc = await StoreSettingsModel.findById(merchantId).lean();
  if (!doc) {
    return { merchantId, shopName: '', acceptCash: true, acceptBankTransfer: false, acceptPromptPay: false, acceptQrCode: false, bankName: '', bankAccount: '', accountName: '', promptPayNumber: '', qrCodeImageUrl: null, qrCodeImageBase64: null, vatEnabled: false };
  }
  return docToSettings(doc as Record<string, unknown>);
}

export async function upsertStoreSettings(data: Partial<StoreSettings> & { merchantId: string }): Promise<StoreSettings> {
  await connectDB();
  const doc = await StoreSettingsModel.findByIdAndUpdate(
    data.merchantId,
    { ...data, _id: data.merchantId },
    { upsert: true, returnDocument: 'after' },
  ).lean();
  return docToSettings(doc as Record<string, unknown>);
}
