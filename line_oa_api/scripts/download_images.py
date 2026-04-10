"""
Download all menu images from mock_data.dart and save to public/images/
Usage: python scripts/download_images.py
"""

import os
import urllib.request
import urllib.error

OUTPUT_DIR = os.path.join(os.path.dirname(__file__), '..', 'public', 'images')

IMAGES = [
    ('menu-001', 'กระเพราหมูสับ',    'https://images.openai.com/static-rsc-4/b4C5IE7Tpv_Ep7wnqXD7HypX6DpTnb3pEI1EBW9KQgV_kR-gKYq7y8gzTU3pwsIpVi127pZ2XEtfkLNaWTk4_0AXBcPjUCLeyc99iGMV8zvD-QINZjo1uOAdsubyYvYzI4aVsfp92u9k99GAl07KHHbLbEHuS0mY8rp1lpIc7c9mvCXF51G01BWaOlM1AEI8?purpose=inline'),
    ('menu-002', 'กระเพราไก่',        'https://images.openai.com/static-rsc-4/RxTk3sZohYoPdvwvzm_D-s9T6AhC18rTzgsPmwkkaxwezuGcxQv6EtVdqLy_kl1ElksSe2WxVaJkmwx2A5k7RFa9qOa5Ur2UNnQRuuz5wYl-M3N66mKPdMukEDpK7fuSzA7zRmQALtOYyfYT4P6OzJSoIOMxBdxZzZeAOTb5HQq5uZJLud7g0zExkKDLog7O?purpose=inline'),
    ('menu-003', 'กระเพรากุ้ง',       'https://images.openai.com/static-rsc-4/LWhFKf3jUTsmen3Y9wpEb-qgfdPZzHBhEwQpxB5FjuzstkfaYb9IGG_y2XzcfQZTh7CQMP97UCS3X27hA8eTL-HwQ9X9C0fsL7jnNJONeqizZrPmN5kBLwATbRuxtudGBmmetS2aSbX6rnP2vbPHJNzZvqbNsO5EOfuU70S1aWyfMPuNv7lkhjXrQbwt0bbU?purpose=inline'),
    ('menu-004', 'ผัดไทยกุ้งสด',      'https://images.openai.com/static-rsc-4/FUkiLfBDDtxHS4tYfHPreB7nPLNTpLodRCckLkmidP1lx2unoADESUCPId6vIUbrg1XjaJF0J7rhFk7OdSB_3FVBmZfCA4-tGMLzvld8P9aSDqZQfdtuCqHuWqtmhXmCnlLw_RofFUZuW4vbWV9sSaQ7YhrIC_hRiv_lyvb64Gc?purpose=inline'),
    ('menu-005', 'ต้มยำกุ้ง',          'https://images.openai.com/static-rsc-4/PF5Nbp9Ni2IiuYHTmLlbDTf0miX8siMpOvQQBadsAKth_P77ojAKwrRD6JIPfk4cnswFVGwesePXRXiLvUz2Dk53LQVcOWhUoaDQpbRla78F5of2CUfWD73wGLaFlQ0H6se-axcfa6THGpNdxNk-MlMLBm5snC1cC0sVjfd2S2TFuj8XG5aNMqqn7_CROOpb?purpose=inline'),
    ('menu-006', 'แกงเขียวหวานไก่',   'https://images.openai.com/static-rsc-4/JyI_93GqEApry9v94R7CueY17nAqb4FkNukQGEOYVFzeViedR9eaHoaF8xVVptMx7ycLeyflPOnDlIUyiOUEfQ0ull-j6YN5T4QuK_Rl_fOkw9jAMtfIQv_TXWVGsEB74KykMW538iL4xlfKtch8UHLLwUeIVXeUA34wRvn3foXjqJrYYeEzsX4lDV1tpYCF?purpose=inline'),
    ('menu-007', 'ส้มตำไทย',           'https://images.openai.com/static-rsc-4/KqeYr35dnhchqj5qn0S0XU34nSKpTGxNzLq4lPUq6trtWgvpQ6SE-HS1T9wckfcsc7FBCuZc9h6WfH2w-JhYj6s1y_9LHYdVK22jUwSbZT6feHQd-NdWt0tB7jgQQcjBJUMGpqtI-uyKD-Sld0evnvhqTANCqVtEXWelj-VdfBh8witDwWCJ0oTxrI44Zqut?purpose=inline'),
    ('menu-008', 'ราดหน้าหมูแดงหมูกรอบ', 'https://images.openai.com/static-rsc-4/0IZ_Q3EF8dYCAnopyXhYX3WToBicRNcm4A8aN2QeWcT8UdzjnPYnzj6RvIQk080-mq-XoNVRRsexLdBubm7lzMoKgTihv0a3CE-uPQ_RAkGlZVceVJ9XelM6iZMxk7P3Y0G_QkJGFeAjqcs8sa9nwe2kkB8UUYRTbYwumLzMcTGYyElqwF2bK6s-sS1AvLZy?purpose=inline'),
    ('menu-009', 'หมูปิ้ง',            'https://images.openai.com/static-rsc-4/z8sff6Eqv6isDIfsYkYrjSJvwDag8Y8xnP5odNqw5KY-PHlNEO5Nizfm-SkVt_9Qg9LmFV0ijRYjpqRitBXFOxsscLTNCYzMbupfnGQGhK4t-IzyxH4CoxoYy2nXLs_capF--eP-lQvD-5TmXBSnufHzAak_vQ7SO42oIENz5wM_GPeoz4ZO76PpaOIZV1os?purpose=inline'),
    ('menu-010', 'ข้าวเหนียวมะม่วง',  'https://images.openai.com/static-rsc-4/Zf7x6pSro7xPHxl4oFzXW9PFy6TLoQnALv8mMkKDp8PuOT2A4lO9SwNS9-nY8pf6-QVRdWSHrMqvGA7gMXM2zz1BcnSfR3TNisEJOKuVXlidaEHVttA0U4DooSyqDuPrbWqD6yr7QFW7OCnOxJsc-fpkSeKCcv8c0sw8an8watYwoUVY7pU_3dxbkn-nwSxu?purpose=inline'),
]


def download():
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    for menu_id, name, url in IMAGES:
        dest = os.path.join(OUTPUT_DIR, f'{menu_id}.jpg')

        if os.path.exists(dest):
            print(f'[skip]  {menu_id} ({name}) already exists')
            continue

        try:
            req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
            with urllib.request.urlopen(req, timeout=30) as resp:
                data = resp.read()
            with open(dest, 'wb') as f:
                f.write(data)
            print(f'[ok]    {menu_id} ({name}) — {len(data) // 1024} KB')
        except urllib.error.URLError as e:
            print(f'[error] {menu_id} ({name}) — {e}')


if __name__ == '__main__':
    download()
    print(f'\nDone — saved to {os.path.abspath(OUTPUT_DIR)}')
