# 🏬 Walmart Supercenter Data Warehouse

คลังข้อมูลและการวิเคราะห์ธุรกิจสำหรับ Walmart Supercenter โดยใช้สถาปัตยกรรม **Modern Data Stack** (PostgreSQL 16 + dbt Core + Metabase + Docker Compose) ตามมาตรฐานหลักสูตร DSBA8 KMITL

---

## 🧰 Tech Stack & Ports Overview

| บริการ | Container Name | URL / Port | ข้อมูลเข้าใช้งาน (Credentials) |
| :--- | :--- | :--- | :--- |
| **PostgreSQL 16** | `dw_postgres` | `localhost:25432` | User: `dw_user` / Pass: `dw_pass` / DB: `walmart_dw` |
| **pgAdmin 4** | `dw_pgadmin` | [http://localhost:28880](http://localhost:28880) | Email: `dw_user@mail.com` / Pass: `dw_pass` |
| **Metabase (BI)** | `dw_metabase` | [http://localhost:23000](http://localhost:23000) | Setup ครั้งแรกผ่านหน้าเว็บ |
| **dbt Core** | `dw_dbt` | Container CLI / Port `28088` (Docs) | รันผ่านคำสั่ง Docker Exec |

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

*(หมายเหตุ: ไฟล์ `init_db/01_init_raw.sql` จะสร้างตาราง `raw_walmart_sales` และโหลดข้อมูลจาก `raw_data/Walmart.csv` ให้โดยอัตโนมัติเมื่อเริ่ม Container เป็นครั้งแรก)*

---

### 2. รัน dbt Pipeline (Transform & Testing)

#### 2.1 ตรวจสอบการเชื่อมต่อ
```bash
docker exec -it dw_dbt bash -c "cd walmart_dw && dbt debug"
```

#### 2.2 สร้างโมเดลทั้งหมด (Staging -> Dimensions -> Fact -> Metrics)
```bash
docker exec -it dw_dbt bash -c "cd walmart_dw && dbt run"
```

#### 2.3 ตรวจสอบคุณภาพข้อมูล (Data Quality Tests)
ทดสอบ `unique`, `not_null`, และ `relationships` (Foreign Keys) ข้ามตาราง:
```bash
docker exec -it dw_dbt bash -c "cd walmart_dw && dbt test"
```

#### 2.4 สร้างเอกสารคู่มือคลังข้อมูล (dbt Docs)
```bash
docker exec -it dw_dbt bash -c "cd walmart_dw && dbt docs generate"
```

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

1. เข้าเบราว์เซอร์ไปที่: [http://localhost:23000](http://localhost:23000)
2. ทำตามขั้นตอนตั้งค่าเริ่มต้นของ Metabase (สร้างแอดมิน)
3. เลือกเพิ่มฐานข้อมูล (**Add your data**):
   - **Database type:** PostgreSQL
   - **Host:** `postgres`
   - **Port:** `5432`
   - **Database name:** `walmart_dw`
   - **Database username:** `dw_user`
   - **Database password:** `dw_pass`
4. สร้าง Dashboards และ Visualizations ตอบโจทย์ KPIs 3 ด้านได้ทันที!
