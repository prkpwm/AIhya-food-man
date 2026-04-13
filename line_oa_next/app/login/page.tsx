'use client';
import { useState } from 'react';
import { useRouter } from 'next/navigation';

type Mode = 'login' | 'register';

export default function LoginPage() {
  const router = useRouter();
  const [mode, setMode] = useState<Mode>('login');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [name, setName] = useState('');
  const [shopName, setShopName] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      const body = mode === 'login'
        ? { email, password }
        : { email, password, name, shopName };
      const res = await fetch(`/api/auth/${mode}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
      });
      const data = await res.json();
      if (!res.ok) { setError(data.th || data.en || 'เกิดข้อผิดพลาด'); return; }
      localStorage.setItem('token', data.token);
      localStorage.setItem('merchantId', data.merchantId);
      localStorage.setItem('userName', data.name);
      router.push('/dashboard');
    } catch {
      setError('เกิดข้อผิดพลาด กรุณาลองใหม่');
    } finally {
      setLoading(false);
    }
  }

  return (
    <div style={styles.bg}>
      <div style={styles.card}>
        <div style={styles.logo}>🍽️</div>
        <h1 style={styles.title}>Aihya Food</h1>
        <p style={styles.sub}>{mode === 'login' ? 'เข้าสู่ระบบ' : 'สมัครสมาชิก'}</p>

        <div style={styles.tabs}>
          <button style={{ ...styles.tab, ...(mode === 'login' ? styles.tabActive : {}) }} onClick={() => { setMode('login'); setError(''); }}>เข้าสู่ระบบ</button>
          <button style={{ ...styles.tab, ...(mode === 'register' ? styles.tabActive : {}) }} onClick={() => { setMode('register'); setError(''); }}>สมัครสมาชิก</button>
        </div>

        <form onSubmit={submit} style={styles.form}>
          {mode === 'register' && (
            <>
              <input style={styles.input} placeholder="ชื่อของคุณ" value={name} onChange={e => setName(e.target.value)} required />
              <input style={styles.input} placeholder="ชื่อร้านอาหาร" value={shopName} onChange={e => setShopName(e.target.value)} required />
            </>
          )}
          <input style={styles.input} type="email" placeholder="อีเมล" value={email} onChange={e => setEmail(e.target.value)} required />
          <input style={styles.input} type="password" placeholder="รหัสผ่าน" value={password} onChange={e => setPassword(e.target.value)} required />
          {error && <p style={styles.error}>{error}</p>}
          <button style={{ ...styles.btn, opacity: loading ? 0.7 : 1 }} type="submit" disabled={loading}>
            {loading ? 'กำลังดำเนินการ...' : mode === 'login' ? 'เข้าสู่ระบบ' : 'สมัครสมาชิก'}
          </button>
        </form>
      </div>
    </div>
  );
}

const styles: Record<string, React.CSSProperties> = {
  bg: { minHeight: '100vh', background: '#f1f3f4', display: 'flex', alignItems: 'center', justifyContent: 'center', padding: 16, fontFamily: '-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif' },
  card: { background: '#fff', borderRadius: 20, padding: '36px 28px', width: '100%', maxWidth: 400, boxShadow: '0 4px 24px rgba(0,0,0,.1)' },
  logo: { fontSize: 48, textAlign: 'center' },
  title: { fontSize: 24, fontWeight: 700, textAlign: 'center', margin: '8px 0 4px', color: '#202124' },
  sub: { textAlign: 'center', color: '#5f6368', fontSize: 14, marginBottom: 24 },
  tabs: { display: 'flex', background: '#f1f3f4', borderRadius: 12, padding: 4, marginBottom: 24, gap: 4 },
  tab: { flex: 1, padding: '10px 0', border: 'none', background: 'transparent', borderRadius: 10, fontSize: 14, fontWeight: 500, color: '#5f6368', cursor: 'pointer', transition: 'all .2s' },
  tabActive: { background: '#fff', color: '#1a73e8', boxShadow: '0 1px 4px rgba(0,0,0,.12)', fontWeight: 600 },
  form: { display: 'flex', flexDirection: 'column', gap: 12 },
  input: { padding: '13px 14px', border: '1.5px solid #e8eaed', borderRadius: 12, fontSize: 15, outline: 'none', transition: 'border .2s' },
  btn: { padding: '14px', background: '#1a73e8', color: '#fff', border: 'none', borderRadius: 12, fontSize: 16, fontWeight: 600, cursor: 'pointer', marginTop: 4, boxShadow: '0 2px 8px rgba(26,115,232,.3)' },
  error: { color: '#ea4335', fontSize: 13, textAlign: 'center', margin: 0 },
};
