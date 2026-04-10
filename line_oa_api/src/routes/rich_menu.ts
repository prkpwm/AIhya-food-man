import { Router, Request, Response, NextFunction } from 'express';
import * as richMenuService from '../services/rich_menu.service';
import { env } from '../config/env';

const router = Router();

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

// POST /rich-menu/deploy/customer — deploy customer menu
router.post('/deploy/customer', async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const { shopName, imageBase64, imageType } = req.body as {
      shopName: string;
      imageBase64: string;
      imageType: 'image/jpeg' | 'image/png';
    };

    console.table({
      step: 'deploy-customer',
      shopName,
      hasImage: !!imageBase64,
      imageType: imageType ?? 'none',
      imageBase64Length: imageBase64?.length ?? 0,
      tokenLength: env.line.channelAccessToken.length,
    });

    if (!shopName) {
      console.table({ step: 'deploy-customer', error: 'missing shopName' });
      res.status(400).json({ code: '400', en: 'shopName required', th: 'ข้อมูลไม่ครบ' });
      return;
    }

    const menuRequest = richMenuService.buildCustomerMenu(shopName);
    console.table({ step: 'deploy-customer', action: 'menu-built', areas: menuRequest.areas?.length ?? 0 });

    if (!imageBase64) {
      console.table({ step: 'deploy-customer', action: 'create-without-image' });
      const { messagingApi } = await import('@line/bot-sdk');
      const client = new messagingApi.MessagingApiClient({ channelAccessToken: env.line.channelAccessToken });
      const { richMenuId } = await client.createRichMenu(menuRequest);
      console.table({ step: 'deploy-customer', action: 'created', richMenuId });
      await client.setDefaultRichMenu(richMenuId);
      console.table({ step: 'deploy-customer', action: 'set-default', richMenuId });
      res.json({ success: true, data: { richMenuId } });
      return;
    }

    const imageBuffer = Buffer.from(imageBase64, 'base64');
    const type = imageType ?? 'image/png';
    console.table({ step: 'deploy-customer', action: 'uploading-image', type, bufferSize: imageBuffer.length });

    const richMenuId = await richMenuService.createAndSetDefault(menuRequest, imageBuffer, type);
    console.table({ step: 'deploy-customer', action: 'done', richMenuId });

    res.json({ success: true, data: { richMenuId } });
  } catch (err) {
    console.table({ step: 'deploy-customer', error: String(err) });
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

    console.table({
      step: 'deploy-merchant',
      shopName,
      hasImage: !!imageBase64,
      imageType: imageType ?? 'none',
      imageBase64Length: imageBase64?.length ?? 0,
      tokenLength: env.line.channelAccessToken.length,
    });

    if (!shopName) {
      console.table({ step: 'deploy-merchant', error: 'missing shopName' });
      res.status(400).json({ code: '400', en: 'shopName required', th: 'ข้อมูลไม่ครบ' });
      return;
    }

    const menuRequest = richMenuService.buildMerchantMenu(shopName);
    console.table({ step: 'deploy-merchant', action: 'menu-built', areas: menuRequest.areas?.length ?? 0 });

    if (!imageBase64) {
      console.table({ step: 'deploy-merchant', action: 'create-without-image' });
      const { messagingApi } = await import('@line/bot-sdk');
      const client = new messagingApi.MessagingApiClient({ channelAccessToken: env.line.channelAccessToken });
      const { richMenuId } = await client.createRichMenu(menuRequest);
      console.table({ step: 'deploy-merchant', action: 'created', richMenuId });
      await client.setDefaultRichMenu(richMenuId);
      console.table({ step: 'deploy-merchant', action: 'set-default', richMenuId });
      res.json({ success: true, data: { richMenuId } });
      return;
    }

    const imageBuffer = Buffer.from(imageBase64, 'base64');
    const type = imageType ?? 'image/png';
    console.table({ step: 'deploy-merchant', action: 'uploading-image', type, bufferSize: imageBuffer.length });

    const richMenuId = await richMenuService.createAndSetDefault(menuRequest, imageBuffer, type);
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
