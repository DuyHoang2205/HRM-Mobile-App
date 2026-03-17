/*
OT + Timesheet demo kit for KIA / admin
Muc tieu:
- Co ca lam viec trong thang 02/2026
- Co cac symbol de demo: 1, 0, X, P, C, x/P
- Co data inspect OT de hieu DB

Tai khoan demo hien tai:
- accountID = admin
- employeeID = 8847
- code = 200190
- attendCode = 01964
- siteID = KIA

Script nay chi dung marker demo rieng de tranh dung du lieu that.
*/

USE DB_HRM
GO

/* -------------------------------------------------------------------------
1. Inspect nhanh OT backend/runtime
------------------------------------------------------------------------- */
SELECT
    p.name AS proc_name,
    prm.parameter_id,
    prm.name AS parameter_name,
    TYPE_NAME(prm.user_type_id) AS data_type
FROM sys.procedures p
JOIN sys.parameters prm
    ON p.object_id = prm.object_id
WHERE p.name IN (
    'DecisionOvertimeGetAll',
    'DecisionOvertimeGetByUser',
    'DecisionOvertimeGetByUser_bk',
    'GetListShiftOvertime',
    'GetShiftByDate',
    'AttendanceGetWithDay',
    'sp_GetDailyTimesheetSummary'
)
ORDER BY p.name, prm.parameter_id
GO

SELECT TOP 20
    id, code, status, fromDate, toDate, requestBy, reason, note, shiftID, qty,
    createBy, createDate, updateBy, updateDate, docType, siteID
FROM dbo.DecisionOvertime
WHERE siteID = 'KIA'
ORDER BY id DESC
GO

/* -------------------------------------------------------------------------
2. Dam bao admin co row WorkOfDayPlan nam 2026 va set ca cho thang 02
   Shift 8 = CA VAN PHONG (08:00-17:00)
------------------------------------------------------------------------- */
IF NOT EXISTS (
    SELECT 1
    FROM dbo.WorkOfDayPlan
    WHERE EmployeeID = 8847
      AND Yearly = 2026
)
BEGIN
    INSERT INTO dbo.WorkOfDayPlan
    (
        EmployeeID,
        Yearly,
        CreatedBy,
        CreatedDate,
        UpdatedBy,
        UpdatedDate,
        SiteID
    )
    VALUES
    (
        8847,
        2026,
        'admin',
        CAST(GETDATE() AS DATE),
        'admin',
        CAST(GETDATE() AS DATE),
        'KIA'
    )
END
GO

UPDATE dbo.WorkOfDayPlan
SET
    c0201 = 8,
    c0202 = 8,
    c0203 = 8,
    c0204 = 8,
    c0205 = 8,
    c0206 = 8,
    c0207 = 8,
    c0208 = 8,
    c0209 = 8,
    c0210 = 8,
    c0211 = 8,
    c0212 = 8,
    c0213 = 8,
    c0214 = 8,
    c0215 = 8,
    c0216 = 8,
    c0217 = 8,
    c0218 = 8,
    c0219 = 8,
    c0220 = 8,
    c0221 = 8,
    c0222 = 8,
    c0223 = 8,
    c0224 = 8,
    c0225 = 8,
    c0226 = 8,
    c0227 = 8,
    c0228 = 8
WHERE EmployeeID = 8847
  AND Yearly = 2026
GO

/* -------------------------------------------------------------------------
3. Xoa data demo cu trong thang 02/2026 (chi xoa marker do script nay tao)
------------------------------------------------------------------------- */
DELETE FROM dbo.AttendanceTime
WHERE AttendCode = '01964'
  AND AuthDate BETWEEN '2026-02-01' AND '2026-02-28'
  AND Location IN (15, 16)
GO

DELETE FROM dbo.OnLeaveFileLine
WHERE EmployeeID = 8847
  AND SiteID = 'KIA'
  AND Year = 2026
  AND FromDate BETWEEN '2026-02-01' AND '2026-02-28'
  AND Description LIKE 'DEMO-FEB-%'
GO

/* -------------------------------------------------------------------------
4. Seed attendance de tao symbol 1 / X / 0 / x/P
   2026-02-03 -> 1     (du cong)
   2026-02-04 -> X     (1 log duy nhat)
   2026-02-08 -> 1     (co attendance de ket hop half-day leave thanh x/P)
   2026-02-09 -> 0     (co ca nhung khong scan, khong leave)
------------------------------------------------------------------------- */
INSERT INTO dbo.AttendanceTime (AttendCode, AuthDate, AuthTime, DeviceNo, Location)
VALUES
('01964', '2026-02-03', '08:00:00', 0, 15),
('01964', '2026-02-03', '17:00:00', 0, 15),
('01964', '2026-02-04', '08:05:00', 0, 15),
('01964', '2026-02-08', '08:00:00', 0, 15),
('01964', '2026-02-08', '12:00:00', 0, 15)
GO

/* -------------------------------------------------------------------------
5. Seed leave approved de tao symbol P / C / x/P
   2026-02-05 -> P  (Nghi bu full day, permissionType 28)
   2026-02-06 -> C  (Cong tac, permissionType 25)
   2026-02-08 -> x/P (Half-day leave + attendance, permissionType 35, qty 0.5)
------------------------------------------------------------------------- */
INSERT INTO dbo.OnLeaveFileLine
(
    SiteID,
    Status,
    PermissionType,
    FromDate,
    TotalDay,
    Description,
    CreateBy,
    UpdateBy,
    CreateDate,
    UpdateDate,
    EmployeeID,
    Expired,
    ToDate,
    IsOneDay,
    IsHalfDay,
    Year,
    Qty,
    DocType
)
VALUES
(
    'KIA',
    3,
    28,
    '2026-02-05',
    1,
    'DEMO-FEB-P-Nghi bu full day',
    'admin',
    'admin',
    CAST(GETDATE() AS DATE),
    CAST(GETDATE() AS DATE),
    8847,
    '2026-03-07',
    '2026-02-05',
    1,
    0,
    2026,
    1.0,
    'OLDocType'
),
(
    'KIA',
    3,
    25,
    '2026-02-06',
    1,
    'DEMO-FEB-C-Cong tac full day',
    'admin',
    'admin',
    CAST(GETDATE() AS DATE),
    CAST(GETDATE() AS DATE),
    8847,
    '2026-03-08',
    '2026-02-06',
    1,
    0,
    2026,
    1.0,
    'OLDocType'
),
(
    'KIA',
    3,
    35,
    '2026-02-08',
    0.5,
    'DEMO-FEB-XP-Half day leave',
    'admin',
    'admin',
    CAST(GETDATE() AS DATE),
    CAST(GETDATE() AS DATE),
    8847,
    '2026-03-10',
    '2026-02-08',
    0,
    1,
    2026,
    0.5,
    'OLDocType'
)
GO

/* -------------------------------------------------------------------------
6. Verify shift + scan + leave raw
------------------------------------------------------------------------- */
EXEC dbo.GetShiftByDate
    @EmployeeID = 8847,
    @Date = '2026-02-03',
    @SiteID = 'KIA'
GO

EXEC dbo.AttendanceGetWithDay
    @employeeID = 8847,
    @day = '2026-02-03'
GO

SELECT
    ID,
    Status,
    PermissionType,
    FromDate,
    ToDate,
    Qty,
    Description,
    EmployeeID,
    SiteID
FROM dbo.OnLeaveFileLine
WHERE EmployeeID = 8847
  AND SiteID = 'KIA'
  AND Year = 2026
  AND FromDate BETWEEN '2026-02-01' AND '2026-02-28'
ORDER BY FromDate
GO

/* -------------------------------------------------------------------------
7. Verify summary raw tu backend SQL
   Raw summary chi cho thay 1 / 0 / x tu attendance.
   P / C / x/P se duoc overlay o client tu leave approved.
------------------------------------------------------------------------- */
EXEC dbo.sp_GetDailyTimesheetSummary
    @employeeID = 8847,
    @fromDate = '2026-02-01',
    @toDate = '2026-02-10',
    @siteID = 'KIA'
GO

/* -------------------------------------------------------------------------
8. Bang doi chieu ky hieu demo du kien tren UI
   2026-02-03 -> 1
   2026-02-04 -> X
   2026-02-05 -> P
   2026-02-06 -> C
   2026-02-08 -> x/P
   2026-02-09 -> 0
------------------------------------------------------------------------- */
SELECT '2026-02-03' AS DemoDate, '1'   AS ExpectedSymbol, 'Attendance du cong' AS Meaning
UNION ALL SELECT '2026-02-04', 'X',   'Thieu 1 log check-in/out'
UNION ALL SELECT '2026-02-05', 'P',   'Nghi bu full day approved'
UNION ALL SELECT '2026-02-06', 'C',   'Cong tac approved'
UNION ALL SELECT '2026-02-08', 'x/P', 'Half-day cong + half-day phep'
UNION ALL SELECT '2026-02-09', '0',   'Co ca nhung khong scan, khong leave'
GO
