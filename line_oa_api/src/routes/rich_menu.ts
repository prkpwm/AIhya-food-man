import { Router, Request, Response, NextFunction } from 'express';
import multer from 'multer';
import * as richMenuService from '../services/rich_menu.service';

const router = Router();
const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 10 * 1024 * 1024 } });

// GET /rich-menu — list all
router.get('/', async (_req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const menus = await richMenuService.listRichMenus();
    res.json({ success: true, data: menus });
  } catch (err) {
    next(err);
  }
});

// POST /rich-menu/deploy/customer — multipart: shopName + image file
router.post('/deploy/customer', upload.single('image'), async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const shopName = req.body['shopName'] as string;
    const file = req.file;

    if (!shopName) {
      res.status(400).json({ code: '400', en: 'shopName required', th: 'ข้อมูลไม่ครบ' });
      return;
    }
    if (!file) {
      res.status(400).json({ code: '400', en: 'image file required', th: 'กรุณาแนบรูปภาพ' });
      return;
    }

    const large = req.body['large'] === 'true';
    const richMenuId = await richMenuService.deployCustomerMenu(shopName, file.buffer, large);
    res.json({ success: true, data: { richMenuId } });
  } catch (err) {
    next(err);
  }
});

// POST /rich-menu/deploy/merchant — multipart: shopName + image file
router.post('/deploy/merchant', upload.single('image'), async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const shopName = req.body['shopName'] as string;
    const file = req.file;

    if (!shopName) {
      res.status(400).json({ code: '400', en: 'shopName required', th: 'ข้อมูลไม่ครบ' });
      return;
    }
    if (!file) {
      res.status(400).json({ code: '400', en: 'image file required', th: 'กรุณาแนบรูปภาพ' });
      return;
    }

    const large = req.body['large'] === 'true';
    const richMenuId = await richMenuService.deployMerchantMenu(shopName, file.buffer, large);
    res.json({ success: true, data: { richMenuId } });
  } catch (err) {
    next(err);
  }
});

// DELETE /rich-menu/:id
router.delete('/:id', async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const id = req.params['id'] ?? '';
    await richMenuService.deleteRichMenu(id);
    res.json({ success: true });
  } catch (err) {
    next(err);
  }
});

export default router;
