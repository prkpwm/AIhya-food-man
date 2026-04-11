import { Router, Request, Response } from 'express';
import * as orderService from '../services/order.service';

const router = Router();

// GET /payment?orderId=xxx — payment page
router.get('/', (req: Request, res: Response): void => {
  const orderId = req.query['orderId'] as string;
  const order = orderId ? orderService.getOrder(orderId) : null;

  if (!order) {
    res.status(404).send('<h2>ไม่พบออเดอร์</h2>');
    return;
  }

  const itemRows = order.items.map((item) => `
    <tr>
      <td>${item.menuName}</td>
      <td style="text-align:center">×${item.quantity}</td>
      <td style="text-align:right">฿${(item.unitPrice * item.quantity).toFixed(0)}</td>
    </tr>`).join('');

  res.send(`<!DOCTYPE html>
<html lang="th">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>ชำระเงิน</title>
  <style>
    *{box-sizing:border-box;margin:0;padding:0}
    body{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;background:#f5f5f5;padding:20px}
    .card{background:#fff;border-radius:20px;padding:24px;max-width:420px;margin:0 auto;box-shadow:0 4px 20px rgba(0,0,0,.08)}
    .header{text-align:center;margin-bottom:20px}
    .header h1{font-size:22px;font-weight:700}
    .order-id{font-size:13px;color:#999;margin-top:4px}
    table{width:100%;border-collapse:collapse;margin:16px 0}
    td{padding:8px 4px;font-size:14px;border-bottom:1px solid #f0f0f0}
    .total-row{font-weight:700;font-size:16px;color:#FF6B00;border-bottom:none}
    .pay-btn{width:100%;padding:16px;background:#FF6B00;color:#fff;border:none;border-radius:50px;font-size:16px;font-weight:700;cursor:pointer;margin-top:20px}
    .pay-btn:active{opacity:.85}
    .status-badge{display:inline-block;padding:4px 12px;border-radius:50px;font-size:12px;font-weight:600;background:#FFF3E0;color:#FF6B00;margin-top:8px}
    .note{font-size:12px;color:#999;text-align:center;margin-top:12px}
  </style>
</head>
<body>
  <div class="card">
    <div class="header">
      <h1>💳 ชำระเงิน</h1>
      <div class="order-id">ออเดอร์ #${order.id.slice(-6)}</div>
      <div class="status-badge">${order.status === 'pending' ? 'รอชำระเงิน' : order.status}</div>
    </div>
    <table>
      <tbody>
        ${itemRows}
        <tr class="total-row">
          <td colspan="2">ยอดรวม</td>
          <td style="text-align:right">฿${order.totalPrice.toFixed(0)}</td>
        </tr>
      </tbody>
    </table>
    <button class="pay-btn" onclick="handlePay()">ชำระเงิน ฿${order.totalPrice.toFixed(0)}</button>
    <p class="note">* ระบบชำระเงินจริงสามารถเชื่อมต่อ PromptPay / บัตรเครดิต ได้ในภายหลัง</p>
  </div>
  <script>
    function handlePay() {
      alert('✅ ชำระเงินสำเร็จ!\\nขอบคุณที่ใช้บริการ');
    }
  </script>
</body>
</html>`);
});

export default router;
