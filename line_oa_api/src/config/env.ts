import dotenv from 'dotenv';
dotenv.config();

export const env = {
  port: Number(process.env.PORT) || 3000,
  nodeEnv: process.env.NODE_ENV ?? 'development',
  renderExternalUrl: process.env.RENDER_EXTERNAL_URL ?? '',
  liffUrl: process.env.LIFF_URL ?? '',
  line: {
    channelAccessToken: process.env.LINE_CHANNEL_ACCESS_TOKEN ?? '',
    channelSecret: process.env.LINE_CHANNEL_SECRET ?? '',
  },
  jwtSecret: process.env.JWT_SECRET ?? 'dev-secret',
} as const;
