import { Router, Request, Response } from 'express';
import * as menuService from '../services/menu.service';
import { Menu } from '../types';

const router = Router();

// GET /menus
router.get('/', (req: Request, res: Response): void => {
  const merchantId = (req.query['merchantId'] as string) ?? 'merchant-001';
  const menus = menuService.getMenusByMerchant(merchantId);
  res.json({ success: true, data: menus });
});

// GET /menus/:id
router.get('/:id', (req: Request, res: Response): void => {
  const menu = menuService.getMenu(req.params['id'] ?? '');
  if (!menu) {
    res.status(404).json({ code: '404', en: 'Menu not found', th: 'ไม่พบเมนู' });
    return;
  }
  res.json({ success: true, data: menu });
});

// POST /menus
router.post('/', (req: Request, res: Response): void => {
  const body = req.body as Omit<Menu, 'id'>;
  if (!body.name || !body.merchantId) {
    res.status(400).json({ code: '400', en: 'Missing required fields', th: 'ข้อมูลไม่ครบถ้วน' });
    return;
  }
  const menu = menuService.upsertMenu(body);
  res.status(201).json({ success: true, data: menu });
});

// PUT /menus/:id
router.put('/:id', (req: Request, res: Response): void => {
  const body = req.body as Omit<Menu, 'id'>;
  const menu = menuService.upsertMenu({ ...body, id: req.params['id'] });
  res.json({ success: true, data: menu });
});

// DELETE /menus/:id
router.delete('/:id', (req: Request, res: Response): void => {
  const deleted = menuService.deleteMenu(req.params['id'] ?? '');
  if (!deleted) {
    res.status(404).json({ code: '404', en: 'Menu not found', th: 'ไม่พบเมนู' });
    return;
  }
  res.json({ success: true });
});

export default router;
