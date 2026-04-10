import { Router, Request, Response, NextFunction } from 'express';
import * as orderService from '../services/order.service';
import * as lineService from '../services/line.service';
import { env } from '../config/env';
import { OrderStatus } from '../types';

const router = Router();

// GET /orders — list all orders for merchant
router.get('/', (req: Request, res: Response): void => {
  const merchantId = (req.query['merchantId'] as string) ?? 'merchant-001';
  const orders = orderService.getOrdersByMerchant(merchantId);
  res.json({ success: true, data: orders });
});

// GET /orders/grouped — grouped active orders for kitchen
router.get('/grouped', (req: Request, res: Response): void => {
  const merchantId = (req.query['merchantId'] as string) ?? 'merchant-001';
  const grouped = orderService.getGroupedActiveOrders(merchantId);
  res.json({ success: true, data: grouped });
});

// GET /orders/:id
router.get('/:id', (req: Request, res: Response): void => {
  const order = orderService.getOrder(req.params['id'] ?? '');
  if (!order) {
    res.status(404).json({ code: '404', en: 'Order not found', th: 'ไม่พบออเดอร์' });
    return;
  }
  res.json({ success: true, data: order });
});

// POST /orders — create order
router.post('/', (req: Request, res: Response): void => {
  const { merchantId, customerId, customerName, items, note } = req.body as {
    merchantId: string;
    customerId: string;
    customerName: string;
    items: unknown[];
    note?: string;
  };

  if (!merchantId || !customerId || !customerName || !Array.isArray(items)) {
    res.status(400).json({ code: '400', en: 'Missing required fields', th: 'ข้อมูลไม่ครบถ้วน' });
    return;
  }

  const order = orderService.createOrder(merchantId, customerId, customerName, items as never, note);
  res.status(201).json({ success: true, data: order });
});

// PATCH /orders/:id/status — update order status
router.patch('/:id/status', async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const { status, notifyCustomer, accessToken, userId } = req.body as {
      status: OrderStatus;
      notifyCustomer?: boolean;
      accessToken?: string;
      userId?: string;
    };

    const validStatuses: OrderStatus[] = ['pending', 'confirmed', 'preparing', 'ready', 'completed', 'cancelled'];
    if (!validStatuses.includes(status)) {
      res.status(400).json({ code: '400', en: 'Invalid status', th: 'สถานะไม่ถูกต้อง' });
      return;
    }

    const order = orderService.updateOrderStatus(req.params['id'] ?? '', status);
    if (!order) {
      res.status(404).json({ code: '404', en: 'Order not found', th: 'ไม่พบออเดอร์' });
      return;
    }

    if (notifyCustomer && userId) {
      const token = accessToken ?? env.line.channelAccessToken;
      await lineService.pushOrderStatus(token, userId, order);
    }

    res.json({ success: true, data: order });
  } catch (err) {
    next(err);
  }
});

export default router;
