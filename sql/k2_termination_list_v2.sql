/* =============================================================================
   K2 — รายชื่อสัญญาที่เข้าเกณฑ์บอกเลิก (Overdue 6)
   เวอร์ชัน 2 · 2026-08-28
   ผลลัพธ์: ครบทุกช่องของ Template จดหมายบอกเลิก + Customer number

   ตรรกะการคัดมาจาก query ของทีม แล้วเพิ่มคอลัมน์ตรวจสอบ
   - เงื่อนไข A = ค้างตามรอบปกติ (งวดล่าสุดที่ถึงกำหนดยังไม่จ่าย)
   - เงื่อนไข B = สัญญาหมดอายุแล้วแต่ยังค้าง

   ⚠️ ต้องอ่าน N_PASTDUE ก่อนออกหนังสือ — ดูหมายเหตุท้ายไฟล์
   ============================================================================= */

DECLARE @snap_1  date = '2026-08-03';   -- วัน refresh ของรอบวันที่ 1
DECLARE @due_1   date = '2026-08-01';   -- งวดที่ครบกำหนดของรอบนั้น
DECLARE @snap_16 date = '2026-08-18';   -- วัน refresh ของรอบวันที่ 16
DECLARE @due_16  date = '2026-08-16';
DECLARE @cut     date = '2026-08-01';   -- เส้นแบ่ง "งวดถัดไปอยู่ในอดีต" = สัญญาจบแล้ว

/* ---------------------------------------------------------------------------
   1) หา "งวดแรกที่ยังไม่จ่าย" ของแต่ละสัญญา
      ถ้าไม่มีงวดค้างเลย จะได้งวดสุดท้ายที่จ่ายแล้วแทน (RECEIPT_NUMBER ไม่ NULL)
      → กรองด้วย RECEIPT_NUMBER IS NULL ทีหลัง = เอาเฉพาะสัญญาที่ยังค้าง
   --------------------------------------------------------------------------- */
WITH first_unpaid AS (
    SELECT CONTRACT_ID, INSTALL_NUM, DUEDATE, RECEIPT_NUMBER
    FROM (
        SELECT CONTRACT_ID, INSTALL_NUM, DUEDATE, RECEIPT_NUMBER,
               ROW_NUMBER() OVER (
                   PARTITION BY CONTRACT_ID
                   ORDER BY CASE WHEN RECEIPT_NUMBER IS NULL THEN 0 ELSE 1 END,
                            CASE WHEN RECEIPT_NUMBER IS NULL THEN  INSTALL_NUM
                                                             ELSE -INSTALL_NUM END
               ) AS rn
        FROM CUSTOMER_CARD
    ) x
    WHERE rn = 1
),

/* ---------------------------------------------------------------------------
   2) คัดสัญญาที่เข้าเกณฑ์ จาก snapshot หนี้ค้างรายวัน
   --------------------------------------------------------------------------- */
picked AS (
    SELECT ct.EXTRACT_DATE, ct.CONTRACT_ID, ct.CONTRACT_NUMBER,
           ct.CONTRACT_STATUS, ct.CONTRACT_STATUS_DESC,
           ct.PERIOD_DUE_DATE, ct.LAST_REPAY_DATE,
           ct.NUMBER_OF_PERIOD, ct.INSTALLMENT_PER_PERIOD,
           ct.PAID_NUMBER_OF_PERIOD, ct.REMAINING_PERIOD,
           ct.TOTAL_OUTSTANDING, ct.REMAINING_OUTSTANDING,
           ct.NUMBER_OF_OD_INSTALLMENT,
           ct.OD_AMOUNT, ct.PENALTY_AMT, ct.COLLECT_AMT, ct.TOTAL_FOLLOW_UP_AMOUNT,
           ct.INVOICE_NUMBER, ct.INVOICE_DATE, ct.PRODUCT_TYPE,
           fu.INSTALL_NUM AS FIRST_UNPAID_NUM,
           fu.DUEDATE     AS FIRST_UNPAID_DUE,
           CASE WHEN ct.PERIOD_DUE_DATE IN (@due_1, @due_16)
                THEN 'A ค้างตามรอบปกติ'
                ELSE 'B สัญญาหมดอายุแล้วยังค้าง' END AS CASE_TYPE
    FROM COLLECTION_OD ct
    LEFT JOIN first_unpaid fu ON fu.CONTRACT_ID = ct.CONTRACT_ID
    WHERE fu.RECEIPT_NUMBER IS NULL          -- ยังมีงวดค้างจริง
      AND ct.CONTRACT_STATUS = 48            -- ระบบตั้งสถานะ Overdue 6
      AND (
            -- A · งวดที่เพิ่งถึงกำหนดยังไม่จ่าย
              ( ct.EXTRACT_DATE = @snap_16 AND ct.PERIOD_DUE_DATE = @due_16 )
           OR ( ct.EXTRACT_DATE = @snap_1  AND ct.PERIOD_DUE_DATE = @due_1  )
            -- B · งวดถัดไปอยู่ในอดีต = สัญญาจบแล้วแต่ยังค้าง
           OR ( ct.EXTRACT_DATE = @snap_16 AND ct.PERIOD_DUE_DATE < @cut
                AND DAY(ct.PERIOD_DUE_DATE) = 16 )
           OR ( ct.EXTRACT_DATE = @snap_1  AND ct.PERIOD_DUE_DATE < @cut
                AND DAY(ct.PERIOD_DUE_DATE) = 1 )
          )
),

/* ---------------------------------------------------------------------------
   3) นับงวดค้างจากการ์ดผ่อนจริง (ใช้ตรวจสอบ ไม่ใช่คัด)
   --------------------------------------------------------------------------- */
card AS (
    SELECT k.CONTRACT_ID,
           COUNT(*)                                                AS N_CARD,
           MIN(k.DUEDATE)                                           AS FIRST_DUE,
           MAX(k.DUEDATE)                                           AS LAST_DUE,
           SUM(CASE WHEN k.RECEIPT_NUMBER IS NULL THEN 1 ELSE 0 END) AS N_UNPAID,
           SUM(CASE WHEN k.RECEIPT_NUMBER IS NULL
                     AND k.DUEDATE <= @snap_16 THEN 1 ELSE 0 END)    AS N_PASTDUE
    FROM CUSTOMER_CARD k
    GROUP BY k.CONTRACT_ID
),

/* ---------------------------------------------------------------------------
   4) งวดที่ครบ OD6 = งวดค้างเกินกำหนดลำดับที่ 6
   --------------------------------------------------------------------------- */
od6 AS (
    SELECT CONTRACT_ID, INSTALL_NUM AS OD6_INSTALL_NUM, DUEDATE AS OD6_DUEDATE
    FROM (
        SELECT k.CONTRACT_ID, k.INSTALL_NUM, k.DUEDATE,
               ROW_NUMBER() OVER (PARTITION BY k.CONTRACT_ID ORDER BY k.INSTALL_NUM) AS od_rank
        FROM CUSTOMER_CARD k
        WHERE k.RECEIPT_NUMBER IS NULL AND k.DUEDATE <= @snap_16
    ) z
    WHERE od_rank = 6
)

/* ---------------------------------------------------------------------------
   5) ประกอบข้อมูลให้ครบตาม template
   --------------------------------------------------------------------------- */
SELECT
    /* ---------- Customer number (สิ่งที่ขอเป็นหลัก) ---------- */
      k.PERSON_ID                                   AS CUSTOMER_ID
    , pr.TAX_ID                                     AS CUSTOMER_TAX_ID
    , p.CONTRACT_NUMBER                             AS [สัญญาเลขที่]

    /* ---------- ตัวตนลูกค้า ---------- */
    , LTRIM(RTRIM(ISNULL(pf.Prefix_name, N'') + N' '
        + ISNULL(pr.FIRST_NAME, N'') + N' '
        + ISNULL(pr.LAST_NAME, N'')))               AS [ชื่อผู้ทำสัญญา]
    , pr.BIRTHDAY                                   AS [วันเกิด]

    /* ---------- สัญญา ---------- */
    , k.CONTRACT_START                              AS [วันที่ทำสัญญา]
    , N'เช่าซื้อ ' + ISNULL(cat.CATEGORY_NAME, N'') AS [ประเภทสัญญา]
    , br.BRAND_NAME                                 AS [ยี่ห้อ]
    , pd.MODEL_NAME                                 AS [รุ่น/แบบ]
    , pd.MODEL_NUMBER                               AS [เครื่อง]
    , pd.SERIAL_NUMBER                              AS [Serial Number]

    /* ---------- เงื่อนไขการเงิน ---------- */
    , pd.HP_VAT_SUM                                 AS [ค่าเช่าซื้อรวมภาษีมูลค่าเพิ่ม]
    , pd.INSTALL_SUM                                AS [งวดละ (บาท)]
    , pd.INSTALL_NUM                                AS [จำนวนงวดเช่าซื้อ]
    , pd.FRIST_PAY_DATE                             AS [วันเริ่มชำระงวดแรก]
    , pd.DUEDATE_NUM                                AS [วันที่ชำระงวดต่อไป]

    /* ---------- สถานะค้างชำระ ---------- */
    , p.FIRST_UNPAID_NUM                            AS [ค้างชำระงวดแรก]
    , o6.OD6_INSTALL_NUM                            AS [งวดที่ครบ OD 6]
    , p.OD_AMOUNT                                   AS [ค่าเช่าซื้อ 6 งวด (OD1-OD6)]
    , p.PENALTY_AMT                                 AS [ค่าเบี้ยปรับชำระล่าช้า]
    , p.COLLECT_AMT                                 AS [ค่าติดตามทวงถามหนี้]
    , CAST(0 AS float)                              AS [ค่าใช้จ่ายอื่นที่บริษัทฯ มีสิทธิเรียกเก็บ]
    , (ISNULL(p.OD_AMOUNT,0) + ISNULL(p.PENALTY_AMT,0)
       + ISNULL(p.COLLECT_AMT,0))                   AS [รวมเป็นเงินทั้งสิ้น]
    , p.EXTRACT_DATE                                AS [วันที่เป็น OD6]
    , cd.N_PASTDUE                                  AS [รวมจำนวนงวดที่ค้าง]

    /* ---------- ที่อยู่ตามทะเบียนบ้าน ---------- */
    , LTRIM(RTRIM(
        CASE WHEN NULLIF(LTRIM(RTRIM(a.A1_NO)),N'')       IS NULL THEN N'' ELSE N'เลขที่ ' + a.A1_NO + N' ' END
      + CASE WHEN NULLIF(LTRIM(RTRIM(a.A1_MOI)),N'')      IS NULL THEN N'' ELSE N'หมู่ที่ ' + a.A1_MOI + N' ' END
      + CASE WHEN NULLIF(LTRIM(RTRIM(a.A1_VILLAGE)),N'')  IS NULL THEN N'' ELSE N'หมู่บ้าน/โครงการ ' + a.A1_VILLAGE + N' ' END
      + CASE WHEN NULLIF(LTRIM(RTRIM(a.A1_BUILDING)),N'') IS NULL THEN N'' ELSE N'อาคาร ' + a.A1_BUILDING + N' ' END
      + CASE WHEN NULLIF(LTRIM(RTRIM(a.A1_FLOOR)),N'')    IS NULL THEN N'' ELSE N'ชั้น ' + a.A1_FLOOR + N' ' END
      + CASE WHEN NULLIF(LTRIM(RTRIM(a.A1_ROOM_NO)),N'')  IS NULL THEN N'' ELSE N'เลขที่ห้อง ' + a.A1_ROOM_NO + N' ' END
      + CASE WHEN NULLIF(LTRIM(RTRIM(a.A1_SOI)),N'')      IS NULL THEN N'' ELSE N'ซอย ' + a.A1_SOI + N' ' END
      + CASE WHEN NULLIF(LTRIM(RTRIM(a.A1_ROAD)),N'')     IS NULL THEN N'' ELSE N'ถนน ' + a.A1_ROAD + N' ' END
      ))                                            AS [เลขที่]
    , LTRIM(RTRIM(ISNULL(N'ตำบล' + sd.SUB_DISTRICT_NAME, N'') + N' '
                + ISNULL(N'อำเภอ' + di.DISTRICT_NAME, N'')))  AS [แขวง/ตำบล/อำเภอ]
    , pv.PROVINCE_NAME                              AS [จังหวัด]
    , a.A1_POSTALCODE                               AS [รหัส ปณ.]

    /* ---------- คอลัมน์ตรวจสอบ (ไม่ต้องส่งเข้าจดหมาย) ---------- */
    , p.CASE_TYPE                                   AS _CASE_TYPE
    , p.NUMBER_OF_OD_INSTALLMENT                    AS _OD_SYSTEM
    , cd.N_PASTDUE                                  AS _OD_CARD
    , cd.N_UNPAID                                   AS _UNPAID_TOTAL
    , cd.LAST_DUE                                   AS _CONTRACT_LAST_DUE
    , p.PERIOD_DUE_DATE                             AS _NEXT_DUE
    , DATEDIFF(month, p.PERIOD_DUE_DATE, @snap_16)  AS _MONTHS_OVERDUE
    , CASE WHEN cd.N_PASTDUE >= 6 THEN N'ครบ 6 งวด'
           ELSE N'ยังไม่ครบ 6 งวด — ต้องตรวจก่อนออกหนังสือ' END AS _CHECK

FROM       picked          p
JOIN       card            cd ON cd.CONTRACT_ID   = p.CONTRACT_ID
LEFT JOIN  od6             o6 ON o6.CONTRACT_ID   = p.CONTRACT_ID
JOIN       CONTRACT        k  ON k.CONTRACT_ID    = p.CONTRACT_ID
JOIN       PERSON          pr ON pr.PERSON_ID     = k.PERSON_ID
LEFT JOIN  MT_PREFIX       pf ON pf.Prefix_ID     = TRY_CAST(pr.PREFIX AS int)
LEFT JOIN  PRODUCT         pd ON pd.PRODUCT_ID    = k.PRODUDCT_ID
LEFT JOIN  MT_BRAND        br ON br.BRAND_ID      = TRY_CAST(pd.PRODUCT_BAND AS int)
LEFT JOIN  MT_CATEGORY     cat ON cat.CATEGORY_ID = TRY_CAST(pd.PRODUCT_CATEGORY AS int)
LEFT JOIN  ADDRESS         a  ON a.PERSON_ID      = k.PERSON_ID
LEFT JOIN  MT_PROVINCE     pv ON pv.PROVINCE_ID   = TRY_CAST(a.A1_PROVINCE AS int)
LEFT JOIN  MT_DISTRICT     di ON di.DISTRICT_ID   = TRY_CAST(a.A1_DISTRICT AS int)
LEFT JOIN  MT_SUB_DISTRICT sd ON sd.SUB_DISTRICT_ID = TRY_CAST(a.A1_SUBDISTRICT AS int)
ORDER BY p.CASE_TYPE, cd.N_PASTDUE DESC, p.CONTRACT_NUMBER;

/* =============================================================================
   หมายเหตุจากการทดสอบจริง 2026-08-28
   -----------------------------------------------------------------------------
   ผลรวม 621 สัญญา · ไม่มีสัญญาซ้ำข้าม snapshot · join ครบ 100% ทุกตาราง

     A ค้างตามรอบปกติ         465 สัญญา   (03 ส.ค. 236 · 18 ส.ค. 229)
     B สัญญาหมดอายุแล้วยังค้าง 156 สัญญา   (03 ส.ค.  75 · 18 ส.ค.  81)

   ⚠️ เงื่อนไข B ยังไม่ได้เช็ค "ค้างเกิน 6 งวด" ตามที่คอมเมนต์ในโค้ดเดิมเขียนไว้
      นับจากการ์ดผ่อนจริง:
        A → ค้างครบ 6 งวด  417 จาก 465  (89.7%)
        B → ค้างครบ 6 งวด    1 จาก 156  (0.6%)  ← ที่เหลือค้าง 1–5 งวด

      แต่ทั้ง 156 สัญญาในกลุ่ม B มีงวดสุดท้ายของสัญญาผ่านไปแล้วจริง
      คือ "สัญญาจบแล้วแต่ยังค้าง" ซึ่งเป็นคนละกรณีกับ "ค้าง 6 งวด"

   ถ้าต้องการบังคับให้ครบ 6 งวดจริง เติมท้าย WHERE:
       AND cd.N_PASTDUE >= 6            -- เหลือ 418 สัญญา
   ถ้าต้องการเฉพาะที่ค้างมาเกิน 6 เดือน:
       AND DATEDIFF(month, p.PERIOD_DUE_DATE, @snap_16) >= 6   -- เหลือ 5 สัญญา
   ============================================================================= */
