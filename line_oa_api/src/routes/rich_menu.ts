import { Router, Request, Response, NextFunction } from 'express';
import multer from 'multer';
import * as richMenuService from '../services/rich_menu.service';
import { env } from '../config/env';

const router = Router();
const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 10 * 1024 * 1024 } });

// GET /rich-menu — list all
router.get('/', async (_req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    console.table({ step: 'rich-menu-list', action: 'start' });
    const menus = await richMenuService.listRichMenus();
    console.table({ step: 'rich-menu-list', count: menus.length });
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

    console.table({
      step: 'deploy-customer',
      shopName,
      hasFile: !!file,
      mimetype: file?.mimetype ?? 'none',
      fileSize: file?.size ?? 0,
      tokenLength: env.line.channelAccessToken.length,
    });

    if (!shopName) {
      res.status(400).json({ code: '400', en: 'shopName required', th: 'ข้อมูลไม่ครบ' });
      return;
    }
    if (!file) {
      res.status(400).json({ code: '400', en: 'image file required', th: 'กรุณาแนบรูปภาพ' });
      return;
    }

    const menuRequest = richMenuService.buildCustomerMenu(shopName);
    console.table({ step: 'deploy-customer', action: 'menu-built', areas: menuRequest.areas?.length ?? 0 });

    const richMenuId = await richMenuService.deployCustomerMenu(shopName, file.buffer);
    console.table({ step: 'deploy-customer', action: 'done', richMenuId });

    res.json({ success: true, data: { richMenuId } });
  } catch (err) {
    console.table({ step: 'deploy-customer', error: String(err) });
    next(err);
  }
});

// POST /rich-menu/deploy/merchant — multipart: shopName + image file
router.post('/deploy/merchant', upload.single('image'), async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const shopName = req.body['shopName'] as string;
    const file = req.file;

    console.table({
      step: 'deploy-merchant',
      shopName,
      hasFile: !!file,
      mimetype: file?.mimetype ?? 'none',
      fileSize: file?.size ?? 0,
      tokenLength: env.line.channelAccessToken.length,
    });

    if (!shopName) {
      res.status(400).json({ code: '400', en: 'shopName required', th: 'ข้อมูลไม่ครบ' });
      return;
    }
    if (!file) {
      res.status(400).json({ code: '400', en: 'image file required', th: 'กรุณาแนบรูปภาพ' });
      return;
    }

    const menuRequest = richMenuService.buildMerchantMenu(shopName);
    console.table({ step: 'deploy-merchant', action: 'menu-built', areas: menuRequest.areas?.length ?? 0 });

    const richMenuId = await richMenuService.deployMerchantMenu(shopName, file.buffer);
    console.table({ step: 'deploy-merchant', action: 'done', richMenuId });

    res.json({ success: true, data: { richMenuId } });
  } catch (err) {
    console.table({ step: 'deploy-merchant', error: String(err) });
    next(err);
  }
});

// DELETE /rich-menu/:id
router.delete('/:id', async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const id = req.params['id'] ?? '';
    console.table({ step: 'rich-menu-delete', richMenuId: id });
    await richMenuService.deleteRichMenu(id);
    console.table({ step: 'rich-menu-delete', action: 'done', richMenuId: id });
    res.json({ success: true });
  } catch (err) {
    console.table({ step: 'rich-menu-delete', error: String(err) });
    next(err);
  }
});

export default router;
