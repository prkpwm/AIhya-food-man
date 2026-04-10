import { Router, Request, Response } from 'express';
import * as menuService from '../services/menu.service';
import { Ingredient } from '../types';

const router = Router();

// GET /stock
router.get('/', (req: Request, res: Response): void => {
  const merchantId = (req.query['merchantId'] as string) ?? 'merchant-001';
  const ingredients = menuService.getIngredientsByMerchant(merchantId);
  res.json({ success: true, data: ingredients });
});

// POST /stock
router.post('/', (req: Request, res: Response): void => {
  const body = req.body as Omit<Ingredient, 'id'>;
  if (!body.name || !body.merchantId) {
    res.status(400).json({ code: '400', en: 'Missing required fields', th: 'ข้อมูลไม่ครบถ้วน' });
    return;
  }
  const ingredient = menuService.upsertIngredient(body);
  res.status(201).json({ success: true, data: ingredient });
});

// PATCH /stock/:id — update quantity
router.patch('/:id', (req: Request, res: Response): void => {
  const { quantity } = req.body as { quantity: number };
  if (typeof quantity !== 'number') {
    res.status(400).json({ code: '400', en: 'quantity must be a number', th: 'จำนวนต้องเป็นตัวเลข' });
    return;
  }
  const ingredient = menuService.updateStock(req.params['id'] ?? '', quantity);
  if (!ingredient) {
    res.status(404).json({ code: '404', en: 'Ingredient not found', th: 'ไม่พบวัตถุดิบ' });
    return;
  }
  res.json({ success: true, data: ingredient });
});

export default router;
