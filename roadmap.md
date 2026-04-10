# Roadmap: แอปอาหารตามสั่ง (LINE OA Code Generator)

## ภาพรวมระบบ

แอป Flutter ทำหน้าที่ **Generate LIFF/LINE OA Rich Menu & Flex Message Code** สำหรับผู้ประกอบการร้านอาหาร
โดยลูกค้าและเจ้าของร้านใช้งานผ่าน LINE OA แต่แสดงผลต่างกัน
ผู้ประกอบการเป็นคนใช้แอป Flutter เพื่อ config และ generate โค้ด

---

## Phase 1 — Core Foundation (เดือน 1-2)

### 1.1 Auth & Merchant Onboarding
- สมัครสมาชิกผู้ประกอบการ (email/phone)
- เชื่อม LINE OA Channel (Channel ID + Secret)
- ระบบ Subscription tier: Free / Silver / Gold / Platinum
- Free tier: รองรับลูกค้าได้ไม่เกิน 20 คน/วัน

### 1.2 Menu Management (ใน Flutter App)
- เพิ่ม/แก้ไข/ลบเมนูอาหาร
- กำหนดระดับความเผ็ด (spice level)
- ตั้งราคา, รูปภาพ, หมวดหมู่
- รองรับประเภทร้าน: ตามสั่ง / ภัตตาคาร / บุฟเฟ่ต์ (รวมบุฟเฟ่ต์แบบจัดส่ง)
- ผู้ประกอบการเพิ่มเมนูใหม่ได้เองผ่าน LINE OA

### 1.3 Ingredient & Stock System
- จัดการวัตถุดิบ (กุ้ง, หมูสับ, หมูแดง, หมูกรอบ, ผัก, เส้น ฯลฯ)
- เชื่อมเมนูกับวัตถุดิบ
- แสดงสถานะสต๊อก: มี / หมด
- แจ้งเตือนเมื่อสต๊อกต่ำ

---

## Phase 2 — LINE OA Code Generator (เดือน 2-3)

### 2.1 Rich Menu Generator
- สร้าง Rich Menu JSON สำหรับ **ลูกค้า**
  - ดูเมนู, สั่งอาหาร, ดูคิว, เมนูโปรด, ดูสต๊อก
- สร้าง Rich Menu JSON สำหรับ **เจ้าของร้าน**
  - รับออเดอร์, จัดการสต๊อก, ดูรายได้, จัดการเมนู
- ปรับแต่ง Theme/สี/ลาย OA ได้เอง (Merchant Customization)
- Export โค้ดพร้อม deploy ไป LINE OA API

### 2.2 Flex Message Generator
- Flex Message แสดงเมนูอาหาร (รูป, ราคา, ระดับเผ็ด, สถานะสต๊อก)
- Flex Message ยืนยันออเดอร์
- Flex Message สถานะออเดอร์ + เวลารอคิว
- Flex Message สรุปรายได้ประจำวัน/เดือน

### 2.3 LIFF Integration Code
- Generate LIFF URL สำหรับหน้าสั่งอาหารแบบละเอียด
- หน้าเลือกระดับความเผ็ด
- หน้าดูสต๊อกแบบ real-time (เฉพาะลูกค้าที่ใช้ผ่านแอป)
- หน้าสร้างเมนูเองจากวัตถุดิบ

---

## Phase 3 — Order & Queue System (เดือน 3-4)

### 3.1 Order Management
- รับออเดอร์ผ่าน LINE OA → sync มาแอป
- จัดกลุ่มออเดอร์ที่เหมือนกัน (เช่น กระเพราหมูสับ 5 จาน ทำพร้อมกัน)
- สถานะออเดอร์: รอยืนยัน → กำลังทำ → พร้อมส่ง → เสร็จสิ้น
- รองรับออเดอร์บุฟเฟ่ต์แบบจัดส่ง

### 3.2 Queue System
- คำนวณเวลารอโดยประมาณ
- แสดงคิวให้ลูกค้าเห็นผ่าน LINE OA
- แจ้งเตือนเมื่อออเดอร์พร้อม

### 3.3 Custom Menu by Customer
- ลูกค้าสร้างเมนูเองจากวัตถุดิบคงเหลือ
- ระบบตรวจสอบว่าวัตถุดิบพอสั่งไหม
- ตัวอย่าง: กุ้ง + หมูแดง + หมูกรอบ + ผัก + เส้น

---

## Phase 4 — Analytics & Favorites (เดือน 4-5)

### 4.1 สำหรับลูกค้า
- เมนูโปรด (บันทึกและสั่งซ้ำได้เร็ว)
- เมนูแนะนำ (based on order history)
- ดูสต๊อกร้านค้า real-time

### 4.2 สำหรับผู้ประกอบการ
- สรุปรายได้รายวัน/สัปดาห์/เดือน
- เมนูโปรดของลูกค้า (top sellers)
- ยอดการสั่งซื้อแยกตามเมนู
- รายงานสต๊อกที่ใช้ไป

---

## Phase 5 — Subscription & Upgrade System (เดือน 5-6)

### 5.1 Tier Structure (ชำระรายเดือน)

| Tier | ลูกค้า/วัน | ฟีเจอร์ |
|------|-----------|---------|
| Free | 20 คน | เมนูพื้นฐาน, Rich Menu มาตรฐาน |
| Silver | 100 คน | + Custom Theme, Analytics |
| Gold | 500 คน | + Custom Menu by Customer, Queue |
| Platinum | ไม่จำกัด | + บุฟเฟ่ต์, Multi-branch, Priority Support |

### 5.2 Payment Integration
- ชำระผ่าน PromptPay / บัตรเครดิต
- Auto-renew รายเดือน
- Downgrade grace period (โค้ดปัจจุบันยังใช้ได้ต่อจนหมดรอบ)
- แจ้งเตือนก่อนหมดอายุ 7 วัน

### 5.3 OA Theme Customization (Silver+)
- เลือก color scheme
- อัปโหลด logo/banner
- ปรับ layout Rich Menu
- Preview ก่อน deploy

---

## Tech Stack

```
Flutter (Mobile App - Merchant)
├── State Management: Riverpod
├── LINE SDK / LIFF SDK
├── HTTP: Dio
└── Local DB: Hive

Backend
├── Node.js + Express (API)
├── PostgreSQL (orders, stock, users)
├── Redis (queue, real-time stock)
└── LINE Messaging API

LINE OA Side (Generated Code)
├── Rich Menu JSON
├── Flex Message Templates
└── LIFF Pages (Vue/React lightweight)
```

---

## Milestone Summary

```
Month 1-2  → Auth + Menu + Stock + Onboarding
Month 2-3  → LINE OA Code Generator (Rich Menu + Flex)
Month 3-4  → Order + Queue + Custom Menu
Month 4-5  → Analytics + Favorites
Month 5-6  → Subscription + Payment + Theme
```
