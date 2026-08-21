AWS Skill Bulider
# Module 2 Compute
## Amazon EC2
 Amazon EC2 is more flexible, cost-effective, and faster than managing on-premises servers. It offers on-demand compute capacity that can be quickly launched, scaled, and terminated, with costs based only on active usage.


# EC2 cost
| แบบ                    | ใช้ทำอะไร                                           | จุดเด่น                                                         
| ---------------------- | -------------------------------------------------  | --------------------------------                      
| **On-Demand**          | งานทั่วไป / ทดลอง / งานที่โหลดไม่แน่นอน                |  ไม่ต้องผูกสัญญา จ่ายตามเวลาที่ใช้                              
| **Reserved Instances** | งานที่รู้ว่าจะใช้ EC2 ต่อเนื่องระยะยาว                       | **ประหยัดกว่า On-Demand**                              
| **Spot Instances**     | งานที่ยอมให้เครื่องถูกหยุดได้ เช่น Batch, Data Processing  | **ถูกมาก**                                        
| **Dedicated Hosts**    | ต้องการ **Physical Server ที่เป็นของเราโดยเฉพาะ**     | ไม่แชร์ physical host กับลูกค้ารายอื่น               
|**Savings Plans**       |งานที่ใช้ Compute ต่อเนื่องและค่อนข้างคาดการณ์ได้            | ลดค่าใช้จ่าย โดย commit การใช้จ่ายต่อชั่วโมง และยืดหยุ่นกว่า Reserved Instances
สรุป
>On-Demand ซื้อตั๋วเครื่องบินปกติ → จ่ายเมื่อใช้
>Reserved Instances  จองตั๋วล่วงหน้าระยะยาว/บินประจำ → ได้ราคาดีกว่า
>Savings Plans ซื้อแพ็กเกจการบินขั้นต่ำ > สัญญาว่าจะใช้จ่ายกับการบินอย่างน้อย X บาท → ได้ส่วนลด แต่ยืดหยุ่นว่าจะนั่งเที่ยวไหน
>Spot Instances  ตั๋วลดราคาที่นั่งว่าง → ถูกมาก แต่สายการบินอาจยกเลิก/เรียกคืนได้
>Dedicated Hosts เครืองบินส่วนตัว

# EC2 Instance Types 
- General purpose > General purpose instances provide a balanced mix of compute, memory, and networking resources. They are ideal for diverse workloads, like web services, code repositories, and when workload performance is uncertain.
- Compute optimized > Compute optimized instances are ideal for compute-intensive tasks, such as gaming servers, high performance computing (HPC), machine learning, and scientific modeling.
- Memory optimized > Memory optimized instances are used for memory-intensive tasks like processing large datasets, data analytics, and databases. They provide fast performance for memory-heavy workloads
- Accelerated computing > Accelerated computing instances use hardware accelerators, like graphics processing units (GPUs), to efficiently handle tasks, such as floating-point calculations, graphics processing, and machine learning.
- Storage optimized > Storage optimized instances are designed for workloads that require high performance for locally stored data, such as large databases, data warehousing, and I/O-intensive applications.
| Type                      | จุดเด่น                     | เหมาะกับ                                                    | สรุป     |
| ------------------------- | --------------------------| --------------------------------------------------------- |---------|
| **General Purpose**       | CPU + RAM สมดุล            | Web server, Application, Code repository                  | *สมดุล   |
| **Compute Optimized**     | CPU สูง                    | HPC, Gaming server, Scientific modeling, Batch processing  |  **CPU*  |
| **Memory Optimized**      | RAM สูง                    | Database, Big Data, Data Analytics                         | **RAM    |
| **Accelerated Computing** | GPU / Hardware accelerator| ML, AI, Graphics, HPC                                     |  GPU     |
| **Storage Optimized**     | Local storage + I/O สูง    | Large database, Data warehouse, I/O-intensive workloads    | Disk/I/O |

ตัวอย่าง
- Web application → General Purpose
- Video encoding / CPU calculation → Compute Optimized
- SAP / Redis / Large database → Memory Optimized
- Deep Learning / Computer Vision → Accelerated Computing
- High-speed local database / Elasticsearch → Storage Optimized


# HOW TO USE
- The AWS Management Console
The AWS Management Console is a web interface for managing AWS services, offering quick access to services, search functionality, and simplified workflows. With the mobile app, you monitor resources, view alarms, and check billing, supporting multiple logged-in identities at once.
> Good for : Users who prefer a visual, easy-to-use interface for managing and configuring AWS services

- AWS CLI
With the AWS CLI, you manage multiple AWS services directly from the command line across Windows, macOS, and Linux. You can automate tasks through scripts, such as launching EC2 instances.
> Good for: Advanced users and developers who need to automate tasks, script actions, and manage AWS resources efficiently from the command line\

- The AWS SDK
The AWS SDK simplifies integrating AWS services into your applications by providing APIs for various programming languages. AWS offers documentation and sample code for languages like C++, Java, and .NET to help you get started.
> Good for: Developers looking to integrate AWS services into their applications using language-specific APIs


# Amazon EC2 Auto Scaling
- mazon EC2 Auto Scaling automatically adjusts the number of EC2 instances based on changes in application demand, providing better availability. It offers two approaches. Dynamic scaling adjusts in real time to fluctuations in demand. Predictive scaling preemptively schedules the right number of instances based on anticipated demand.

# Elastic Load Balancing 
> กระจาย Traffic ไปยัง Sever  
> "ตำรวจจราจร"
User
  │
  ▼
 ELB
 ├── EC2 #1
 ├── EC2 #2
 └── EC2 #3
- Elastic Load Balancing (ELB) automatically distributes incoming application traffic across multiple resources, such as EC2 instances, to optimize performance and reliability. A load balancer serves as the single point of contact for all incoming web traffic to an Auto Scaling group.

# Amazon SQS 
> "เก็บงานไว้ให้ระบบมาประมวลผล"
> "กล่องคิวงาน"
Application
     │
     ▼
    SQS (รอคิว)
     │
     ▼
 Worker
- Amazon SQS is a message queuing service that facilitates reliable communication between software components. It can send, store, and receive messages at any scale, making sure messages are not lost and that other services don't need to be available for processing


# Amazon SNS
>  กระจาย Massage ไปหลายปลายทาง
> "ประกาศข่าว"
              ┌── SQS
              │
Application → SNS ── Lambda
              │
              └── Email
- Amazon SNS is a publish-subscribe service that publishers use to send messages to subscribers through SNS topics. In Amazon SNS, subscribers can include web servers, email addresses, Lambda functions, and various other endpoints. You will learn about Lambda in more detail later.

# EventBridge
> รับ Event แล้ว Route ตาม Rlue
> "ศูนย์กลางจัดการ Event"
AWS Service / Application
          │
          ▼
     EventBridge
          │
     ┌────┼────┐
     ▼    ▼    ▼
  Lambda  SQS  Step Functions
- EventBridge is a serverless service that helps connect different parts of an application using events, helping to build scalable, event-driven systems. With EventBridge, you route events from sources like custom apps, AWS services, and third-party software to other applications. EventBridge simplifies the process of receiving, filtering, transforming, and delivering events, so you can quickly build reliable applications.

# รวม Flow
                    User
                      │
                      ▼ 
                    ELB (กระจายไป เครื่องไหน)
                      │
             ┌────────┴────────┐
             ▼                 ▼
          API Server        API Server
             │
             │ Order Created
             ▼
        EventBridge (ต้องส่งงานให้ไปให้ใครทำ)
             │
      ┌──────┼─────────┐
      │      │         │
      ▼      ▼         ▼
     SQS    Lambda     SNS (ทำหน้าที่คล้ายEventBridge อาจแทนกันได้บางกรณี แต่ Event brige จะตรวจสอบ Rule ให้เองว่าจะไปไหน)
      │                │
      ▼           ┌────┼────┐
   Worker         ▼    ▼    ▼
      │          Email SQS Lambda
      ▼
  Process Order

- EventBridge = ความสามารถด้าน Routing สูงกว่า → ไม่ได้แปลว่าดีกว่าเสมอ
- SNS = Broadcast/Fan-out ง่ายกว่า และมักประหยัดกว่า (มักใช้ร่วมกับ SQS)
- ถ้าต้องการแค่ “ส่งข้อความไปหลาย Service” → SNS มักเพียงพอ 
- sns -sqS > ประกาศ → ต่อคิว → ประมวลผล
- รับ Event → ตรวจ Rule → Route ไป Service

## AWS Lambda

- Lamda is severless compute service that run code in response to events without the need to provision or manage servers. It automatically manages the underlying infrastructure, scaling resources based on the volume of requests.
