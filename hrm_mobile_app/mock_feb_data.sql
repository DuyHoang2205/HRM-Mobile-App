DECLARE @EmpID INT = 3195;
DECLARE @SiteID VARCHAR(50) = 'REEME';
DECLARE @AttendCode NVARCHAR(50);

-- Lấy mã vân tay của baoduy
SELECT TOP 1 @AttendCode = attendCode FROM Employee WHERE ID = @EmpID;

-- 1. XÓA SÁCH DỮ LIỆU CŨ THÁNG 2 (Refresh làm lại từ đầu)
DELETE FROM AttendanceTime WHERE attendCode = @AttendCode AND authDate >= '2026-02-01' AND authDate <= '2026-02-28';
DELETE FROM OnLeaveFileLine WHERE employeeID = @EmpID AND fromDate >= '2026-02-01' AND toDate <= '2026-02-28';

-- 2. TẠO DATA QUẸT THẺ (VÂN TAY) ĐI LÀM
-- Mình bỏ ngày 24/02 để nó trống trơn (Không có data In/Out, cũng không có đơn phép)
INSERT INTO AttendanceTime (attendCode, authDate, authTime)
SELECT @AttendCode, DateVal, TimeVal
FROM (
    VALUES 
    -- Tuần 1: Ngoan ngoãn đủ công
    ('2026-02-02', '08:00:00'), ('2026-02-02', '17:05:00'),
    ('2026-02-03', '07:55:00'), ('2026-02-03', '17:10:00'),
    ('2026-02-04', '07:50:00'), ('2026-02-04', '17:00:00'),
    ('2026-02-05', '08:00:00'), ('2026-02-05', '17:00:00'),
    ('2026-02-06', '07:58:00'), ('2026-02-06', '17:02:00'),
    
    -- Tuần 2: 
    ('2026-02-09', '08:00:00'), ('2026-02-09', '17:00:00'),
    ('2026-02-10', '08:00:00'), ('2026-02-10', '17:00:00'),
    ('2026-02-11', '08:00:00'), ('2026-02-11', '17:00:00'),
    ('2026-02-12', '08:15:00'), 
    -- Ngày 13 nghỉ trọn ngày (Trống log)
    
    -- Tuần 3:
    ('2026-02-16', '08:00:00'), ('2026-02-16', '17:00:00'),
    ('2026-02-17', '08:00:00'), ('2026-02-17', '17:00:00'),
    ('2026-02-18', '08:00:00'), ('2026-02-18', '17:00:00'),
    ('2026-02-19', '08:00:00'), ('2026-02-19', '17:00:00'),
    ('2026-02-20', '08:00:00'), ('2026-02-20', '12:00:00'),
    
    -- Tuần 4: Chăm chỉ, NHƯNG BỎ QUÊN NGÀY 24/02
    ('2026-02-23', '08:00:00'), ('2026-02-23', '17:00:00'),
    -- Ngày 24/02 MIẾNG MẤT
    ('2026-02-25', '08:00:00'), ('2026-02-25', '17:00:00'),
    ('2026-02-26', '08:00:00'), ('2026-02-26', '17:00:00'),
    ('2026-02-27', '08:00:00'), ('2026-02-27', '17:00:00')
) AS Data(DateVal, TimeVal);

-- 3. TẠO DATA CÁC ĐƠN XIN NGHỈ ĐĂNG KÝ (ĐÃ ĐƯỢC ADMIN DUYỆT - status = 3)
-- Lưu ý: Status = 3 mới là Đã duyệt nhé (Tôi đã sửa 2 thành 3 để giống với Logic của App)
INSERT INTO OnLeaveFileLine (
    employeeID, status, permissionType, fromDate, toDate, 
    expired, qty, year, description, createBy, createDate, updateDate, docType, siteID
)
VALUES 
-- Đơn xin nghỉ phép cả ngày 13/02 (Đã được Admin ID=2 duyệt)
(
    @EmpID, 3, 1, '2026-02-13', '2026-02-13', 
    '2026-03-31', 1.0, 2026, N'Nghỉ phép cá nhân (UAT Mock)', 'ADMIN', GETDATE(), GETDATE(), 'OLDocType', @SiteID
),
-- Đơn xin nghỉ phép buổi chiều 20/02 (Đã được duyệt 0.5 công)
(
    @EmpID, 3, 1, '2026-02-20', '2026-02-20', 
    '2026-03-31', 0.5, 2026, N'Nghỉ phép đột xuất chiều (UAT Mock)', 'ADMIN', GETDATE(), GETDATE(), 'OLDocType', @SiteID
);

-- CHẠY SP CALCULATE ĐỂ CẬP NHẬT TỔNG HỢP (Tính toán lại dữ liệu)
EXEC sp_GetDailyTimesheetSummary @EmpID, '2026-02-01', '2026-02-28', @SiteID;
