/* =============================================================================
   K2 — รายชื่อสัญญาบอกเลิก รอบเดือน 8/2026 (รอบวันที่ 1 และ 16)
   เวอร์ชัน 3 · 2026-08-28
   แยก 2 กรณีตามที่ทีมกำหนด และคิด "ค้างชำระงวดแรก / งวดสุดท้าย" คนละแบบ

   กรณี 1 · OD6 แบบปกติ — สัญญายังไม่จบ
        ค้างงวดแรก      = งวดแรกที่ไม่มีใบเสร็จ
        ค้างงวดสุดท้าย  = งวดที่เลยกำหนดล่าสุด (ตกวันที่ 1 หรือ 16 ส.ค. 2026)

   กรณี 2 · OD6 เคสสัญญาหมดอายุไปแล้ว
        ค้างงวดแรก      = งวดแรกที่ไม่มีใบเสร็จ
        ค้างงวดสุดท้าย  = งวดสุดท้ายของสัญญา (งวด ณ วันสิ้นสุดสัญญา)

   ผลลัพธ์ครบทุกช่องของ Template จดหมายบอกเลิก

   ⚠ ตัดสัญญาที่ N_PASTDUE = 0 ออก — คือคนที่จ่ายครบหลังวัน snapshot
     snapshot ยังบอกว่าค้าง แต่การ์ดผ่อนวันนี้จ่ายครบแล้ว ยอดเรียกเก็บเป็น 0 ทุกช่อง
   ============================================================================= */

DECLARE @snap_1  date = '2026-08-03';   -- วัน refresh ของรอบวันที่ 1
DECLARE @due_1   date = '2026-08-01';
DECLARE @snap_16 date = '2026-08-18';   -- วัน refresh ของรอบวันที่ 16
DECLARE @due_16  date = '2026-08-16';
DECLARE @cut     date = '2026-08-01';   -- เส้นแบ่ง "งวดถัดไปอยู่ในอดีต" = สัญญาจบแล้ว
DECLARE @asof    date = '2026-08-18';   -- วันที่ใช้ตัดสินว่า "เลยกำหนดแล้ว"

WITH
/* 1) งวดแรกที่ยังไม่จ่าย — ถ้าจ่ายครบจะได้งวดสุดท้ายที่จ่ายแล้วแทน (กรองทิ้งทีหลัง) */
first_unpaid AS (
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
    ) x WHERE rn = 1
),

/* 2) คัดสัญญาที่เข้าเกณฑ์ + ระบุกรณี */
picked AS (
    SELECT ct.EXTRACT_DATE, ct.CONTRACT_ID, ct.CONTRACT_NUMBER, ct.PERIOD_DUE_DATE,
           ct.NUMBER_OF_OD_INSTALLMENT, ct.OD_AMOUNT, ct.PENALTY_AMT, ct.COLLECT_AMT,
           ct.TOTAL_OUTSTANDING, ct.REMAINING_OUTSTANDING,
           CASE WHEN ct.PERIOD_DUE_DATE IN (@due_1, @due_16) THEN 1 ELSE 2 END AS CASE_NO
    FROM COLLECTION_OD ct
    LEFT JOIN first_unpaid fu ON fu.CONTRACT_ID = ct.CONTRACT_ID
    WHERE fu.RECEIPT_NUMBER IS NULL
      AND ct.CONTRACT_STATUS = 48
      AND (   ( ct.EXTRACT_DATE = @snap_16 AND ct.PERIOD_DUE_DATE = @due_16 )
           OR ( ct.EXTRACT_DATE = @snap_1  AND ct.PERIOD_DUE_DATE = @due_1  )
           OR ( ct.EXTRACT_DATE = @snap_16 AND ct.PERIOD_DUE_DATE < @cut
                AND DAY(ct.PERIOD_DUE_DATE) = 16 )
           OR ( ct.EXTRACT_DATE = @snap_1  AND ct.PERIOD_DUE_DATE < @cut
                AND DAY(ct.PERIOD_DUE_DATE) = 1 ) )
),

/* 3) สรุปการ์ดผ่อนรายสัญญา — แหล่งความจริงของจำนวนงวดและยอดเงิน */
card AS (
    SELECT CONTRACT_ID,
           COUNT(*)                                                         AS N_CARD,
           MAX(INSTALL_NUM)                                                 AS LAST_INSTALL_NUM,
           MIN(DUEDATE)                                                     AS FIRST_DUE,
           MAX(DUEDATE)                                                     AS CONTRACT_LAST_DUE,
           MIN(CASE WHEN RECEIPT_NUMBER IS NULL THEN INSTALL_NUM END)       AS FIRST_UNPAID_NUM,
           MIN(CASE WHEN RECEIPT_NUMBER IS NULL THEN DUEDATE END)           AS FIRST_UNPAID_DUE,
           MAX(CASE WHEN RECEIPT_NUMBER IS NULL AND DUEDATE <= @asof
                    THEN INSTALL_NUM END)                                   AS LAST_PASTDUE_NUM,
           MAX(CASE WHEN RECEIPT_NUMBER IS NULL AND DUEDATE <= @asof
                    THEN DUEDATE END)                                       AS LAST_PASTDUE_DUE,
           SUM(CASE WHEN RECEIPT_NUMBER IS NULL AND DUEDATE <= @asof
                    THEN 1 ELSE 0 END)                                      AS N_PASTDUE,
           SUM(CASE WHEN RECEIPT_NUMBER IS NULL THEN 1 ELSE 0 END)          AS N_UNPAID,
           SUM(CASE WHEN RECEIPT_NUMBER IS NULL AND DUEDATE <= @asof
                    THEN INSTALL_AMT END)                                   AS OD_AMT_CARD,
           MAX(CASE WHEN RECEIPT_NUMBER IS NULL AND DUEDATE <= @asof
                    THEN PENALTY_AMT END)                                   AS PENALTY_CARD,
           MAX(CASE WHEN RECEIPT_NUMBER IS NULL AND DUEDATE <= @asof
                    THEN COLLECT_AMT END)                                   AS COLLECT_CARD
    FROM CUSTOMER_CARD GROUP BY CONTRACT_ID
),

/* 4) งวดที่ครบ OD6 = งวดค้างเกินกำหนดลำดับที่ 6 */
od6 AS (
    SELECT CONTRACT_ID, INSTALL_NUM AS OD6_INSTALL_NUM, DUEDATE AS OD6_DUEDATE
    FROM (
        SELECT CONTRACT_ID, INSTALL_NUM, DUEDATE,
               ROW_NUMBER() OVER (PARTITION BY CONTRACT_ID ORDER BY INSTALL_NUM) AS od_rank
        FROM CUSTOMER_CARD
        WHERE RECEIPT_NUMBER IS NULL AND DUEDATE <= @asof
    ) z WHERE od_rank = 6
)

SELECT
    /* ---------- กรณีและตัวระบุ ---------- */
      p.CASE_NO                                     AS [กรณี]
    , CASE p.CASE_NO WHEN 1 THEN N'1 · OD6 ปกติ'
                     ELSE N'2 · สัญญาหมดอายุแล้ว' END AS [ชื่อกรณี]
    , CASE WHEN DAY(p.PERIOD_DUE_DATE) = 16 THEN N'รอบวันที่ 16'
           ELSE N'รอบวันที่ 1' END                   AS [รอบ]
    , k.PERSON_ID                                   AS [รหัสลูกค้า]
    , pr.TAX_ID                                     AS [เลขบัตรประชาชน]

    /* ---------- ตาม Template จดหมายบอกเลิก ---------- */
    , p.CONTRACT_NUMBER                             AS [สัญญาเลขที่]
    , LTRIM(RTRIM(ISNULL(pf.Prefix_name, N'') + N' '
        + ISNULL(pr.FIRST_NAME, N'') + N' '
        + ISNULL(pr.LAST_NAME, N'')))               AS [ชื่อผู้ทำสัญญา]
    , k.CONTRACT_START                              AS [วันที่ทำสัญญา]
    , N'เช่าซื้อ ' + ISNULL(cat.CATEGORY_NAME, N'') AS [ประเภทสัญญา]
    , br.BRAND_NAME                                 AS [ยี่ห้อ]
    , pd.MODEL_NAME                                 AS [รุ่น/แบบ]
    , pd.MODEL_NUMBER                               AS [เครื่อง]
    , pd.SERIAL_NUMBER                              AS [Serial Number]
    , pd.HP_VAT_SUM                                 AS [ค่าเช่าซื้อรวมภาษีมูลค่าเพิ่ม]
    , pd.INSTALL_SUM                                AS [งวดละ (บาท)]
    , pd.INSTALL_NUM                                AS [จำนวนงวดเช่าซื้อ]
    , pd.FRIST_PAY_DATE                             AS [วันเริ่มชำระงวดแรก]
    , pd.DUEDATE_NUM                                AS [วันที่ชำระงวดต่อไป]

    /* ---------- ค้างชำระงวดแรก / งวดสุดท้าย — คิดตามกรณี ---------- */
    , cd.FIRST_UNPAID_NUM                           AS [ค้างชำระงวดแรก]
    , cd.FIRST_UNPAID_DUE                           AS [วันครบกำหนดงวดแรกที่ค้าง]
    , CASE WHEN p.CASE_NO = 1 THEN cd.LAST_PASTDUE_NUM
                              ELSE cd.LAST_INSTALL_NUM   END AS [ค้างชำระงวดสุดท้าย]
    , CASE WHEN p.CASE_NO = 1 THEN cd.LAST_PASTDUE_DUE
                              ELSE cd.CONTRACT_LAST_DUE  END AS [วันครบกำหนดงวดสุดท้ายที่ค้าง]

    , CASE WHEN cd.FIRST_UNPAID_NUM + 5 > cd.LAST_INSTALL_NUM
                THEN cd.LAST_INSTALL_NUM
                ELSE cd.FIRST_UNPAID_NUM + 5 END    AS [งวดที่ครบ OD 6]

    /* ---------- จำนวนเงิน ----------
       ค่างวดที่ค้าง : รวมจากการ์ดผ่อนจริง
       ค่าปรับ      : 100 บาท/งวด เพดาน 600 (OD6 ขึ้นไป)            [Fee Policy ข้อ 1]
       ค่าติดตาม    : ตัดสิน A/B จาก "ยอดค้างงวดแรก" = ค่างวด + ค่าปรับ 100
                      กรณี A  ค่างวด + 100 >  1,000 → 50,150,250,350,450
                      กรณี B  ค่างวด + 100 <= 1,000 → +100 ต่อลำดับงวดที่
                              ยอดสะสม k*(ค่างวด+100) > 1,000 · นับถึง OD5 แล้วหยุด
                      [Fee Policy ข้อ 2]
       ------------------------------------------------------------------ */
    , cd.OD_AMT_CARD                                AS [ค่าเช่าซื้อที่ค้างชำระ]

    , CAST(100 * (CASE WHEN cd.N_PASTDUE >= 6 THEN 6 ELSE cd.N_PASTDUE END)
           AS float)                                AS [ค่าเบี้ยปรับชำระล่าช้า]

    , CAST(CASE
        WHEN cd.N_PASTDUE = 0 THEN 0
        WHEN ISNULL(pd.INSTALL_SUM, 0) + 100 > 1000
             THEN CASE WHEN cd.N_PASTDUE >= 5 THEN 450
                       ELSE 50 + (cd.N_PASTDUE - 1) * 100 END
        ELSE 100 *
             CASE WHEN (CASE WHEN cd.N_PASTDUE > 5 THEN 5 ELSE cd.N_PASTDUE END)
                       - (FLOOR(1000.0 / (ISNULL(pd.INSTALL_SUM,0) + 100)) + 1) + 1 > 0
                  THEN (CASE WHEN cd.N_PASTDUE > 5 THEN 5 ELSE cd.N_PASTDUE END)
                       - (FLOOR(1000.0 / (ISNULL(pd.INSTALL_SUM,0) + 100)) + 1) + 1
                  ELSE 0 END
      END AS float)                                 AS [ค่าติดตามทวงถามหนี้]

    , CAST(0 AS float)                              AS [ค่าใช้จ่ายอื่นที่บริษัทฯ มีสิทธิเรียกเก็บ]

    , ISNULL(cd.OD_AMT_CARD,0)
      + 100 * (CASE WHEN cd.N_PASTDUE >= 6 THEN 6 ELSE cd.N_PASTDUE END)
      + CASE
          WHEN cd.N_PASTDUE = 0 THEN 0
          WHEN ISNULL(pd.INSTALL_SUM, 0) + 100 > 1000
               THEN CASE WHEN cd.N_PASTDUE >= 5 THEN 450
                         ELSE 50 + (cd.N_PASTDUE - 1) * 100 END
          ELSE 100 *
               CASE WHEN (CASE WHEN cd.N_PASTDUE > 5 THEN 5 ELSE cd.N_PASTDUE END)
                         - (FLOOR(1000.0 / (ISNULL(pd.INSTALL_SUM,0) + 100)) + 1) + 1 > 0
                    THEN (CASE WHEN cd.N_PASTDUE > 5 THEN 5 ELSE cd.N_PASTDUE END)
                         - (FLOOR(1000.0 / (ISNULL(pd.INSTALL_SUM,0) + 100)) + 1) + 1
                    ELSE 0 END
        END                                         AS [รวมเป็นเงินทั้งสิ้น]
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
                + ISNULL(N'อำเภอ' + di.DISTRICT_NAME, N''))) AS [แขวง/ตำบล/อำเภอ]
    , pv.PROVINCE_NAME                              AS [จังหวัด]
    , a.A1_POSTALCODE                               AS [รหัส ปณ.]

    /* ---------- คอลัมน์ตรวจสอบ ---------- */
    , cd.N_CARD                                     AS _งวดทั้งหมดในการ์ด
    , cd.CONTRACT_LAST_DUE                          AS _สัญญาสิ้นสุด
    , p.PERIOD_DUE_DATE                             AS _งวดถัดไปที่ระบบชี้
    , TRY_CAST(p.NUMBER_OF_OD_INSTALLMENT AS int)   AS _ระบบนับกี่งวด
    , p.OD_AMOUNT                                   AS _ยอดค้างจาก_snapshot
    , cd.OD_AMT_CARD - ISNULL(p.OD_AMOUNT,0)        AS _ผลต่างการ์ด_ลบ_snapshot
    , cd.N_UNPAID                                   AS _งวดที่ยังไม่จ่ายทั้งหมด
    , ISNULL(cd.PENALTY_CARD, 0)                    AS _ค่าปรับที่ระบบคิดไว้ในการ์ด
    , ISNULL(cd.COLLECT_CARD, 0)                    AS _ค่าติดตามที่ระบบคิดไว้ในการ์ด
    , o6.OD6_INSTALL_NUM                            AS _งวดค้างเกินกำหนดลำดับที่6
    , o6.OD6_DUEDATE                                AS _วันครบกำหนดของงวดลำดับที่6
    , pd.INSTALL_SUM                                AS _ค่างวดใช้ตัดสินกรณี_A_B
    , CASE WHEN cd.N_PASTDUE >= 6 THEN N'ค้างครบ 6 งวด'
           ELSE N'ค้าง ' + CAST(cd.N_PASTDUE AS nvarchar(5)) + N' งวด — ยังไม่ถึง 6'
      END                                           AS _สถานะตรวจสอบ

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

/* ตัดสัญญาที่ไม่เหลืองวดค้างเกินกำหนดแล้ว — จ่ายครบหลังวัน snapshot
   ยอดเรียกเก็บจะเป็น 0 ทุกช่อง ออกหนังสือไม่ได้ */
WHERE cd.N_PASTDUE > 0

ORDER BY p.CASE_NO, p.EXTRACT_DATE, cd.N_PASTDUE DESC, p.CONTRACT_NUMBER;
