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
      {
        source: '/api/:path*',
        headers: [
          { key: 'Access-Control-Allow-Origin', value: '*' },
          { key: 'Access-Control-Allow-Methods', value: 'GET,POST,PUT,PATCH,DELETE,OPTIONS' },
          { key: 'Access-Control-Allow-Headers', value: 'Content-Type,Authorization,X-Requested-With' },
        ],
      },
      {
        source: '/images/:path*',
        headers: [
          { key: 'Access-Control-Allow-Origin', value: '*' },
        ],
      },
    ];
  },
};

export default nextConfig;
