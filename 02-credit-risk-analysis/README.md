# Báo cáo tình hình cấp tín dụng — Ngân hàng TMCP VNC, 6 tháng đầu năm 2024

Xây dựng bộ stored procedure trên SQL Server để tự động hoá báo cáo tín dụng định kỳ: quy mô dư nợ, hiệu quả thu hồi nợ, diễn biến lãi suất và phân bổ theo mạng lưới chi nhánh.

**Vai trò:** Data Analyst · **Thời gian:** 11/2025 – 02/2026 · **Công cụ:** SQL Server, Microsoft Excel

---

## Bài toán

Báo cáo tín dụng nửa năm trước đây được tổng hợp thủ công từ nhiều nguồn, mỗi kỳ làm lại từ đầu và khó đối chiếu giữa các kỳ. Yêu cầu: dựng một bộ truy vấn nhận vào ngày đầu kỳ và ngày cuối kỳ, trả ra đúng năm bảng của báo cáo, chạy lại cho kỳ nào cũng được mà không phải sửa câu lệnh.

## Mô hình dữ liệu

Bốn bảng chính:

| Bảng | Nội dung |
|---|---|
| `HOPDONG_TINDUNG` | Hợp đồng vay: số tiền, lãi suất, ngày giải ngân, ngày đáo hạn |
| `KHACHHANG_TRANO` | Lịch sử trả nợ: tiền gốc, tiền lãi, ngày trả |
| `KHACHHANG` | Thông tin khách hàng, mã chi nhánh |
| `CHINHANH` | Danh mục chi nhánh |

## Năm stored procedure

| Procedure | Trả về |
|---|---|
| `prc_baocao_tindung` | Quy mô tín dụng đầu kỳ, phát sinh tăng, phát sinh giảm, cuối kỳ |
| `prc_max_hdtd` | Các hợp đồng giải ngân lớn nhất trong kỳ kèm lãi suất áp dụng |
| `prc_thn` | Thu hồi nợ theo quý, tách riêng gốc và lãi |
| `prc_lsbq` | Lãi suất cho vay bình quân theo năm, có gộp giai đoạn lịch sử |
| `prc_baocao_duno_cn` | Dư nợ và biến động theo từng chi nhánh |

Code đầy đủ: [`sql/bao-cao-tin-dung.sql`](sql/bao-cao-tin-dung.sql) · Kết quả: [`data/bao-cao-tin-dung-2024H1.csv`](data/bao-cao-tin-dung-2024H1.csv)

Hai điểm kỹ thuật đáng chú ý trong bộ truy vấn:

- **Dư nợ gốc còn lại** không có sẵn trong bảng nào. Phải tính bằng tổng giá trị hợp đồng trừ tổng tiền gốc đã trả tính đến thời điểm chốt, dùng CTE riêng cho đầu kỳ và cuối kỳ rồi `left join` để không mất hợp đồng chưa phát sinh khoản trả nào.
- **Khách hàng tăng và giảm** phải loại trừ khách đã có dư nợ từ trước, bằng mệnh đề `not in` trên chính bảng hợp đồng. Nếu chỉ đếm `distinct` theo khoảng ngày sẽ đếm trùng khách cũ vay thêm thành khách mới.

---

## Kết quả

### Quy mô tín dụng

| Tiêu chí | Số hợp đồng | Số khách hàng | Tổng giá trị hợp đồng | Dư nợ gốc còn lại |
|---|---:|---:|---:|---:|
| 31/12/2023 | 255 | 190 | 2.612,96 tỷ | 1.640,01 tỷ |
| Phát sinh tăng | 43 | 43 | 324,45 tỷ | 324,45 tỷ |
| Phát sinh giảm | 23 | 11 | 184,60 tỷ | 272,00 tỷ |
| 30/06/2024 | 275 | 222 | 2.752,81 tỷ | 1.692,45 tỷ |

### Thu hồi nợ 2024

| Mốc | Gốc đã thu | Lãi đã thu | Tổng |
|---|---:|---:|---:|
| Quý 1 | 136,27 tỷ | 56,79 tỷ | 193,07 tỷ |
| Quý 2 | 135,73 tỷ | 55,13 tỷ | 190,86 tỷ |
| Quý 3 | 152,02 tỷ | 62,78 tỷ | 214,80 tỷ |
| Quý 4 | 180,16 tỷ | 67,77 tỷ | 247,93 tỷ |
| **Cả năm** | **604,18 tỷ** | **242,47 tỷ** | **846,65 tỷ** |

### Lãi suất cho vay bình quân

| Giai đoạn | Lãi suất |
|---|---:|
| Từ 2020 về trước | 14,16% |
| 2021 | 15,00% |
| 2022 | 15,83% |
| 2023 | 13,88% |
| 2024 | 14,89% |

---

## Phân tích

**1. Hạn mức ký nhiều nhưng dư nợ thực tăng ít.** Giá trị hợp đồng mới trong kỳ là 324,45 tỷ, trong khi dư nợ gốc thực tế chỉ tăng 52,44 tỷ. Khoảng chênh này đến từ hai phía: khách ký hạn mức để dự phòng mà chưa giải ngân hết, và tốc độ thu hồi gốc gần tương đương tốc độ giải ngân mới. Ngân hàng giữ được quy mô dư nợ ổn định mà không chịu áp lực vốn lớn.

**2. Tăng trưởng đến từ khách mới, không phải cho vay thêm khách cũ.** Số khách hàng tăng 16,8% trong khi số hợp đồng chỉ tăng 7,8%. Tỷ lệ này cho thấy danh mục đang được phân tán thay vì dồn thêm vào nhóm khách sẵn có — tốt cho rủi ro tập trung.

**3. Nhưng rủi ro tập trung vẫn hiện diện rõ ở nhóm đầu.** Năm khách hàng lớn nhất chiếm 145 tỷ, tương đương gần 45% tổng giá trị phát sinh tăng trong kỳ. Đây là nhóm quyết định lợi nhuận của kỳ, đồng thời là nhóm cần cơ chế giám sát riêng: chỉ một khoản trong số này chuyển nhóm nợ là ảnh hưởng thấy ngay trên báo cáo.

**4. Dòng tiền thu hồi đều và có xu hướng tăng dần theo quý.** Tổng thu hồi cả năm 846,65 tỷ, trong đó lãi chiếm 28,6%. Thu hồi gốc tốt cho thấy khách có dòng tiền trả nợ theo kế hoạch; đây là nguồn để tái cho vay mà không phụ thuộc hoàn toàn vào huy động mới.

**5. Lãi suất phục hồi sau năm 2023 nhưng chưa về đỉnh.** Bình quân 2024 là 14,89%, cao hơn mức 13,88% của 2023 nhưng vẫn thấp hơn đỉnh 15,83% của 2022. Ngân hàng đang nới lại biên lợi nhuận sau giai đoạn hạ lãi suất hỗ trợ thị trường, chứ chưa quay về mặt bằng cao nhất.

---

## Đề xuất

| Phát hiện | Đề xuất |
|---|---|
| Gần 45% phát sinh tăng đến từ 5 khách hàng | Lập danh sách theo dõi riêng, soát lãi suất và tài sản bảo đảm theo tháng thay vì theo kỳ báo cáo |
| Chênh lệch lớn giữa hạn mức ký và dư nợ thực | Theo dõi tỷ lệ giải ngân trên hạn mức như một chỉ số riêng, vì hạn mức chưa dùng vẫn là cam kết phải chuẩn bị vốn |
| Thu hồi quý 4 cao đột biến so với quý 1 và 2 | Kiểm tra xem do mùa vụ hay do một vài khoản lớn đáo hạn, trước khi dùng số quý 4 làm cơ sở dự phóng |

---

*Dữ liệu thuộc một bài tập phân tích dữ liệu ngân hàng. Tên khách hàng và mã CIF trong bộ dữ liệu công bố ở đây đã được thay bằng mã ẩn danh; các chỉ tiêu tài chính giữ nguyên.*
