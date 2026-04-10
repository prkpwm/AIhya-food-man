import { Router, Request, Response, NextFunction } from 'express';
import * as richMenuService from '../services/rich_menu.service';

const router = Router();

// GET /rich-menu — list all
router.get('/', async (_req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const menus = await richMenuService.listRichMenus();
    res.json({ success: true, data: menus });
  } catch (err) {
    next(err);
  }
});

// POST /rich-menu/deploy/customer — deploy customer menu
router.post('/deploy/customer', async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const { shopName, imageBase64, imageType } = req.body as {
      shopName: string;
      imageBase64: string;
      imageType: 'image/jpeg' | 'image/png';
    };

    if (!shopName || !imageBase64) {
      res.status(400).json({ code: '400', en: 'shopName and imageBase64 required', th: 'ข้อมูลไม่ครบ' });
      return;
    }

    const menuRequest = richMenuService.buildCustomerMenu(shopName);
    const imageBuffer = Buffer.from(imageBase64, 'base64');
    const richMenuId = await richMenuService.createAndSetDefault(menuRequest, imageBuffer, imageType ?? 'image/png');

    res.json({ success: true, data: { richMenuId } });
  } catch (err) {
    next(err);
  }
});

// POST /rich-menu/deploy/merchant — deploy merchant menu
router.post('/deploy/merchant', async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const { shopName, imageBase64, imageType } = req.body as {
      shopName: string;
      imageBase64: string;
      imageType: 'image/jpeg' | 'image/png';
    };

    if (!shopName || !imageBase64) {
      res.status(400).json({ code: '400', en: 'shopName and imageBase64 required', th: 'ข้อมูลไม่ครบ' });
      return;
    }

    const menuRequest = richMenuService.buildMerchantMenu(shopName);
    const imageBuffer = Buffer.from(imageBase64, 'base64');
    const richMenuId = await richMenuService.createAndSetDefault(menuRequest, imageBuffer, imageType ?? 'image/png');

    res.json({ success: true, data: { richMenuId } });
  } catch (err) {
    next(err);
  }
});

// DELETE /rich-menu/:id
router.delete('/:id', async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    await richMenuService.deleteRichMenu(req.params['id'] ?? '');
    res.json({ success: true });
  } catch (err) {
    next(err);
  }
});

export default router;
