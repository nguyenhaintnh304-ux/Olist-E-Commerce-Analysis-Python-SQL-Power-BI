# 🛒 Olist E-Commerce Analysis — Python | SQL | Power BI

## Bối cảnh 

Olist là sàn thương mại điện tử kết nối các nhà bán hàng nhỏ lẻ tại Brazil với nhiều kênh bán hàng khác nhau. Dữ liệu giai đoạn 2016–2018 ghi nhận mức tăng trưởng doanh thu đều đặn qua các tháng, tuy nhiên con số này chưa phản ánh được tính bền vững của mô hình kinh doanh.

**Câu hỏi đặt ra:** Olist đang tăng trưởng, nhưng có đang giữ được khách hàng quay lại không? Nếu không, điều gì trong trải nghiệm khách hàng (giao hàng, chất lượng sản phẩm) có thể là nguyên nhân?

Dự án này đi tìm câu trả lời bằng cách chia thành 3 lớp phân tích: tình hình chung → hành vi khách hàng → các yếu tố vận hành có thể đang cản trở retention. Toàn bộ quy trình mô phỏng công việc thực tế của Data Analyst: làm sạch dữ liệu thô, phân tích bằng SQL, trực quan hóa trên dashboard.


---

## 📌 Mục lục
- [Tổng quan dự án](#tổng-quan-dự-án)
- [Nguồn dữ liệu](#nguồn-dữ-liệu)
- [Kiến trúc & Quy trình](#kiến-trúc--quy-trình)
- [Data Cleaning — Các quyết định quan trọng](#data-cleaning--các-quyết-định-quan-trọng)
- [Phân tích SQL](#phân-tích-sql)
- [Dashboard Power BI](#dashboard-power-bi)
- [Insight chính](#insight-chính)
- [Cấu trúc thư mục](#cấu-trúc-thư-mục)
- [Công cụ sử dụng](#công-cụ-sử-dụng)

---

## Tổng quan dự án

Dự án sử dụng bộ dữ liệu công khai **Brazilian E-Commerce Public Dataset** (~100.000 đơn hàng, 2016–2018), tiếp cận theo hướng trả lời câu hỏi retention đặt ra ở trên, chia thành 3 lớp điều tra:

| Phần | Vai trò trong việc trả lời câu hỏi chính |
|---|---|
| **1. Business Overview** | Thiết lập bối cảnh kinh doanh: theo dõi doanh thu, sản lượng đơn, AOV... nhằm xác định động lực tăng trưởng cốt lõi. |
| **2. Who are our best customers?** | Đo lường trực tiếp mức độ giữ chân khách hàng: Tỷ lệ khách hàng quay lại và phân khúc khách hàng giá trị cao. |
| **3. What's holding us back?** | Tìm nguyên nhân tiềm năng phía vận hành: thời gian giao hàng theo khu vực, điểm đánh giá theo danh mục sản phẩm — những yếu tố có thể ảnh hưởng đến việc khách có quay lại hay không |

**Luồng xử lý dữ liệu:**

```
Raw CSV (Kaggle) → Python (EDA + Cleaning) → SQL Server (Modeling + Views) → Power BI (Dashboard)
```

---

## Nguồn dữ liệu

- **Dataset:** [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) (Kaggle)
- **Quy mô:** ~100.000 đơn hàng, 9 bảng dữ liệu liên kết (khách hàng, đơn hàng, sản phẩm, thanh toán, đánh giá, người bán, vị trí địa lý...)
- **Thời gian:** 2016–2018

---

## Kiến trúc & Quy trình

Dự án áp dụng ý tưởng kiến trúc **Bronze – Silver – Gold** (đơn giản hóa cho quy mô cá nhân):

| Layer | Nội dung | Công cụ |
|---|---|---|
| 🟫 **Bronze** | Dữ liệu thô, giữ nguyên gốc từ Kaggle | Python (pandas) |
| ⬜ **Silver** | Dữ liệu đã làm sạch: xử lý trùng lặp, missing values, sai định dạng, kiểm tra tính toàn vẹn giữa các bảng | Python (pandas) → SQL Server |
| 🟨 **Gold** | Các SQL View tổng hợp sẵn, phục vụ trực tiếp cho phân tích và dashboard | SQL Server (Views) → Power BI |

### Các bước thực hiện

1. **Python — EDA & Cleaning:** Load 9 file CSV, khảo sát tổng quan, xử lý missing values và duplicate, kiểm tra tính toàn vẹn dữ liệu (referential integrity) giữa các bảng.
2. **SQL Server — Modeling & Analysis:** Import dữ liệu sạch, viết 8 câu query phân tích chính, đóng gói thành **8 SQL Views** để tái sử dụng.
3. **Power BI — Dashboard:** Kết nối trực tiếp vào SQL Server (Import mode), xây dựng dashboard 1 trang gồm 3 phần tương ứng 3 câu hỏi kinh doanh.

---

## Data Cleaning — Các quyết định quan trọng

Đây là những vấn đề chất lượng dữ liệu thực tế đã gặp phải và cách xử lý — thể hiện tư duy nghiệp vụ và phương pháp xử lý dữ liệu thực tế.:

| Vấn đề phát hiện | Quyết định xử lý | Lý do |
|---|---|---|
| Bảng `geolocation` có ~262.000 dòng trùng lặp (nhiều tọa độ ứng với cùng 1 zip code) | Gộp về 1 dòng/zip code bằng giá trị trung bình lat/lng | Mục đích phân tích chỉ cần cấp độ khu vực, không cần độ chính xác từng mét |
| Cột `geolocation_city` bị lỗi chính tả nghiêm trọng, không nhất quán | Loại bỏ cột city, chỉ giữ `state` (đã chuẩn hóa sẵn) | State đáng tin cậy hơn nhiều cho phân tích theo khu vực; sự cân đối hợp lý giữa độ chi tiết và độ tin cậy của dữ liệu. |
| 8 đơn hàng có `order_status = 'delivered'` nhưng thiếu ngày giao hàng thực tế | Giữ nguyên NULL, loại khỏi các phép tính thời gian giao hàng | Số lượng không đáng kể (0.008%); đây là lỗi ghi nhận dữ liệu gốc, tránh việc gán giá trị làm sai lệch bản chất dữ liệu gốc. |
| 610 sản phẩm thiếu toàn bộ thông tin danh mục & metadata | Điền `category = 'unknown'`, metadata = 0 | Giữ lại dòng dữ liệu (vì vẫn có đơn hàng liên quan) thay vì xóa, tránh mất dữ liệu order_items |
| Nhiều danh mục sản phẩm chỉ có vài đơn hàng/review | Áp dụng `HAVING COUNT(...) >= 30` khi phân tích theo danh mục | Tránh kết luận sai lệch từ cỡ mẫu quá nhỏ |
| 3 tháng đầu dataset (09/2016 – 12/2016) có doanh thu gần như bằng 0 | Loại khỏi phân tích xu hướng theo tháng | Đây là giai đoạn soft-launch của nền tảng, không đại diện cho hoạt động kinh doanh thực tế |

---

## Phân tích SQL

8 câu hỏi phân tích được đóng gói thành 8 SQL View, sử dụng: `JOIN`, `GROUP BY`, `HAVING`, `CTE`, Subquery, Window Functions (`LAG`, `RANK`), `CASE WHEN`.

| View | Câu hỏi trả lời | Kỹ thuật chính |
|---|---|---|
| `vw_business_overview` | Tổng doanh thu, số đơn hàng, AOV | Subquery, Aggregation |
| `vw_monthly_revenue` | Doanh thu theo tháng & tăng trưởng MoM | CTE, `LAG()` |
| `vw_category_revenue` | Doanh thu theo danh mục sản phẩm | JOIN, `GROUP BY` |
| `vw_customer_rfm` | Recency – Frequency – Monetary từng khách hàng | CTE, `CROSS JOIN`, `DATEDIFF` |
| `vw_customer_ranking` | Xếp hạng khách hàng theo chi tiêu | `RANK()` |
| `vw_customer_repeat_rate` | Tỷ lệ khách mua 1 lần vs mua lại | `CASE WHEN`, Window Function |
| `vw_delivery_by_state` | Thời gian giao hàng theo khu vực | `AVG`, `HAVING` |
| `vw_review_by_category` | Điểm đánh giá theo danh mục sản phẩm | `AVG`, `HAVING` |

📄 Toàn bộ câu lệnh SQL chi tiết: xem thư mục [`/sql`](./sql)

---

## Dashboard Power BI

Dashboard 1 trang, kết nối trực tiếp SQL Server → Power BI (Import mode), gồm 3 khu vực tương ứng 3 phần câu chuyện phân tích:

![Dashboard Full](images/dashboard.png)

**Business Overview:** Card tổng quan (đơn hàng, AOV, doanh thu) · Biểu đồ doanh thu theo tháng · Top danh mục theo doanh thu (Pareto chart)

**Customer:** Tỷ lệ khách mua 1 lần vs mua lại · Bảng Top 10 khách hàng chi tiêu nhiều nhất

**Operations:** Thời gian giao hàng trung bình theo bang · Điểm đánh giá trung bình theo danh mục sản phẩm

📊 File Power BI: [`/powerbi/olist_ecommerce_dashboard.pbix`](./powerbi)

---

## Insight chính

- 📈 **Doanh thu tăng trưởng mạnh trong 2017**, đạt đỉnh vào tháng 11/2017 (mùa mua sắm cuối năm), sau đó bước vào giai đoạn ổn định/bão hòa trong suốt 2018. Đáng chú ý: tăng trưởng này diễn ra trong khi retention (xem bên dưới) rất thấp — doanh thu phụ thuộc phần lớn vào việc liên tục thu hút khách hàng mới (Acquisition) thay vì khai thác giá trị vòng đời từ tệp khách hàng cũ (Retention) — một mô hình tăng trưởng tiềm ẩn nhiều rủi ro về chi phí CAC trong dài hạn.

- 💄 **`health_beauty`** là danh mục đóng góp doanh thu lớn nhất, theo sau bởi `watches_gifts` và `bed_bath_table`. Đây đều là các nhóm sản phẩm có tần suất mua **thấp** (không phải hàng tiêu dùng nhanh) — một phần lý giải vì sao tỷ lệ mua lại của Olist thấp hơn các mô hình FMCG, nơi khách hàng tự nhiên quay lại mua theo chu kỳ.

- ⚠️ **97% khách hàng chỉ mua đúng 1 lần**, chỉ 3% quay lại mua thêm — đây là vấn đề retention nghiêm trọng. Kết hợp với insight về danh mục sản phẩm ở trên, nguyên nhân có thể đến từ 2 phía: (1) đặc thù ngành hàng ít mua lặp lại, và (2) trải nghiệm sau mua chưa đủ tốt để tạo động lực quay lại — được củng cố bởi 2 insight vận hành bên dưới.

- 🚚 **Khu vực miền Bắc Brazil (RR, AP, AM)** có thời gian giao hàng trung bình 26–29 ngày, gấp hơn 3 lần so với **São Paulo** (8 ngày). Nếu retention ở các khu vực này thấp hơn đáng kể so với SP, dữ liệu chỉ ra mối tương quan rõ rệt giữa thời gian giao hàng kéo dài và sự sụt giảm trong tỷ lệ quay lại của khách hàng.

- ⭐ **`office_furniture`** là danh mục bị đánh giá thấp nhất (3.49/5), trong khi các danh mục **sách** đều đạt trên 4.3/5. Điểm chung của các danh mục bị đánh giá thấp thường là sản phẩm cồng kềnh, dễ hư hỏng khi vận chuyển — gợi ý vấn đề nằm ở **quy trình đóng gói/vận chuyển** hơn là chất lượng sản phẩm gốc, và đây cũng là một mắt xích trong bài toán retention tổng thể.

---

## Đề xuất hành động (Recommendations)

Dựa trên các insight trên, đây là những hướng hành động cụ thể Olist có thể cân nhắc:

1. **Ưu tiên chương trình giữ chân khách hàng cho lần mua thứ 2** — ví dụ mã giảm giá có thời hạn gửi sau đơn hàng đầu tiên, thay vì tiếp tục dồn ngân sách marketing cho việc thu hút khách hoàn toàn mới.
2. **Điều tra sâu hơn mối liên hệ giữa thời gian giao hàng và tỷ lệ quay lại theo từng khu vực** — nếu xác nhận đúng, nên cân nhắc kho hàng vệ tinh hoặc đối tác vận chuyển riêng cho khu vực miền Bắc.
3. **Rà soát quy trình đóng gói cho nhóm hàng cồng kềnh** (nội thất, đồ gia dụng lớn) — đây là nhóm có điểm đánh giá thấp nhất, khả năng cao liên quan đến hư hỏng khi vận chuyển.
4. **Cân nhắc bổ sung danh mục sản phẩm có tần suất mua cao hơn** để tự nhiên thúc đẩy tỷ lệ mua lại, thay vì phụ thuộc hoàn toàn vào các danh mục mua không thường xuyên hiện tại.

---

## Cấu trúc thư mục

```
olist-ecommerce-analysis/
├── data/
│   └── raw/                          # Dữ liệu gốc từ Kaggle
├── python/
│   └── 01_eda_cleaning.ipynb         # EDA & Data Cleaning
├── sql/
│   ├── 01_views_business_overview.sql
│   ├── 02_views_customer.sql
│   └── 03_views_operations.sql
├── powerbi/
│   └── olist_ecommerce_dashboard.pbix
├── images/
│   ├── dashboard_full.png
│   └── dashboard_overview.png
└── README.md
```

---

## Công cụ sử dụng

- **Python** (pandas) — Thu thập, khảo sát & làm sạch dữ liệu
- **SQL Server / SSMS** — Modeling dữ liệu, viết query phân tích, tạo Views
- **Power BI Desktop** — Xây dựng dashboard trực quan

---

## Tác giả

Dự án mô phỏng quy trình xử lý và phân tích dữ liệu E-Commerce thực tế, bao gồm Data Cleaning, SQL Modeling và trực quan hóa qua Power BI.

📫 Liên hệ: *nguyenhaintnh304@gmail.com*
