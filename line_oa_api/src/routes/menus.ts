import { Router, Request, Response, NextFunction } from 'express';
import multer from 'multer';
import * as nodePath from 'node:path';
import * as fs from 'node:fs';
import * as menuService from '../services/menu.service';
import { Menu } from '../types';
import { env } from '../config/env';

const router = Router();

// ensure upload dir exists
const MENU_IMG_DIR = nodePath.join(process.cwd(), 'public', 'images', 'menus');
fs.mkdirSync(MENU_IMG_DIR, { recursive: true });

const storage = multer.diskStorage({
  destination: (_req, _file, cb) => cb(null, MENU_IMG_DIR),
  filename: (_req, file, cb) => {
    const ext = nodePath.extname(file.originalname) || '.jpg';
    cb(null, `menu-${Date.now()}${ext}`);
  },
});
const upload = multer({ storage, limits: { fileSize: 5 * 1024 * 1024 } });

function baseUrl(): string {
  return env.renderExternalUrl || `http://localhost:${env.port}`;
}

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

// POST /menus — supports optional image upload (multipart) or JSON
router.post('/', upload.single('image'), (req: Request, res: Response): void => {
  const body = req.body as Omit<Menu, 'id'>;
  if (!body.name || !body.merchantId) {
    res.status(400).json({ code: '400', en: 'Missing required fields', th: 'ข้อมูลไม่ครบถ้วน' });
    return;
  }

  const imageUrl = req.file
    ? `${baseUrl()}/images/menus/${req.file.filename}`
    : (body.imageUrl ?? null);

  const menu = menuService.upsertMenu({
    ...body,
    price: Number(body.price),
    maxSpiceLevel: Number(body.maxSpiceLevel ?? 3),
    isAvailable: body.isAvailable === true || (body.isAvailable as unknown as string) === 'true',
    ingredientIds: Array.isArray(body.ingredientIds) ? body.ingredientIds : [],
    imageUrl,
  });

  console.table({ step: 'menu-created', id: menu.id, name: menu.name, hasImage: !!imageUrl });
  res.status(201).json({ success: true, data: menu });
});

// PUT /menus/:id — supports optional image upload
router.put('/:id', upload.single('image'), (req: Request, res: Response): void => {
  const body = req.body as Omit<Menu, 'id'>;
  const existing = menuService.getMenu(req.params['id'] ?? '');

  const imageUrl = req.file
    ? `${baseUrl()}/images/menus/${req.file.filename}`
    : (body.imageUrl ?? existing?.imageUrl ?? null);

  const menu = menuService.upsertMenu({
    ...body,
    id: req.params['id'],
    price: Number(body.price),
    maxSpiceLevel: Number(body.maxSpiceLevel ?? 3),
    isAvailable: body.isAvailable === true || (body.isAvailable as unknown as string) === 'true',
    ingredientIds: Array.isArray(body.ingredientIds) ? body.ingredientIds : [],
    imageUrl,
  });

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
