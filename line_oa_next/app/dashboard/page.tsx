'use client';
import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';

interface UserInfo { name: string; email: string; merchantId: string | null; }

export default function DashboardPage() {
  const router = useRouter();
  const [user, setUser] = useState<UserInfo | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const token = localStorage.getItem('token');
    if (!token) { router.replace('/login'); return; }
    fetch('/api/auth/me', { headers: { Authorization: `Bearer ${token}` } })
      .then(r => r.json())
      .then(d => {
        if (!d.success) { router.replace('/login'); return; }
        setUser(d.user);
      })
      .catch(() => router.replace('/login'))
      .finally(() => setLoading(false));
  }, [router]);

  async function logout() {
    await fetch('/api/auth/logout', { method: 'POST' });
    localStorage.clear();
    router.replace('/login');
  }

  if (loading) return <div style={styles.center}>กำลังโหลด...</div>;
  if (!user) return null;

  const merchantId = user.merchantId ?? '';
  const links = [
    { href: `/api/menus?merchantId=${merchantId}`, label: '🍜 เมนู' },
    { href: `/api/orders?merchantId=${merchantId}`, label: '📦 ออเดอร์' },
    { href: `/api/stock?merchantId=${merchantId}`, label: '📦 สต็อก' },
    { href: `/api/settings?merchantId=${merchantId}`, label: '⚙️ ตั้งค่าร้าน' },
  ];

  return (
    <div style={styles.bg}>
      <div style={styles.header}>
        <div>
          <div style={styles.greeting}>สวัสดี, {user.name} 👋</div>
          <div style={styles.email}>{user.email}</div>
        </div>
        <button style={styles.logoutBtn} onClick={logout}>ออกจากระบบ</button>
      </div>

      <div style={styles.body}>
        <div style={styles.merchantCard}>
          <div style={styles.merchantLabel}>Merchant ID</div>
          <div style={styles.merchantId}>{merchantId || '—'}</div>
        </div>

        <div style={styles.sectionTitle}>เมนูด่วน</div>
        <div style={styles.grid}>
          {links.map(l => (
            <a key={l.href} href={l.href} style={styles.linkCard} target="_blank" rel="noreferrer">
              <span style={styles.linkIcon}>{l.label.split(' ')[0]}</span>
              <span style={styles.linkLabel}>{l.label.split(' ').slice(1).join(' ')}</span>
            </a>
          ))}
        </div>

        <div style={styles.sectionTitle}>LIFF</div>
        <a href="/order-web" style={{ ...styles.linkCard, display: 'flex' }} target="_blank" rel="noreferrer">
          <span style={styles.linkIcon}>🛒</span>
          <span style={styles.linkLabel}>หน้าสั่งอาหาร</span>
        </a>
      </div>
    </div>
  );
}

const styles: Record<string, React.CSSProperties> = {
  bg: { minHeight: '100vh', background: '#f1f3f4', fontFamily: '-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif' },
  center: { display: 'flex', alignItems: 'center', justifyContent: 'center', minHeight: '100vh', color: '#5f6368' },
  header: { background: '#fff', padding: '16px 20px', display: 'flex', justifyContent: 'space-between', alignItems: 'center', boxShadow: '0 1px 3px rgba(0,0,0,.1)', position: 'sticky', top: 0, zIndex: 10 },
  greeting: { fontSize: 17, fontWeight: 600, color: '#202124' },
  email: { fontSize: 13, color: '#5f6368', marginTop: 2 },
  logoutBtn: { padding: '8px 16px', background: '#fce8e6', color: '#ea4335', border: 'none', borderRadius: 50, fontSize: 13, fontWeight: 600, cursor: 'pointer' },
  body: { padding: 20, maxWidth: 600, margin: '0 auto' },
  merchantCard: { background: '#fff', borderRadius: 16, padding: '16px 20px', marginBottom: 24, boxShadow: '0 1px 4px rgba(0,0,0,.08)' },
  merchantLabel: { fontSize: 12, color: '#5f6368', fontWeight: 600, letterSpacing: '.5px', textTransform: 'uppercase', marginBottom: 6 },
  merchantId: { fontSize: 14, fontWeight: 600, color: '#202124', wordBreak: 'break-all', fontFamily: 'monospace' },
  sectionTitle: { fontSize: 12, fontWeight: 600, color: '#5f6368', letterSpacing: '.5px', textTransform: 'uppercase', marginBottom: 10 },
  grid: { display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12, marginBottom: 24 },
  linkCard: { background: '#fff', borderRadius: 16, padding: '18px 16px', boxShadow: '0 1px 4px rgba(0,0,0,.08)', textDecoration: 'none', display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 8, color: '#202124', transition: 'box-shadow .2s' },
  linkIcon: { fontSize: 28 },
  linkLabel: { fontSize: 13, fontWeight: 600, color: '#5f6368' },
};
