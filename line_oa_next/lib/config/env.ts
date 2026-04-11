export const env = {
  get nodeEnv() { return process.env.NODE_ENV ?? 'development'; },
  get renderExternalUrl() { return process.env.RENDER_EXTERNAL_URL ?? process.env.NEXT_PUBLIC_BASE_URL ?? ''; },
  get liffUrl() { return process.env.LIFF_URL ?? ''; },
  get line() {
    return {
      channelAccessToken: process.env.LINE_CHANNEL_ACCESS_TOKEN ?? '',
      channelSecret: process.env.LINE_CHANNEL_SECRET ?? '',
    };
  },
  get jwtSecret() { return process.env.JWT_SECRET ?? 'dev-secret'; },
};
