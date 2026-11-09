# Bài tập lớn Xác suất Thống kê (2023)

> Bài tập lớn môn Xác suất Thống kê, lớp L05, Trường Đại học Bách Khoa, ĐHQG-HCM. **Làm năm 2023.** Năm 2026 code được chỉnh lại để đưa lên GitHub (xem [Ghi chú](#ghi-chú)).

Phân tích thống kê bộ dữ liệu giao dịch của một cửa hàng điện tử bằng R: làm sạch dữ liệu, thống kê mô tả, kiểm định giả thuyết, ANOVA và hồi quy.

## Dữ liệu

Nguồn: [Transactional Retail Dataset of Electronics Store](https://www.kaggle.com/datasets/muhammadshahrayar/transactional-retail-dataset-of-electronics-store) trên Kaggle (tác giả *muhammadshahrayar*). Bài này dùng file `dirty_data.csv`. File này được làm "bẩn" có chủ đích để luyện làm sạch dữ liệu: tên kho và mùa viết hoa/thường lẫn lộn, có giá trị ngoại lai, v.v.

Repo không kèm dữ liệu. Muốn chạy lại thì tải bộ dữ liệu từ link trên rồi đặt file vào `data/dirty_data.csv`.

Các biến được dùng:

| Biến | Ý nghĩa |
|---|---|
| `nearest_warehouse` | Kho gần khách hàng nhất (Thompson, Nickolson, Bakers) |
| `order_price` | Giá trị đơn hàng trước giảm giá |
| `delivery_charges` | Phí giao hàng |
| `coupon_discount` | Phần trăm giảm giá |
| `order_total` | Tổng tiền thanh toán |
| `season` | Mùa đặt hàng |
| `distance_to_nearest_warehouse` | Khoảng cách tới kho gần nhất (km) |
| `is_happy_customer` | Khách có hài lòng với đơn gần nhất không |

## Nội dung phân tích

1. **Làm sạch dữ liệu:** chuẩn hoá tên kho và mùa, loại ngoại lai của `order_total` theo quy tắc 1.5×IQR.
2. **Thống kê mô tả:** histogram, boxplot theo mùa và theo kho, bảng tần số.
3. **Kiểm định 1 mẫu:** trung bình `order_total` có bằng 12400 không (t-test, đối chiếu với Wilcoxon).
4. **Kiểm định 2 mẫu:** phí giao hàng của khách hài lòng và không hài lòng (Shapiro-Wilk, Levene, t-test).
5. **ANOVA một nhân tố:** `order_total` giữa các kho, kiểm tra giả định, post hoc Tukey HSD, đối chiếu Kruskal-Wallis.
6. **Hồi quy tuyến tính:** dự đoán `order_total` từ `order_price`, `delivery_charges`, `coupon_discount`.
7. **Hồi quy logistic:** các yếu tố ảnh hưởng đến `is_happy_customer`, chọn mô hình bằng stepwise AIC, kiểm tra đa cộng tuyến bằng VIF.

## Cách chạy

```r
install.packages(c("ggplot2", "dplyr", "ggpubr", "nortest", "car"))
```

Mở `BTL-XSTK-L05.R` trong RStudio, đặt working directory là thư mục gốc của repo rồi chạy từng phần để xem biểu đồ. Cũng có thể chạy cả file bằng lệnh:

```bash
Rscript BTL-XSTK-L05.R
```

## Ghi chú

Bài được làm năm 2023. Khi đưa lên GitHub năm 2026, code được chỉnh lại như sau:

- bỏ đường dẫn tuyệt đối và các lệnh `install.packages` trong script;
- gọi `dplyr::recode` vì gói `car` cũng có hàm `recode` trùng tên;
- chọn `var.equal` của t-test theo kết quả kiểm định Levene;
- trong hồi quy logistic, bỏ `order_total` khỏi mô hình đầy đủ vì biến này được tính từ các biến giá còn lại;
- thay mô hình `glm(season ~ delivery_charges, family = binomial)` (sai, vì `season` có 4 mức) bằng ANOVA và VIF.
