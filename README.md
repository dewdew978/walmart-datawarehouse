# 🏬 Walmart Supercenter Data Warehouse

คลังข้อมูลและการวิเคราะห์ธุรกิจสำหรับ Walmart Supercenter โดยใช้สถาปัตยกรรม **Modern Data Stack** (PostgreSQL 16 + dbt Core + Metabase + Docker Compose) ตามมาตรฐานหลักสูตร DSBA8 KMITL

---

## 🧰 Tech Stack & Ports Overview

| บริการ | Container Name | URL / Port | ข้อมูลเข้าใช้งาน (Credentials) |
| :--- | :--- | :--- | :--- |
| **PostgreSQL 16** | `wmt_postgres` | `localhost:35432` | User: `dw_user` / Pass: `dw_pass` / DB: `walmart_dw` |
| **pgAdmin 4** | `wmt_pgadmin` | [http://localhost:38880](http://localhost:38880) | Email: `dw_user@mail.com` / Pass: `dw_pass` |
| **Metabase (BI)** | `wmt_metabase` | [http://localhost:33000](http://localhost:33000) | Setup ครั้งแรกผ่านหน้าเว็บ |
| **dbt Core** | `wmt_dbt` | Container CLI / Port `38088` (Docs) | รันผ่านคำสั่ง Docker Exec |

---

## 🚀 วิธีเริ่มต้นใช้งาน (Quick Start)

### 1. รัน Container ทั้งหมด
เปิด Terminal ที่โฟลเดอร์นี้ (`C:\Users\thewh\Downloads\walmart-datawarehouse`) แล้วรันคำสั่ง:

```bash
docker compose up -d
```

ตรวจสอบสถานะให้ทุกคอนเทนเนอร์ขึ้น **Up / Running**:
```bash
docker compose ps
```

*(หมายเหตุ: ไฟล์ `init_db/01_init_raw.sql` จะสร้างตาราง `raw_walmart_sales` และโหลดข้อมูลจาก `raw_data/walmart_sales_v2.csv` ให้โดยอัตโนมัติเมื่อเริ่ม Container เป็นครั้งแรก — ถ้าเคยรันมาก่อนและต้องการโหลดข้อมูลใหม่ ให้ลบ volume ด้วย `docker compose down -v` แล้วค่อย `up -d` อีกครั้ง)*

---

### 2. รัน dbt Pipeline (Transform & Testing)

#### 2.1 ตรวจสอบการเชื่อมต่อ
```bash
docker exec -it wmt_dbt bash -c "cd walmart_dw && dbt debug"
```

#### 2.2 สร้างโมเดลทั้งหมด (Staging -> Dimensions -> Fact -> Metrics)
```bash
docker exec -it wmt_dbt bash -c "cd walmart_dw && dbt run"
```

#### 2.3 ตรวจสอบคุณภาพข้อมูล (Data Quality Tests)
ทดสอบ `unique`, `not_null`, `accepted_values` (ค่าที่ผ่านการทำความสะอาดแล้ว), `relationships` (Foreign Keys) และ `tests/assert_fact_attributes_match_source.sql` (attribute ใน dimension ตรงกับข้อมูลต้นทาง):
```bash
docker exec -it wmt_dbt bash -c "cd walmart_dw && dbt test"
```

#### 2.4 สร้างเอกสารคู่มือคลังข้อมูล (dbt Docs)
```bash
docker exec -it wmt_dbt bash -c "cd walmart_dw && dbt docs generate"
```

---

## 🗂️ ข้อมูลต้นทาง (Source Data)

| ไฟล์ | คำอธิบาย |
| :--- | :--- |
| `raw_data/Walmart.csv` | ข้อมูลต้นฉบับ 5,000 แถว (เก็บไว้อ้างอิง ไม่ได้ใช้ใน pipeline) |
| `raw_data/walmart_sales_v2.csv` | ข้อมูลที่ใช้จริง 50,000 transactions ตลอดปี 2024 สร้างจาก `generate_data.py` |

### ทำไมต้องสร้างข้อมูลใหม่
ข้อมูลต้นฉบับถูกสุ่มแยกทีละคอลัมน์ จึงขัดแย้งกันเองและไม่มีรูปแบบทางธุรกิจให้วิเคราะห์ เช่น
- `product_id` / `store_id` / `customer_id` เดียวกันมีหลายชื่อ หลายเมือง หลายระดับสมาชิก
- `holiday_indicator` ไม่คงที่ภายในวันเดียวกัน (ทั้ง 260 วัน) และ `weekday` ไม่ตรงกับวันที่จริง 85%
- สินค้าอยู่ผิดหมวด (Fridge เป็น Electronics), ราคาไม่ขึ้นกับสินค้า, `stockout_indicator` ไม่สัมพันธ์กับสต็อก, `promotion_applied` ขัดกับ `promotion_type`, forecast กับ actual demand ไม่สัมพันธ์กัน (r ≈ 0)

### ข้อมูลใหม่ (`generate_data.py`)
สคริปต์ใช้ seed คงที่ (รันซ้ำได้ไฟล์เดิมทุกครั้ง) ใช้ Python standard library เท่านั้น และคง 28 คอลัมน์/รูปแบบเดิม:
- **Master data คงที่:** 265 สินค้า (8 ประเภท, หมวดถูกต้อง, ช่วงราคาสมจริง), 20 สาขา (เมืองละ 4), ~8,000 ลูกค้า, 60 supplier
- **ปฏิทิน:** ทั้งปี 2024, ฤดูกาล (พ.ย.–ธ.ค. สูงสุด), วันหยุดสุดสัปดาห์, วันหยุดราชการสหรัฐฯ และ Black Friday
- **ความสัมพันธ์ทางธุรกิจ:** โปรโมชันเพิ่มจำนวนชิ้น, ลูกค้าระดับสูงซื้อบ่อยกว่า, supplier lead time ยาวและวันหยุด (ดีมานด์เกินพยากรณ์) ทำให้ของขาดสต็อกมากขึ้น, สภาพอากาศแย่ลดจำนวนลูกค้า
- **ข้อมูลสกปรกโดยเจตนา (~2% ต่อประเภท)** ให้ชั้น staging ทำความสะอาด: ช่องว่าง/แท็บ, ตัวพิมพ์เล็ก-ใหญ่, รูปแบบ `City, ST` ไม่สม่ำเสมอ, ค่าว่าง (เพศ อายุ ประเภทโปรโมชัน), วันที่แบบ ISO, ราคาแบบ `$1,234.56`, boolean แบบ `Yes/No/1/0`, แถวซ้ำ

```bash
python generate_data.py                    # ค่าเริ่มต้น: 50,000 แถว, dirty 2%
python generate_data.py --dirty-rate 0     # ข้อมูลสะอาด
```

### การทำความสะอาดใน `stg_walmart_sales`
ลบแถวซ้ำด้วย `transaction_id`, ตัดช่องว่าง (macro `clean_text`), ปรับตัวพิมพ์ด้วย `initcap`, จัดรูปแบบ `store_location`, แปลงวันที่ทั้งสองรูปแบบ, ตัด `$` และ `,` ออกจากราคา, แปลง boolean ทุกรูปแบบ (macro `clean_bool`), เติมเพศ/อายุที่หายจากรายการอื่นของลูกค้าคนเดียวกัน (ถ้าเติมไม่ได้: เพศ = `Unknown`, อายุคงเป็น null และ test จะแจ้งเตือน), `promotion_type` ว่าง/`None` → `No Promotion`, คำนวณ `weekday` จากวันที่แทนค่าในไฟล์

---

## 📐 สถาปัตยกรรมแบบจำลองข้อมูล (Star Schema)

- **Grain ของ Fact:** 1 แถว ต่อ 1 รายการขายในใบเสร็จ (`sales_key` เป็น Surrogate Key)
- **Fact Table:** `fct_walmart_sales`
  - Measures: `quantity_sold`, `unit_price`, `total_amount`, `inventory_level`, `reorder_point`, `forecasted_demand`, `actual_demand`
- **Dimension Tables:**
  - `dim_product`: สินค้าและหมวดหมู่
  - `dim_customer`: อายุ เพศ ระดับรายได้ และระดับสมาชิก
  - `dim_store`: รหัสและทำเลที่ตั้งสาขา
  - `dim_supplier`: รหัสและระยะเวลาจัดส่งสินค้าเฉลี่ย
  - `dim_date`: ปฏิทิน วันในสัปดาห์ เดือน ไตรมาส ปี และวันหยุด
- **Metric Layer:**
  - `m01_sales_performance`: ยอดขายรวม, ปริมาณขาย, และ AOV แยกตามสาขาและโปรโมชัน
  - `m02_customer_intelligence`: พฤติกรรมการซื้อและ AOV แยกตามระดับสมาชิก
  - `m03_inventory_risk`: อัตราสินค้าขาดสต็อกและความคลาดเคลื่อนของการพยากรณ์ดีมานด์

---

## 📊 การเชื่อมต่อ Metabase เพื่อสร้าง Dashboard

1. เข้าเบราว์เซอร์ไปที่: [http://localhost:33000](http://localhost:33000)
2. ทำตามขั้นตอนตั้งค่าเริ่มต้นของ Metabase (สร้างแอดมิน)
3. เลือกเพิ่มฐานข้อมูล (**Add your data**):
   - **Database type:** PostgreSQL
   - **Host:** `postgres`
   - **Port:** `5432`
   - **Database name:** `walmart_dw`
   - **Database username:** `dw_user`
   - **Database password:** `dw_pass`
4. สร้าง Dashboards และ Visualizations ตอบโจทย์ KPIs 3 ด้านได้ทันที!
