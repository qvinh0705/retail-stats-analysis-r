# =============================================================================
# Bài tập lớn Xác suất Thống kê (HCMUT) - lớp L05
# Làm năm 2023; chỉnh lại năm 2026 khi đưa lên GitHub
# Dataset: Transactional Retail Dataset of Electronics Store (Kaggle) - dirty_data.csv
#   https://www.kaggle.com/datasets/muhammadshahrayar/transactional-retail-dataset-of-electronics-store
# Chạy từ thư mục gốc của repo; đặt file dữ liệu tại data/dirty_data.csv
# Gói cần cài một lần:
#   install.packages(c("ggplot2", "dplyr", "ggpubr", "nortest", "car"))
# =============================================================================

library(ggplot2)
library(dplyr)
library(ggpubr)
library(nortest)
library(car)

# -----------------------------------------------------------------------------
# 1. Đọc và làm sạch dữ liệu
# -----------------------------------------------------------------------------
dirty_data <- read.csv("data/dirty_data.csv")
str(dirty_data)

new_data <- dirty_data[, c("nearest_warehouse", "order_price", "delivery_charges",
                           "coupon_discount", "order_total", "season",
                           "distance_to_nearest_warehouse", "is_happy_customer")]

# Xem 10 dòng đầu
head(new_data, 10)

# Đếm giá trị NA
sum(is.na(new_data))

# Các giá trị khác nhau của season và nearest_warehouse
unique(new_data$season)
unique(new_data$nearest_warehouse)

# Chuẩn hoá chữ hoa/thường (gọi dplyr::recode vì gói car cũng có hàm recode); đưa is_happy_customer về factor "False"/"True"
# (read.csv có thể đọc cột này thành logical hoặc chuỗi tuỳ phiên bản R)
new_data2 <- new_data %>%
  mutate(
    nearest_warehouse = dplyr::recode(nearest_warehouse,
                               "thompson" = "Thompson", "nickolson" = "Nickolson"),
    season = dplyr::recode(season, "spring" = "Spring", "summer" = "Summer",
                    "autumn" = "Autumn", "winter" = "Winter"),
    is_happy_customer = factor(ifelse(as.logical(is_happy_customer), "True", "False"),
                               levels = c("False", "True"))
  )

unique(new_data2$season)
unique(new_data2$nearest_warehouse)

ggplot(new_data2, aes(x = order_total)) +
  geom_histogram(col = "black", fill = "lightblue", bins = 10)
ggplot(new_data2, aes(y = order_total)) +
  geom_boxplot()

# Xử lý giá trị ngoại lai của order_total theo quy tắc 1.5*IQR
q1  <- quantile(new_data2$order_total, 0.25, na.rm = TRUE)
q3  <- quantile(new_data2$order_total, 0.75, na.rm = TRUE)
iqr <- IQR(new_data2$order_total, na.rm = TRUE)

df_cleaned <- new_data2 %>%
  mutate(order_total = ifelse(order_total > q3 + 1.5 * iqr |
                                order_total < q1 - 1.5 * iqr,
                              NA, order_total))

sum(is.na(df_cleaned))
mean(is.na(df_cleaned))

df_cleaned <- na.omit(df_cleaned)
df_cleaned <- df_cleaned %>%
  mutate(nearest_warehouse = as.factor(nearest_warehouse),
         season = as.factor(season))

# -----------------------------------------------------------------------------
# 2. Thống kê mô tả
# -----------------------------------------------------------------------------
summary(df_cleaned)

ggplot(df_cleaned, aes(x = order_total)) +
  geom_histogram(col = "black", fill = "lightblue", bins = 30)
ggplot(df_cleaned, aes(y = order_total, fill = season)) +
  geom_boxplot()
ggplot(df_cleaned, aes(y = order_total, fill = nearest_warehouse)) +
  geom_boxplot()

# Tần số của các biến phân loại
table(df_cleaned$nearest_warehouse)
table(df_cleaned$season)
table(df_cleaned$is_happy_customer)

thongke <- cbind(
  order_price                   = summary(df_cleaned$order_price),
  delivery_charges              = summary(df_cleaned$delivery_charges),
  coupon_discount               = summary(df_cleaned$coupon_discount),
  order_total                   = summary(df_cleaned$order_total),
  distance_to_nearest_warehouse = summary(df_cleaned$distance_to_nearest_warehouse)
)
thongke

# -----------------------------------------------------------------------------
# 3. Kiểm định trung bình 1 mẫu
#    H0: mu = 12400   vs   H1: mu != 12400
# -----------------------------------------------------------------------------
df1 <- df_cleaned %>%
  mutate(order_total_log = log10(order_total))

ggplot(df1, aes(x = order_total_log)) +
  geom_histogram(col = "black", fill = "lightblue", bins = 30)
ggplot(df1, aes(sample = order_total_log)) +
  stat_qq() +
  stat_qq_line()

# Kiểm tra tính chuẩn
shapiro.test(df1$order_total)
shapiro.test(df1$order_total_log)

# Nếu dữ liệu không chuẩn: với cỡ mẫu lớn (n > 30), theo định lý giới hạn trung
# tâm, trung bình mẫu xấp xỉ chuẩn nên t-test trên dữ liệu gốc vẫn dùng được.
# Kiểm tra trên log10 sẽ là giả thuyết về trung bình hình học, không phải trung
# bình của order_total, nên ta kiểm định trên dữ liệu gốc.
t.test(df_cleaned$order_total, mu = 12400, alternative = "two.sided", conf.level = 0.95)

# Đối chiếu bằng kiểm định phi tham số (giả thuyết về trung vị)
wilcox.test(df_cleaned$order_total, mu = 12400, alternative = "two.sided")

# -----------------------------------------------------------------------------
# 4. Kiểm định so sánh 2 mẫu độc lập
#    delivery_charges của khách hài lòng và không hài lòng
# -----------------------------------------------------------------------------
df2 <- df_cleaned %>%
  select(is_happy_customer, delivery_charges)

ggplot(df2, aes(x = delivery_charges)) +
  geom_histogram(color = "black", fill = "lightblue", bins = 10) +
  facet_wrap(. ~ is_happy_customer, scales = "free_x")

ggplot(df2, aes(sample = delivery_charges)) +
  stat_qq() +
  stat_qq_line(color = "blue") +
  facet_wrap(. ~ is_happy_customer, scales = "free_y")

# Kiểm tra tính chuẩn từng nhóm
shapiro.test(df2$delivery_charges[df2$is_happy_customer == "True"])
shapiro.test(df2$delivery_charges[df2$is_happy_customer == "False"])

# Kiểm tra phương sai đồng nhất
levene <- leveneTest(delivery_charges ~ is_happy_customer, data = df2)
levene

# Chọn var.equal theo kết quả Levene (p > 0.05 -> coi phương sai bằng nhau;
# ngược lại dùng Welch t-test)
equal_var <- levene$`Pr(>F)`[1] > 0.05
t.test(delivery_charges ~ is_happy_customer, data = df2, var.equal = equal_var)

ggbarplot(df2, x = "is_happy_customer", y = "delivery_charges",
          add = "mean_sd", color = "is_happy_customer")

df2 %>%
  group_by(is_happy_customer) %>%
  summarise(mean = mean(delivery_charges), sd = sd(delivery_charges))

# -----------------------------------------------------------------------------
# 5. ANOVA một nhân tố: order_total theo nearest_warehouse
# -----------------------------------------------------------------------------
df3 <- df_cleaned %>%
  select(nearest_warehouse, order_total)

av1 <- aov(order_total ~ nearest_warehouse, data = df3)
resid_df <- data.frame(resid = residuals(av1))

ggplot(resid_df, aes(x = resid)) +
  geom_histogram(color = "black", fill = "lightblue", bins = 15)
ggplot(resid_df, aes(sample = resid)) +
  stat_qq() +
  stat_qq_line(color = "blue")

# Kiểm tra tính chuẩn của phần dư
shapiro.test(resid_df$resid)
# Kiểm tra phương sai đồng nhất giữa các nhóm
leveneTest(order_total ~ nearest_warehouse, data = df3)

summary(av1)

# Nếu giả định chuẩn/đồng nhất phương sai bị vi phạm, đối chiếu bằng Kruskal-Wallis
kruskal.test(order_total ~ nearest_warehouse, data = df3)

# Kiểm tra mô hình
par(mfrow = c(2, 2))
plot(av1)
par(mfrow = c(1, 1))

# Phân tích post hoc
TukeyHSD(av1)
plot(TukeyHSD(av1))

# -----------------------------------------------------------------------------
# 6. Hồi quy tuyến tính: dự đoán order_total
#    H0: beta_i = 0 (hệ số không có ý nghĩa)   vs   H1: beta_i != 0
# -----------------------------------------------------------------------------
model_1_1 <- lm(order_total ~ order_price + delivery_charges + coupon_discount,
                data = df_cleaned)
summary(model_1_1)
# Ghi chú lúc làm bài (2023): p-value của delivery_charges ≈ 0.65 > 0.05 nên
# không bác bỏ H0, delivery_charges không có ý nghĩa thống kê -> bỏ biến này.

model_1_2 <- lm(order_total ~ order_price + coupon_discount, data = df_cleaned)
summary(model_1_2)

par(mfrow = c(2, 2))
plot(model_1_2)
par(mfrow = c(1, 1))

# -----------------------------------------------------------------------------
# 7. Hồi quy logistic: mức hài lòng của khách hàng (is_happy_customer)
# -----------------------------------------------------------------------------
# order_total được tính từ order_price, delivery_charges và coupon_discount, nên
# đưa cả 4 biến vào cùng mô hình sẽ gây đa cộng tuyến -> loại order_total.
df_logit <- df_cleaned %>% select(-order_total)

model_2_1 <- glm(is_happy_customer ~ ., family = binomial, data = df_logit)
vif(model_2_1)

# Chọn mô hình theo AIC (stepwise)
model_step <- step(model_2_1, trace = 0)
summary(model_step)

# Mô hình một biến để so sánh
model_2_2 <- glm(is_happy_customer ~ season, family = binomial, data = df_cleaned)
summary(model_2_2)

model_2_3 <- glm(is_happy_customer ~ delivery_charges, family = binomial, data = df_cleaned)
summary(model_2_3)

# Mô hình kết hợp season + delivery_charges.
# delivery_charges thay đổi theo mùa (kiểm tra bằng ANOVA bên dưới). Điều đó không
# cấm dùng cả hai biến; chỉ cần kiểm tra mức đa cộng tuyến bằng VIF
# (GVIF^(1/(2*Df)) < ~2 là chấp nhận được).
summary(aov(delivery_charges ~ season, data = df_cleaned))

model_2_4 <- glm(is_happy_customer ~ season + delivery_charges,
                 family = binomial, data = df_cleaned)
summary(model_2_4)
vif(model_2_4)

# So sánh mô hình một biến và mô hình kết hợp (likelihood ratio test)
anova(model_2_3, model_2_4, test = "Chisq")
AIC(model_2_2, model_2_3, model_2_4)
