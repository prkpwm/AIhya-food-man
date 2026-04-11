import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  // Allow images from external domains
  images: {
    remotePatterns: [{ protocol: 'https', hostname: '**' }],
  },
  // Disable body parsing for webhook route (we read raw body)
  async headers() {
    return [
      {
        source: '/api/webhook',
        headers: [{ key: 'Cache-Control', value: 'no-store' }],
      },
    ];
  },
};

export default nextConfig;
