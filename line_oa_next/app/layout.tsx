import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'LINE OA Food Order',
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return children;
}
