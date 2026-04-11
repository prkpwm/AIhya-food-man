export const env = {
  nodeEnv: process.env.NODE_ENV ?? 'development',
  renderExternalUrl: process.env.RENDER_EXTERNAL_URL ?? process.env.NEXT_PUBLIC_BASE_URL ?? '',
  liffUrl: process.env.LIFF_URL ?? '',
  line: {
    channelAccessToken: process.env.LINE_CHANNEL_ACCESS_TOKEN ?? '',
    channelSecret: process.env.LINE_CHANNEL_SECRET ?? '',
  },
  jwtSecret: process.env.JWT_SECRET ?? 'dev-secret',
} as const;
