-- =====================================================================
-- K2 — รายชื่อสัญญาที่ถึงเกณฑ์บอกเลิกสัญญา
--
--   เกณฑ์ A : ค้างชำระครบ 6 งวด (นับจากการ์ดลูกหนี้จริง)
--             หรือระบบเคยนับ NUMBER_OF_OD_INSTALLMENT >= 6 ในรอบ
--   เกณฑ์ B : สัญญาหมดอายุแล้ว (งวดสุดท้ายเลยกำหนด) แต่ยังมีงวดค้าง
--             และระบบให้สถานะ Overdue 6
--
--   ยอดเรียกเก็บ = คำนวณจากการ์ด (งวดที่เลยกำหนดและยังไม่มีใบเสร็จ x ค่างวด)
--   คอลัมน์ท้ายตาราง = ฟิลด์เสริมที่ไม่ได้อยู่ในหนังสือ แต่ควรมีติดไว้
--
--   หมายเหตุ: 7 ช่อง txt ใน Excel (J, L, S, U, W, Y, AA) เป็นสูตร =BAHTTEXT()
--             SQL ทำแทนไม่ได้ ต้องใส่สูตรตอนเขียนลงไฟล์
-- =====================================================================

DECLARE @from date = '2026-08-01';                                   -- ต้นรอบที่จะออกหนังสือ
DECLARE @to   date = '2026-08-31';                                   -- ปลายรอบ
DECLARE @snap date = (SELECT MAX(EXTRACT_DATE) FROM COLLECTION_OD);  -- snapshot ล่าสุด

WITH card AS (                       -- สรุปการ์ดลูกหนี้ต่อสัญญา
    SELECT k.CONTRACT_ID,
           COUNT(*)                                                        AS N_CARD,
           MAX(k.DUEDATE)                                                  AS LAST_DUE,
           MIN(CASE WHEN k.RECEIPT_NUMBER IS NULL THEN k.INSTALL_NUM END)  AS FIRST_UNPAID,
           SUM(CASE WHEN k.RECEIPT_NUMBER IS NULL THEN 1 ELSE 0 END)       AS N_UNPAID,
           SUM(CASE WHEN k.RECEIPT_NUMBER IS NULL AND k.DUEDATE <= @snap
                    THEN 1 ELSE 0 END)                                     AS N_PASTDUE
    FROM CUSTOMER_CARD k
    GROUP BY k.CONTRACT_ID
),
od_seq AS (                          -- ไล่ลำดับงวดที่ค้างและเลยกำหนดแล้ว
    SELECT k.CONTRACT_ID, k.INSTALL_NUM, k.DUEDATE,
           ROW_NUMBER() OVER (PARTITION BY k.CONTRACT_ID ORDER BY k.INSTALL_NUM) AS od_rank
    FROM CUSTOMER_CARD k
    WHERE k.RECEIPT_NUMBER IS NULL AND k.DUEDATE <= @snap
),
od6 AS (SELECT CONTRACT_ID, INSTALL_NUM AS OD6_INSTALL, DUEDATE AS OD6_DUE
        FROM od_seq WHERE od_rank = 6),
odlast AS (SELECT CONTRACT_ID, MAX(INSTALL_NUM) AS LAST_OD_INSTALL
           FROM od_seq GROUP BY CONTRACT_ID),
snap AS (SELECT * FROM COLLECTION_OD WHERE EXTRACT_DATE = @snap),
hit6sys AS (SELECT DISTINCT CONTRACT_ID FROM COLLECTION_OD
            WHERE TRY_CAST(NUMBER_OF_OD_INSTALLMENT AS int) >= 6
              AND EXTRACT_DATE BETWEEN @from AND @to)
SELECT
    -- ═══ ส่วนที่ 1 : ตรงกับไฟล์ Excel หนังสือบอกเลิกสัญญา ═══════════════
    ct.CONTRACT_NUMBER                                     AS [A_สัญญาเลขที่],
    LTRIM(RTRIM(ISNULL(pf.Prefix_name, N'') + N' '
              + ISNULL(p.FIRST_NAME,   N'') + N' '
              + ISNULL(p.LAST_NAME,    N'')))              AS [B_ชื่อผู้ทำสัญญา],
    ct.CONTRACT_START                                      AS [C_วันที่ทำสัญญา],
    N'เช่าซื้อ ' + cat.CATEGORY_NAME                       AS [D_ประเภทสัญญา],
    b.BRAND_NAME                                           AS [E_ยี่ห้อ],
    pr.MODEL_NAME                                          AS [F_รุ่นแบบ],
    pr.MODEL_NUMBER                                        AS [G_เครื่อง],
    pr.SERIAL_NUMBER                                       AS [H_SerialNumber],
    CAST(pr.INSTALL_SUM * pr.INSTALL_NUM AS decimal(12,2)) AS [I_ค่าเช่าซื้อรวมVAT],
    pr.INSTALL_SUM                                         AS [K_งวดละ],
    pr.INSTALL_NUM                                         AS [M_จำนวนงวด],
    pr.FRIST_PAY_DATE                                      AS [N_วันเริ่มชำระงวดแรก],
    pr.DUEDATE_NUM                                         AS [O_วันที่ชำระงวดต่อไป],
    cd.FIRST_UNPAID                                        AS [P_ค้างชำระงวดแรก],
    ISNULL(od6.OD6_INSTALL, ol.LAST_OD_INSTALL)            AS [Q_งวดที่ครบOD6],
    CAST(cd.N_PASTDUE * pr.INSTALL_SUM AS decimal(12,2))   AS [R_ค่าเช่าซื้อค้าง],
    o.PENALTY_AMT                                          AS [T_ค่าเบี้ยปรับ],
    o.COLLECT_AMT                                          AS [V_ค่าติดตามทวงถาม],
    CAST(0 AS decimal(12,2))                               AS [X_ค่าใช้จ่ายอื่น],
    CAST(cd.N_PASTDUE * pr.INSTALL_SUM
         + o.PENALTY_AMT + o.COLLECT_AMT AS decimal(12,2)) AS [Z_รวมเป็นเงินทั้งสิ้น],
    DATEFROMPARTS(YEAR (ISNULL(od6.OD6_DUE, cd.LAST_DUE)) + 543,
                  MONTH(ISNULL(od6.OD6_DUE, cd.LAST_DUE)),
                  DAY  (ISNULL(od6.OD6_DUE, cd.LAST_DUE))) AS [AB_วันที่เป็นOD6],
    LTRIM(CONCAT_WS(N' ', a1.LINE1, a1.LINE2,
                    N'จังหวัด' + prov1.PROVINCE_NAME,
                    CAST(a.A1_POSTALCODE AS nvarchar(10)))) AS [AC_ที่อยู่ตามทะเบียนบ้าน],
    a1.LINE1                                               AS [AD_เลขที่],
    a1.LINE2                                               AS [AE_ตำบลอำเภอ],
    prov1.PROVINCE_NAME                                    AS [AF_จังหวัด],
    a.A1_POSTALCODE                                        AS [AG_รหัสไปรษณีย์],

    -- ═══ ส่วนที่ 2 : ฟิลด์เสริมที่ควรรู้ ════════════════════════════════
    -- ── ตัวตนลูกค้า ──
    p.TAX_ID                                               AS [เลขบัตรประชาชน],
    p.BIRTHDAY                                             AS [วันเกิด],
    DATEDIFF(year, p.BIRTHDAY, @snap)                      AS [อายุ],
    ocp.Ocpt_name                                          AS [อาชีพ],
    p.OFFICE_NAME                                          AS [ที่ทำงาน],
    o.PRODUCT_TYPE                                         AS [กลุ่มลูกค้า],
    -- ── ช่องทางติดต่อ ──
    p.PHONE                                                AS [เบอร์โทร],
    p.PHONE_SECOND                                         AS [เบอร์สำรอง],
    p.EMAIL                                                AS [อีเมล],
    -- ── ที่อยู่ปัจจุบัน (A2) — ใช้ส่งจริงดีกว่าทะเบียนบ้าน ──
    LTRIM(CONCAT_WS(N' ', a2.LINE1, a2.LINE2,
                    N'จังหวัด' + prov2.PROVINCE_NAME,
                    CAST(a.A2_POSTALCODE AS nvarchar(10)))) AS [ที่อยู่ปัจจุบัน],
    CASE WHEN ISNULL(a.A1_NO,N'') = ISNULL(a.A2_NO,N'')
          AND ISNULL(a.A1_SUBDISTRICT,0) = ISNULL(a.A2_SUBDISTRICT,0)
         THEN N'ตรงกับทะเบียนบ้าน' ELSE N'ต่างจากทะเบียนบ้าน' END AS [ที่อยู่ปัจจุบันตรงกันไหม],
    -- ── ผู้ค้ำประกัน ──
    LTRIM(RTRIM(ISNULL(g.PREFIX,N'') + N' ' + ISNULL(g.FIRST_NAME,N'')
              + N' ' + ISNULL(g.LAST_NAME,N'')))           AS [ผู้ค้ำประกัน],
    g.RELATION_REF_DES                                     AS [ความสัมพันธ์ผู้ค้ำ],
    ISNULL(g.MOBILE, g.PHONE)                              AS [เบอร์ผู้ค้ำ],
    -- ── สถานะการเงินของสัญญา ──
    o.REMAINING_OUTSTANDING                                AS [ยอดคงเหลือทั้งสัญญา],
    o.PAID_NUMBER_OF_PERIOD                                AS [จ่ายมาแล้วกี่งวด],
    o.LAST_REPAY_DATE                                      AS [วันชำระล่าสุด],
    DATEDIFF(day, o.LAST_REPAY_DATE, @snap)                AS [ไม่จ่ายมากี่วัน],
    -- ── ประวัติติดตามหนี้ ──
    dc.N_CONTACT                                           AS [จำนวนครั้งที่ติดตาม],
    dc.LAST_CONTACT                                        AS [ติดตามครั้งล่าสุด],
    -- ── ช่องทางที่ขายเครื่อง ──
    sp.PARTNER_NAME                                        AS [ร้านที่ขาย],
    ct.PROJECT_TYPE                                        AS [สายผลิตภัณฑ์],

    -- ═══ ส่วนที่ 3 : คอลัมน์ตรวจสอบ ════════════════════════════════════
    cd.LAST_DUE                                            AS [งวดสุดท้ายครบกำหนด],
    cd.N_PASTDUE                                           AS [ค้างจริงจากการ์ด],
    TRY_CAST(o.NUMBER_OF_OD_INSTALLMENT AS int)            AS [OD_ที่ระบบนับ],
    o.OD_AMOUNT                                            AS [ค่าเช่าซื้อค้าง_ระบบ],
    CAST(o.OD_AMOUNT + o.PENALTY_AMT
         + o.COLLECT_AMT AS decimal(12,2))                 AS [รวม_ระบบ],
    o.CONTRACT_STATUS_DESC                                 AS [สถานะปัจจุบัน],
    CASE WHEN cd.N_PASTDUE >= 6 AND cd.LAST_DUE < @snap THEN N'A+B'
         WHEN cd.N_PASTDUE >= 6                          THEN N'A'
         WHEN h.CONTRACT_ID IS NOT NULL                  THEN N'A (ระบบ)'
         ELSE N'B' END                                     AS [เกณฑ์],
    LTRIM(
      CASE WHEN cd.LAST_DUE < @snap
           THEN N'หมดสัญญาตั้งแต่ '
              + CASE MONTH(cd.LAST_DUE)
                  WHEN 1  THEN N'ม.ค.'  WHEN 2  THEN N'ก.พ.'  WHEN 3  THEN N'มี.ค.'
                  WHEN 4  THEN N'เม.ย.' WHEN 5  THEN N'พ.ค.'  WHEN 6  THEN N'มิ.ย.'
                  WHEN 7  THEN N'ก.ค.'  WHEN 8  THEN N'ส.ค.'  WHEN 9  THEN N'ก.ย.'
                  WHEN 10 THEN N'ต.ค.'  WHEN 11 THEN N'พ.ย.'  ELSE N'ธ.ค.' END
              + N' ' + CAST(YEAR(cd.LAST_DUE) + 543 AS nvarchar(4))
              + N' (' + CAST(DATEDIFF(day, cd.LAST_DUE, @snap) AS nvarchar(6)) + N' วัน)'
           ELSE N'' END
      + CASE WHEN cd.N_PASTDUE <> TRY_CAST(o.NUMBER_OF_OD_INSTALLMENT AS int)
             THEN N' · ระบบนับ OD ' + o.NUMBER_OF_OD_INSTALLMENT
                + N' แต่การ์ดค้าง ' + CAST(cd.N_PASTDUE AS nvarchar(4)) + N' งวด'
             ELSE N'' END
      + CASE WHEN cd.N_PASTDUE < 6 AND h.CONTRACT_ID IS NOT NULL
             THEN N' · เลี้ยง OD' ELSE N'' END
      + CASE WHEN g.GUAR_ID IS NOT NULL THEN N' · มีผู้ค้ำ' ELSE N'' END
    )                                                      AS [หมายเหตุ]

FROM CONTRACT ct
JOIN snap    o  ON o.CONTRACT_ID  = ct.CONTRACT_ID
JOIN card    cd ON cd.CONTRACT_ID = ct.CONTRACT_ID
JOIN PERSON  p  ON p.PERSON_ID    = ct.PERSON_ID
JOIN PRODUCT pr ON pr.PRODUCT_ID  = ct.PRODUDCT_ID          -- PRODUDCT_ID สะกดผิดในฐานจริง
LEFT JOIN MT_PREFIX     pf  ON pf.Prefix_ID    = p.PREFIX
LEFT JOIN MT_BRAND      b   ON b.BRAND_ID      = pr.PRODUCT_BAND
LEFT JOIN MT_CATEGORY   cat ON cat.CATEGORY_ID = pr.PRODUCT_CATEGORY
LEFT JOIN MT_OCCUPATION ocp ON CAST(ocp.Ocpt_ID AS nvarchar(20)) = p.OCCUPATION_CODE
LEFT JOIN SETUP_PARTNER sp  ON sp.PARTNER_ID   = ct.PARTNER_ID
LEFT JOIN ADDRESS a         ON a.PERSON_ID     = ct.PERSON_ID
LEFT JOIN MT_PROVINCE prov1 ON prov1.PROVINCE_ID = TRY_CAST(a.A1_PROVINCE AS int)
LEFT JOIN MT_PROVINCE prov2 ON prov2.PROVINCE_ID = TRY_CAST(a.A2_PROVINCE AS int)
LEFT JOIN od6    ON od6.CONTRACT_ID = ct.CONTRACT_ID
LEFT JOIN odlast ol ON ol.CONTRACT_ID = ct.CONTRACT_ID
LEFT JOIN hit6sys h ON h.CONTRACT_ID  = ct.CONTRACT_ID
-- ผู้ค้ำ: join ผ่าน APP_ID เพราะ CONTRACT_ID ว่าง 91% (มี index บน APP_ID)
OUTER APPLY (SELECT TOP 1 * FROM GUARANTOR gg
             WHERE gg.APP_ID = ct.APP_ID OR gg.CONTRACT_ID = ct.CONTRACT_ID) g
-- ประวัติติดตาม: join ด้วย CONTARCT_NUMBER (สะกดผิด) เพราะมี index
OUTER APPLY (SELECT COUNT(*) AS N_CONTACT, MAX(d.CreateDate) AS LAST_CONTACT
             FROM CONTACT_DEBT_COLLECTION d
             WHERE d.CONTARCT_NUMBER = ct.CONTRACT_NUMBER) dc
-- ที่อยู่ตามทะเบียนบ้าน (A1)
OUTER APPLY (SELECT
    LTRIM(CONCAT_WS(N' ',
        NULLIF(N'เลขที่ '           + NULLIF(a.A1_NO,       N''), N'เลขที่ '),
        NULLIF(N'หมู่ที่ '          + NULLIF(a.A1_MOI,      N''), N'หมู่ที่ '),
        NULLIF(N'หมู่บ้าน/โครงการ ' + NULLIF(a.A1_VILLAGE,  N''), N'หมู่บ้าน/โครงการ '),
        NULLIF(N'อาคาร '            + NULLIF(a.A1_BUILDING, N''), N'อาคาร '),
        NULLIF(N'ชั้น '             + NULLIF(a.A1_FLOOR,    N''), N'ชั้น '),
        NULLIF(N'ซอย '              + NULLIF(a.A1_SOI,      N''), N'ซอย '),
        NULLIF(N'ถนน '              + NULLIF(a.A1_ROAD,     N''), N'ถนน '),
        NULLIF(N'เลขที่ห้อง '       + NULLIF(a.A1_ROOM_NO,  N''), N'เลขที่ห้อง '))) AS LINE1,
    CONCAT_WS(N' ', NULLIF(N'ตำบล'  + ISNULL(s1.SUB_DISTRICT_NAME, N''), N'ตำบล'),
                    NULLIF(N'อำเภอ' + ISNULL(d1.DISTRICT_NAME,     N''), N'อำเภอ')) AS LINE2
    FROM (SELECT 1 x) z
    LEFT JOIN MT_SUB_DISTRICT s1 ON s1.SUB_DISTRICT_ID = a.A1_SUBDISTRICT
    LEFT JOIN MT_DISTRICT     d1 ON d1.DISTRICT_ID     = a.A1_DISTRICT) a1
-- ที่อยู่ปัจจุบัน (A2)
OUTER APPLY (SELECT
    LTRIM(CONCAT_WS(N' ',
        NULLIF(N'เลขที่ '           + NULLIF(a.A2_NO,       N''), N'เลขที่ '),
        NULLIF(N'หมู่ที่ '          + NULLIF(a.A2_MOI,      N''), N'หมู่ที่ '),
        NULLIF(N'หมู่บ้าน/โครงการ ' + NULLIF(a.A2_VILLAGE,  N''), N'หมู่บ้าน/โครงการ '),
        NULLIF(N'ซอย '              + NULLIF(a.A2_SOI,      N''), N'ซอย '),
        NULLIF(N'ถนน '              + NULLIF(a.A2_ROAD,     N''), N'ถนน '))) AS LINE1,
    CONCAT_WS(N' ', NULLIF(N'ตำบล'  + ISNULL(s2.SUB_DISTRICT_NAME, N''), N'ตำบล'),
                    NULLIF(N'อำเภอ' + ISNULL(d2.DISTRICT_NAME,     N''), N'อำเภอ')) AS LINE2
    FROM (SELECT 1 x) z
    LEFT JOIN MT_SUB_DISTRICT s2 ON s2.SUB_DISTRICT_ID = a.A2_SUBDISTRICT
    LEFT JOIN MT_DISTRICT     d2 ON d2.DISTRICT_ID     = a.A2_DISTRICT) a2
WHERE o.OD_AMOUNT > 0                                       -- ยังมียอดค้างจริง
  AND o.CONTRACT_STATUS NOT IN (54,56,62,63)                -- ตัดคนที่บอกเลิก/ขายหนี้/write off แล้ว
  AND (
        cd.N_PASTDUE >= 6                                   -- เกณฑ์ A: ค้างจริงครบ 6 งวด
     OR h.CONTRACT_ID IS NOT NULL                           -- เกณฑ์ A: หรือระบบเคยนับครบ 6
     OR (cd.LAST_DUE < @snap AND cd.N_UNPAID > 0
         AND o.CONTRACT_STATUS = 48)                        -- เกณฑ์ B: หมดสัญญาแล้วยังค้าง
      )
ORDER BY [เกณฑ์], cd.LAST_DUE, ct.CONTRACT_NUMBER;
