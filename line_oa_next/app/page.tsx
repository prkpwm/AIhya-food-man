export default function Home() {
  return (
    <html lang="th">
      <body style={{ fontFamily: 'sans-serif', padding: 40 }}>
        <h1>LINE OA Food Order API</h1>
        <ul style={{ marginTop: 16, lineHeight: 2 }}>
          <li><a href="/api/health">GET /api/health</a></li>
          <li><a href="/api/logs">GET /api/logs</a></li>
          <li><a href="/api/menus?merchantId=merchant-001">GET /api/menus</a></li>
          <li><a href="/api/orders?merchantId=merchant-001">GET /api/orders</a></li>
          <li><a href="/api/stock?merchantId=merchant-001">GET /api/stock</a></li>
          <li><a href="/order-web">LIFF Order Page</a></li>
        </ul>
      </body>
    </html>
  );
}
