SELECT      aa.OpenedDate, aa.ClosedDate, aa.Branch AS Branch_ID, aa.BranchType, aa.BranchName, REPLACE(REPLACE(REPLACE(REPLACE(aa.BranchName, N'ปิด', ''), N'ยกเลิก', ''), 
                      N'ว่าง', ''), 'close', '') AS CleanBranchName, aa.Address, aa.Province_EN, aa.SALE_CHANNEL, aa.SHOP_BRAND, aa.SHOP_TYPE, aa.SHOP_TYPE_BRAND, 
                      aa.CLEAN_PROVINCE, aa.BRANCH_STATUS, b.Region_EN, b.Province_TH, b.Region_TH
FROM          (SELECT      OpenedDate, ClosedDate, Branch, BranchType, BranchName, Address, Province AS Province_EN, CASE WHEN a.BranchType = 'Online' OR
                                              a.BranchType = 'Ecommerce' THEN 'Online' ELSE 'Physical' END AS SALE_CHANNEL, CASE WHEN a.BranchType LIKE '%Banana%' OR
                                              a.BranchType LIKE '%BNN%' THEN 'BaNANA' WHEN a.BranchType LIKE '%BN Sure%' THEN 'BaNANA Sure' WHEN a.BranchType IS NULL 
                                              THEN 'NA' ELSE a.BranchType END AS SHOP_BRAND, CASE WHEN a.[Address] LIKE N'%เซ็นทรัล%' OR
                                              a.[Address] LIKE N'%เซนทรัล%' OR
                                              a.[Address] LIKE '%Central%' THEN 'In Mall' WHEN a.[Address] LIKE N'%โรบินสัน%' THEN 'In Mall' WHEN a.[Address] LIKE N'%พันธุ์ทิพ%' OR
                                              a.[Address] LIKE '%panthip%' THEN 'In Mall' WHEN a.[Address] LIKE N'%เซียร์%' OR
                                              a.[Address] LIKE '%zeer%' THEN 'In Mall' WHEN a.[Address] LIKE N'%ตึกคอม%' THEN 'In Mall' WHEN a.[Address] LIKE N'%ฟอร์จูน%' OR
                                              a.[Address] LIKE '%fortune%' THEN 'In Mall' WHEN a.[Address] LIKE N'%เสรีเซ็นเตอร์%' THEN 'In Mall' WHEN a.[Address] LIKE N'%โลตัส%' OR
                                              a.[Address] LIKE '%lotus%' THEN 'In Mall' WHEN a.[Address] LIKE N'%แพชชั่น ช้อปปิ้ง%' THEN 'In Mall' WHEN a.[Address] LIKE N'%ฮาร์เบอร์มอลล์%' OR
                                              a.[Address] LIKE '%habour mall%' THEN 'In Mall' WHEN a.[Address] LIKE N'%ไอทีมอลล์%' OR
                                              a.[Address] LIKE '%it mall%' THEN 'In Mall' WHEN a.[Address] LIKE N'%พาราไดซ์%' OR
                                              a.[Address] LIKE '%paradise%' THEN 'In Mall' WHEN a.[Address] LIKE N'%แหลมทอง%' THEN 'In Mall' WHEN a.[Address] LIKE N'%หลักสี่ พลาซ่า%' THEN 'In Mall' WHEN a.[Address]
                                               LIKE N'%ศูนย์การค้า%' THEN 'In Mall' WHEN a.[Address] LIKE N'%เดอะมอลล์%' OR
                                              a.[Address] LIKE '%the mall%' THEN 'In Mall' WHEN a.[Address] LIKE N'%ซีคอน%' OR
                                              a.[Address] LIKE '%seacon%' THEN 'In Mall' WHEN a.[Address] LIKE N'%โฮมโปร%' OR
                                              a.[Address] LIKE '%home pro%' OR
                                              a.[Address] LIKE '%homepro%' THEN 'In Mall' WHEN a.[Address] LIKE N'%แฟชั่นไอส์แลน%' OR
                                              a.[Address] LIKE '%fashion island%' OR
                                              a.[Address] LIKE '%fashionisland%' THEN 'In Mall' WHEN a.[Address] LIKE N'%บิ๊กซี%' OR
                                              a.[Address] LIKE '%bigc%' OR
                                              a.[Address] LIKE '%big c%' THEN 'In Mall' WHEN a.[Address] LIKE N'%ฟิวเจอร์พาร์ค%' OR
                                              a.[Address] LIKE '%futurepark%' OR
                                              a.[Address] LIKE '%future park%' THEN 'In Mall' WHEN a.[Address] LIKE N'%ไอทีพลาซ่า%' OR
                                              a.[Address] LIKE '%itplaza%' OR
                                              a.[Address] LIKE '%it plaza%' THEN 'In Mall' WHEN a.[Address] LIKE N'%เมกะ บางนา%' OR
                                              a.[Address] LIKE '%mega bangna%' OR
                                              a.[Address] LIKE '%megabangna%' THEN 'In Mall' WHEN a.[Address] LIKE N'%สยามดิสคัพเวอร์รี่%' THEN 'In Mall' WHEN a.[Address] LIKE N'%พารากอน%' THEN 'In Mall' WHEN
                                               a.[Address] LIKE N'%เทอร์มินอล%' THEN 'In Mall' WHEN a.[Address] LIKE N'%อิมพีเรียล%' THEN 'In Mall' WHEN a.[Address] LIKE N'%มาบุญครอง%' THEN 'In Mall' WHEN a.[Address]
                                               LIKE N'%เมญ่า%' THEN 'In Mall' WHEN a.[Address] LIKE N'%เมเจอร์%' THEN 'In Mall' WHEN a.[Address] LIKE N'%เอ็มควอเทีย%' THEN 'In Mall' WHEN a.[Address] LIKE N'%เสามย่าน มิตรทาวน์%'
                                               THEN 'In Mall' WHEN a.[Address] LIKE N'%เท็อปส์%' THEN 'In Mall' WHEN a.[Address] LIKE '%mall%' THEN 'In Mall' WHEN a.[Address] LIKE '%index%' THEN 'In Mall'
                                               WHEN a.[Address] LIKE '%power mall%' THEN 'In Mall' WHEN a.[Address] LIKE N'%มหาวิทยาลัย%' THEN 'In University' WHEN a.[Address] IS NULL 
                                              THEN 'NA' ELSE 'Other & Stan Alone' END AS SHOP_TYPE, CASE WHEN a.[Address] LIKE N'%เซ็นทรัล%' OR
                                              a.[Address] LIKE N'%เซนทรัล%' OR
                                              a.[Address] LIKE '%Central%' THEN 'Central' WHEN a.[Address] LIKE N'%โรบินสัน%' THEN 'Robinson' WHEN a.[Address] LIKE N'%พันธุ์ทิพ%' OR
                                              a.[Address] LIKE '%panthip%' THEN 'Panthip' WHEN a.[Address] LIKE N'%เซียร์%' OR
                                              a.[Address] LIKE '%zeer%' THEN 'Zeer' WHEN a.[Address] LIKE N'%ตึกคอม%' THEN 'TukCom' WHEN a.[Address] LIKE N'%ฟอร์จูน%' OR
                                              a.[Address] LIKE '%fortune%' THEN 'Fortune Town' WHEN a.[Address] LIKE N'%เสรีเซ็นเตอร์%' THEN 'Others' WHEN a.[Address] LIKE N'%โลตัส%' OR
                                              a.[Address] LIKE '%lotus%' THEN 'Lotus' WHEN a.[Address] LIKE N'%แพชชั่น ช้อปปิ้ง%' THEN 'Others' WHEN a.[Address] LIKE N'%ฮาร์เบอร์มอลล์%' OR
                                              a.[Address] LIKE '%habour mall%' THEN 'Others' WHEN a.[Address] LIKE N'%ไอทีมอลล์%' OR
                                              a.[Address] LIKE '%it mall%' THEN 'Others' WHEN a.[Address] LIKE N'%พาราไดซ์%' OR
                                              a.[Address] LIKE '%paradise%' THEN 'Others' WHEN a.[Address] LIKE N'%แหลมทอง%' THEN 'Others' WHEN a.[Address] LIKE N'%หลักสี่ พลาซ่า%' THEN 'Others' WHEN a.[Address]
                                               LIKE N'%ศูนย์การค้า%' THEN 'Others' WHEN a.[Address] LIKE N'%เดอะมอลล์%' OR
                                              a.[Address] LIKE '%the mall%' THEN 'The Mall' WHEN a.[Address] LIKE N'%ซีคอน%' OR
                                              a.[Address] LIKE '%seacon%' THEN 'ZeCon' WHEN a.[Address] LIKE N'%โฮมโปร%' OR
                                              a.[Address] LIKE '%home pro%' OR
                                              a.[Address] LIKE '%homepro%' THEN 'HomePro' WHEN a.[Address] LIKE N'%แฟชั่นไอส์แลน%' OR
                                              a.[Address] LIKE '%fashion island%' OR
                                              a.[Address] LIKE '%fashionisland%' THEN 'Others' WHEN a.[Address] LIKE N'%บิ๊กซี%' OR
                                              a.[Address] LIKE '%bigc%' OR
                                              a.[Address] LIKE '%big c%' THEN 'Big C' WHEN a.[Address] LIKE N'%ฟิวเจอร์พาร์ค%' OR
                                              a.[Address] LIKE '%futurepark%' OR
                                              a.[Address] LIKE '%future park%' THEN 'Others' WHEN a.[Address] LIKE N'%ไอทีพลาซ่า%' OR
                                              a.[Address] LIKE '%itplaza%' OR
                                              a.[Address] LIKE '%it plaza%' THEN 'Others' WHEN a.[Address] LIKE N'%เมกะ บางนา%' OR
                                              a.[Address] LIKE '%mega bangna%' OR
                                              a.[Address] LIKE '%megabangna%' THEN 'Others' WHEN a.[Address] LIKE N'%สยามดิสคัพเวอร์รี่%' THEN 'Others' WHEN a.[Address] LIKE N'%พารากอน%' THEN 'Siam Paragon'
                                               WHEN a.[Address] LIKE N'%เทอร์มินอล%' THEN 'Terminal 21' WHEN a.[Address] LIKE N'%อิมพีเรียล%' THEN 'Others' WHEN a.[Address] LIKE N'%มาบุญครอง%' THEN 'MBK' WHEN
                                               a.[Address] LIKE N'%เมญ่า%' THEN 'Others' WHEN a.[Address] LIKE N'%เมเจอร์%' THEN 'Major' WHEN a.[Address] LIKE N'%เอ็มควอเทีย%' THEN 'Others' WHEN a.[Address] LIKE
                                               N'%เสามย่าน มิตรทาวน์%' THEN 'Others' WHEN a.[Address] LIKE N'%เท็อปส์%' THEN 'Others' WHEN a.[Address] LIKE '%mall%' THEN 'Others' WHEN a.[Address] LIKE '%index%'
                                               THEN 'Index' WHEN a.[Address] LIKE '%power mall%' THEN 'Others' WHEN a.[Address] LIKE N'%มหาวิทยาลัย%' THEN 'In University' WHEN a.[Address] IS NULL 
                                              THEN 'NA' ELSE 'Other & Stan Alone' END AS SHOP_TYPE_BRAND, CASE WHEN a.[Address] LIKE N'%กรุงเทพมหานคร%' OR
                                              a.[Address] LIKE N'%กรุงเทพ%' OR
                                              trim(replace(a.[Address], '.', '')) LIKE N'%กทม%' OR
                                              a.[Province] LIKE N'%กรุงเทพ%' OR
                                              a.[Province] LIKE N'%BKK%' OR
                                              a.[Province] LIKE 'Bangkok' OR
                                              a.[Address] LIKE N'%พระราม 3%' THEN 'Bangkok' WHEN a.[Address] LIKE N'%กาญจนบุรี%' THEN 'Kanchanaburi' WHEN a.[Address] LIKE N'%จันทบุรี%' THEN 'Chanthaburi' WHEN
                                               a.[Address] LIKE N'%ฉะเชิงเทรา%' THEN 'Chachoengsao' WHEN a.[Address] LIKE N'%ชลบุรี%' THEN 'Chonburi' WHEN a.[Address] LIKE N'%ชัยนาท%' THEN 'Chainat' WHEN
                                               a.[Address] LIKE N'%ตราด%' THEN 'Trat' WHEN a.[Address] LIKE N'%นครนายก%' THEN 'Nakhon Nayok' WHEN a.[Address] LIKE N'%นครปฐม%' THEN 'Nakhon Pathom' WHEN
                                               a.[Address] LIKE N'%นนทบุรี%' OR
                                              a.[Address] LIKE N'%นนบุรี%' OR
                                              a.[Address] LIKE '%Nonthaburi%' OR
                                              a.Province LIKE N'%นนทบุรี%' OR
                                              a.Province LIKE N'%นนบุรี%' OR
                                              a.Province LIKE '%Nontha%' THEN 'Nonthaburi' WHEN a.[Address] LIKE N'%ลพบุรี%' THEN 'Lopburi' WHEN a.[Address] LIKE N'%กำแพงเพชร%' THEN 'Kamphaeng Phet' WHEN
                                               a.[Address] LIKE N'%เชียงราย%' THEN 'Chiang Rai' WHEN a.[Address] LIKE N'%เชียงใหม่%' THEN 'Chiang Mai' WHEN a.[Address] LIKE N'%ตาก%' THEN 'Tak' WHEN a.[Address]
                                               LIKE N'%นครสวรรค์%' THEN 'Nakhon Sawan' WHEN a.[Address] LIKE N'%น่าน%' THEN 'Nan' WHEN a.[Address] LIKE N'%พะเยา%' THEN 'Phayao' WHEN a.[Address] LIKE N'%พิจิตร%'
                                               THEN 'Phichit' WHEN a.[Address] LIKE N'%พิษณุโลก%' THEN 'Phitsanulok' WHEN a.[Address] LIKE N'%เพชรบูรณ์%' THEN 'Phetchabun' WHEN a.[Address] LIKE N'%กาฬสินธุ์%'
                                               THEN 'Kalasin' WHEN a.[Address] LIKE N'%ขอนแก่น%' OR
                                              a.[Address] LIKE '%Khon Kaen%' OR
                                              a.Province LIKE N'%ขอนแก่น%' OR
                                              a.Province LIKE '%Khon Kaen%' THEN 'Khon Kaen' WHEN a.[Address] LIKE N'%นครพนม%' THEN 'Nakhon Phanom' WHEN a.[Address] LIKE N'%นครราชสีมา%' THEN 'Nakhon Ratchasima'
                                               WHEN a.[Address] LIKE N'%บุรีรัมย์%' OR
                                              a.[Address] LIKE '%Burir%' OR
                                              a.[Province] LIKE N'%บุรีรัมย์%' OR
                                              a.[Province] LIKE '%Burir%' THEN 'Buriram' WHEN a.[Address] LIKE N'%บึงกาฬ%' THEN 'Bueng Kan' WHEN a.[Address] LIKE N'%มหาสารคาม%' THEN 'Maha Sarakham' WHEN
                                               a.[Address] LIKE N'%มุกดาหาร%' THEN 'Mukdahan' WHEN a.[Address] LIKE N'%ยโสธร%' THEN 'Yasothon' WHEN a.[Address] LIKE N'%ร้อยเอ็ด%' THEN 'Roi Et' WHEN a.[Address]
                                               LIKE N'%กระบี่%' THEN 'Krabi' WHEN a.[Address] LIKE N'%ชุมพร%' THEN 'Chumphon' WHEN a.[Address] LIKE N'%ตรัง%' THEN 'Trang' WHEN a.[Address] LIKE N'%นครศรีธรรมราช%'
                                               THEN 'Nakhon Si Thammarat' WHEN a.[Address] LIKE N'%ปัตตานี%' THEN 'Pattani' WHEN a.[Address] LIKE N'%พังงา%' THEN 'Phang Nga' WHEN a.[Address] LIKE N'%พัทลุง%'
                                               THEN 'Phatthalung' WHEN a.[Address] LIKE N'%ภูเก็ต%' THEN 'Phuket' WHEN a.[Address] LIKE N'%ยะลา%' THEN 'Yala' WHEN a.[Address] LIKE N'%ระนอง%' THEN 'Ranong'
                                               WHEN a.[Address] LIKE N'%นราธิวาส%' THEN 'Narathiwat' WHEN a.[Address] LIKE N'%สงขลา%' THEN 'Songkhla' WHEN a.[Address] LIKE N'%สตูล%' THEN 'Satun' WHEN a.[Address]
                                               LIKE N'%สุราษฎร์ธานี%' OR
                                              a.[address] LIKE N'%สุราษ%' OR
                                              a.Province LIKE 'Surat' OR
                                              a.Province LIKE N'%สุราษ%' THEN 'Surat Thani' WHEN a.[Address] LIKE N'%ชัยภูมิ%' THEN 'Chaiyaphum' WHEN a.[Address] LIKE N'%เลย%' THEN 'Loei' WHEN a.[Address]
                                               LIKE N'%ศรีสะเกษ%' THEN 'Sisaket' WHEN a.[Address] LIKE N'%สกลนคร%' THEN 'Sakon Nakhon' WHEN a.[Address] LIKE N'%สุรินทร์%' THEN 'Surin' WHEN a.[Address] LIKE
                                               N'%หนองคาย%' THEN 'Nong Khai' WHEN a.[Address] LIKE N'%หนองบัวลำภู%' THEN 'Nong Bua Lamphu' WHEN a.[Address] LIKE N'%อุดรธานี%' THEN 'Udon Thani' WHEN a.[Address]
                                               LIKE N'%อุบลราชธานี%' OR
                                              a.[Address] LIKE N'%อุบลรา%' OR
                                              a.Province LIKE '%Ubon%' OR
                                              a.Province LIKE N'%อุบล%' THEN 'Ubon Ratchathani' WHEN a.[Address] LIKE N'%อำนาจเจริญ%' THEN 'Amnat Charoen' WHEN a.[Address] LIKE N'%แพร่%' THEN 'Phrae' WHEN
                                               a.[Address] LIKE N'%แม่ฮ่องสอน%' THEN 'Mae Hong Son' WHEN a.[Address] LIKE N'%ลำปาง%' THEN 'Lampang' WHEN a.[Address] LIKE N'%ลำพูน%' THEN 'Lamphun' WHEN
                                               a.[Address] LIKE N'%สุโขทัย%q' THEN 'Sukhothai' WHEN a.[Address] LIKE N'%อุตรดิตถ์%' THEN 'Uttaradit' WHEN a.[Address] LIKE N'%อุทัยธานี%' THEN 'Uthai Thani' WHEN a.[Address]
                                               LIKE N'%ปทุมธานี%' THEN 'Pathum Thani' WHEN a.[Address] LIKE N'%ประจวบคีรีขันธ์%' OR
                                              a.[Address] LIKE N'%ประจวบ%' OR
                                              a.[Address] LIKE '%Prachuap%' OR
                                              a.[province] LIKE N'%ประจวบ%' OR
                                              a.[province] LIKE '%Prachuap%' THEN 'Prachuap Khiri Khan' WHEN a.[Address] LIKE N'%ปราจีนบุรี%' THEN 'Prachinburi' WHEN a.[Address] LIKE N'%เพชรบุรี%' OR
                                              a.[Address] LIKE '%Phetch%' OR
                                              a.[Province] LIKE N'%เพชรบุรี%' OR
                                              a.[Province] LIKE '%Phetch%' THEN 'Phetchaburi' WHEN a.[Address] LIKE N'%ระยอง%' THEN 'Rayong' WHEN a.[Address] LIKE N'%ราชบุรี%' THEN 'Ratchaburi' WHEN a.[Address]
                                               LIKE N'%สมุทรปราการ%' THEN 'Samut Prakan' WHEN a.[Address] LIKE N'%สมุทรสงคราม%' THEN 'Samut Songkhram' WHEN a.[Address] LIKE N'%สมุทรสาคร%' THEN 'Samut Sakhon'
                                               WHEN a.[Address] LIKE N'%สระบุรี%' THEN 'Saraburi' WHEN a.[Address] LIKE N'%สระแก้ว%' THEN 'Sa Kaeo' WHEN a.[Address] LIKE N'%สิงห์บุรี%' THEN 'Sing Buri' WHEN a.[Address]
                                               LIKE N'%สุพรรณบุรี%' OR
                                              a.[Address] LIKE N'%สุพรรณ%' OR
                                              a.[Address] LIKE '%Suphan%' OR
                                              a.[Province] LIKE N'%สุพรรณบุรี%' OR
                                              a.[Province] LIKE N'%สุพรรณ%' OR
                                              a.[Province] LIKE '%Suphan%' THEN 'Suphan Buri' WHEN a.[Address] LIKE N'%อ่างทอง%' THEN 'Ang Thong' WHEN a.[Address] LIKE N'%พระนครศรีอยุธยา%' OR
                                              a.[Address] LIKE '%Ayutth%' OR
                                              a.[Address] LIKE N'%อยุธยา%' OR
                                              a.[Address] LIKE N'%พระนครศรีอยุธยา%' OR
                                              a.[Province] LIKE '%Ayutth%' OR
                                              a.[Province] LIKE N'%อยุธยา%' THEN 'Phra Nakhon Si Ayutthaya' WHEN a.[Address] IS NULL OR
                                              trim(a.[Address]) = '' OR
                                              trim(a.[Address]) = '-' THEN 'Empty' ELSE 'NA' END AS CLEAN_PROVINCE, CASE WHEN a.ClosedDate IS NOT NULL OR
                                              trim(a.BranchName) LIKE N'%ปิด%' OR
                                              trim(a.BranchName) LIKE N'%ยกเลิก%' OR
                                              trim(a.BranchName) LIKE '%close%' OR
                                              trim(a.BranchName) LIKE N'%ว่าง%' OR
                                              trim(a.BranchName) LIKE '%-%' OR
                                              trim(a.BranchType) IS NULL THEN 'InActive' ELSE 'Active' END AS BRANCH_STATUS
                       FROM           rpt.dim_branch_itec AS a) AS aa LEFT OUTER JOIN
                      ci.thailand_map AS b ON aa.CLEAN_PROVINCE = b.Province_EN