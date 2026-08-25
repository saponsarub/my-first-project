# AWS Skill Bulider
## Amazon EC2
 Amazon EC2 is more flexible, cost-effective, and faster than managing on-premises servers. It offers on-demand compute capacity that can be quickly launched, scaled, and terminated, with costs based only on active usage.


## EC2 cost
| แบบ                    | ใช้ทำอะไร                                           | จุดเด่น                                                         
| ---------------------- | -------------------------------------------------  | --------------------------------                      
| **On-Demand**          | งานทั่วไป / ทดลอง / งานที่โหลดไม่แน่นอน                |  ไม่ต้องผูกสัญญา จ่ายตามเวลาที่ใช้                              
| **Reserved Instances** | งานที่รู้ว่าจะใช้ EC2 ต่อเนื่องระยะยาว                       | **ประหยัดกว่า On-Demand**                              
| **Spot Instances**     | งานที่ยอมให้เครื่องถูกหยุดได้ เช่น Batch, Data Processing  | **ถูกมาก**                                        
| **Dedicated Hosts**    | ต้องการ **Physical Server ที่เป็นของเราโดยเฉพาะ**     | ไม่แชร์ physical host กับลูกค้ารายอื่น               
|**Savings Plans**       |งานที่ใช้ Compute ต่อเนื่องและค่อนข้างคาดการณ์ได้            | ลดค่าใช้จ่าย โดย commit การใช้จ่ายต่อชั่วโมง และยืดหยุ่นกว่า Reserved Instances
สรุป
> - On-Demand ซื้อตั๋วเครื่องบินปกติ → จ่ายเมื่อใช้
> - Reserved Instances  จองตั๋วล่วงหน้าระยะยาว/บินประจำ → ได้ราคาดีกว่า
> - Savings Plans ซื้อแพ็กเกจการบินขั้นต่ำ > สัญญาว่าจะใช้จ่ายกับการบินอย่างน้อย X บาท → ได้ส่วนลด แต่ยืดหยุ่นว่าจะนั่งเที่ยวไหน
> - Spot Instances  ตั๋วลดราคาที่นั่งว่าง → ถูกมาก แต่สายการบินอาจยกเลิก/เรียกคืนได้
> - Dedicated Hosts เครืองบินส่วนตัว

## EC2 Instance Types 
- **General purpose** > General purpose instances provide a balanced mix of compute, memory, and networking resources. They are ideal for diverse workloads, like web services, code repositories, and when workload performance is uncertain.
- **Compute optimized** > Compute optimized instances are ideal for compute-intensive tasks, such as gaming servers, high performance computing (HPC), machine learning, and scientific modeling.
- **Memory optimized** > Memory optimized instances are used for memory-intensive tasks like processing large datasets, data analytics, and databases. They provide fast performance for memory-heavy workloads
- **Accelerated computing** > Accelerated computing instances use hardware accelerators, like graphics processing units (GPUs), to efficiently handle tasks, such as floating-point calculations, graphics processing, and machine learning.
- **Storage optimized** > Storage optimized instances are designed for workloads that require high performance for locally stored data, such as large databases, data warehousing, and I/O-intensive applications.

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


## HOW TO USE
- **The AWS Management Console**
The AWS Management Console is a web interface for managing AWS services, offering quick access to services, search functionality, and simplified workflows. With the mobile app, you monitor resources, view alarms, and check billing, supporting multiple logged-in identities at once.
> Good for : Users who prefer a visual, easy-to-use interface for managing and configuring AWS services

- **AWS CLI**
With the AWS CLI, you manage multiple AWS services directly from the command line across Windows, macOS, and Linux. You can automate tasks through scripts, such as launching EC2 instances.
> Good for: Advanced users and developers who need to automate tasks, script actions, and manage AWS resources efficiently from the command line

- **The AWS SDK**
The AWS SDK simplifies integrating AWS services into your applications by providing APIs for various programming languages. AWS offers documentation and sample code for languages like C++, Java, and .NET to help you get started.
> Good for: Developers looking to integrate AWS services into their applications using language-specific APIs

## Amazon EC2 Auto Scaling
- Amazon EC2 Auto Scaling automatically adjusts the number of EC2 instances based on changes in application demand, providing better availability. It offers two approaches. Dynamic scaling adjusts in real time to fluctuations in demand. Predictive scaling preemptively schedules the right number of instances based on anticipated demand.

## Elastic Load Balancing 
> - กระจาย Traffic ไปยัง Sever  
> - ตำรวจจราจร
```
User
  │
  ▼
 ELB
 ├── EC2 #1
 ├── EC2 #2
 └── EC2 #3
 ```
- Elastic Load Balancing (ELB) automatically distributes incoming application traffic across multiple resources, such as EC2 instances, to optimize performance and reliability. A load balancer serves as the single point of contact for all incoming web traffic to an Auto Scaling group.

## Amazon SQS 
> - เก็บงานไว้ให้ระบบมาประมวลผล
> - กล่องคิวงาน
```
Application
     │
     ▼
    SQS (รอคิว)
     │
     ▼
 Worker
 ```
- Amazon SQS is a message queuing service that facilitates reliable communication between software components. It can send, store, and receive messages at any scale, making sure messages are not lost and that other services don't need to be available for processing


## Amazon SNS
> - กระจาย Massage ไปหลายปลายทาง
> - ประกาศข่าว
```
              ┌── SQS
              │
Application → SNS ── Lambda
              │
              └── Email
```
- Amazon SNS is a publish-subscribe service that publishers use to send messages to subscribers through SNS topics. In Amazon SNS, subscribers can include web servers, email addresses, Lambda functions, and various other endpoints. You will learn about Lambda in more detail later.

## EventBridge
> - รับ Event แล้ว Route ตาม Rlue
> - ศูนย์กลางจัดการ Event
```
AWS Service / Application
          │
          ▼
     EventBridge
          │
     ┌────┼────┐
     ▼    ▼    ▼
  Lambda  SQS  Step Functions
```
- EventBridge is a serverless service that helps connect different parts of an application using events, helping to build scalable, event-driven systems. With EventBridge, you route events from sources like custom apps, AWS services, and third-party software to other applications. EventBridge simplifies the process of receiving, filtering, transforming, and delivering events, so you can quickly build reliable applications.

## **รวม Flow**
```
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
```

- EventBridge = ความสามารถด้าน Routing สูงกว่า → ไม่ได้แปลว่าดีกว่าเสมอ
- SNS = Broadcast/Fan-out ง่ายกว่า และมักประหยัดกว่า (มักใช้ร่วมกับ SQS)
- ถ้าต้องการแค่ “ส่งข้อความไปหลาย Service” → SNS มักเพียงพอ 
- sns -sqS > ประกาศ → ต่อคิว → ประมวลผล
- รับ Event → ตรวจ Rule → Route ไป Service

## AWS Lambda
- Lamda is severless compute service that run code in response to events without the need to provision or manage servers. It automatically manages the underlying infrastructure, scaling resources based on the volume of requests.

## ***Containers***
## Amazon ECS
- Amazon Elastic Container Service (Amazon ECS) is a scalable container orchestration service for running and managing containers on AWS, like Docker containers. Docker is a software platform for building, testing, and deploying applications quickly.

## Amazon EKS
- Amazon Elastic Kubernetes Service (Amazon EKS) is a fully managed service for running Kubernetes on AWS. It simplifies deploying, managing, and scaling containerized applications using open-source Kubernetes, with ongoing support and updates from the broader community.

## Amazon ECR
- Amazon Elastic Container Registry (Amazon ECR) is where you can store, manage, and deploy container images. It supports container images that follow the Open Container Initiative (OCI) standards. You can push, pull, and manage images in your Amazon ECR repositories using standard container tooling and command line interfaces (CLIs).

## Fargate
- AWS Fargate is a serverless compute engine for containers. It works with both Amazon ECS and Amazon EKS. Fargate is a container hosting platform, unlike Amazon ECS and Amazon EKS, which are both container orchestration services. When using Fargate, you do not need to provision or manage servers. Fargate manages your server infrastructure for you. You can focus more on innovating and developing your applications, and you pay only for the resources that are required to run your containers.

## **Other service**

## Elastic Beanstalk
- Elastic Beanstalk is a fully managed service that streamlines the deployment, management, and scaling of web applications. Developers can upload their code, and Elastic Beanstalk automatically handles the provisioning of infrastructure, scaling, load balancing, and application health monitoring. It supports various programming languages and frameworks, such as Java, .NET, Python, Node.js, Docker, and more. It provides full control over the underlying AWS resources while automating many operational tasks.

> Good for: Deploying and managing web applications, RESTful APIs, mobile backend services, and microservices architectures, with automated scaling and simplified infrastructure management

## AWS Batch
- AWS Batch is a fully managed service that you can use to run batch computing workloads on AWS. It automatically schedules, manages, and scales compute resources for batch jobs, optimizing resource allocation based on job requirements.

> Good for: Processing large-scale, parallel workloads in areas like scientific computing, financial risk analysis, media transcoding, big data processing, machine learning training, and genomics research

## Lightsail
- Amazon Lightsail is a cloud service offering virtual private servers (VPSs), storage, databases, and networking at a predictable monthly price. It’s ideal for small businesses, basic workloads, and developers seeking a straightforward AWS experience without the complexity of the full AWS Management Console.

> Good for: Basic web applications, low-traffic websites, development and testing environments, small business websites, blogs, and learning cloud services

## Outposts
- AWS Outposts is a fully managed hybrid cloud solution that extends AWS infrastructure and services to on-premises data centers. It provides a consistent experience between on premises and the AWS Cloud, offering compute, storage, and networking components.
> Good for: Low-latency applications, data processing in remote locations, migrating and modernizing legacy applications, and meeting regulatory compliance or data residency requirements

## **Region**
## Key considerations when choosing Regions 
### Compliance
    Compliance is an important consideration when selecting Regions for deploying business resources. Different geographical locations have varying regulatory requirements and data protection laws that organizations must follow. For example, the General Data Protection Regulation (GDPR) is designed to protect the personal data and privacy of individuals within the European Union (EU). An online retail company operating in the EU would be required to meet GDPR compliance to protect customer data. GDPR compliance includes obtaining proper consent for data collection and providing mechanisms for data access and deletion.
### Proximity
    When selecting a Region, you also want to consider how to achieve low latency for your users. Regions closer to your user base minimize data travel time, which reduces latency and enhances application responsiveness. Choosing a Region or set of Regions farther away from customers could introduce delays, which might impact user satisfaction and overall system efficiency.
### Feature availability
    You also want to consider which specific features and services are available in each Region. AWS is constantly expanding features and services to multiple locations, but not all Regions contain all AWS offerings. For example, AWS GovCloud Regions are specifically designed to meet the compliance and security requirements of US government agencies and their contractors. These Regions have stringent physical, operational, and personnel security controls in place. These controls are only available in specific Regions to meet certain governmental regulatory requirements.
### Pricing
    When selecting a Region, pricing is also a factor that can influence your decision. Some Regions have lower operational costs than others. These operational costs can impact the overall expenses for hosting applications and services. Tax laws and regulations can also play a role in cost. Some Regions might offer tax incentives or have lower tax rates, which can affect customer pricing. Additionally, data sovereignty laws in certain Regions might require data to be stored locally, affecting both compliance and cost.

## CloudFormation
- CloudFormation is a service that helps you model and set up your AWS resources so that you can spend less time managing those resources and more time focusing on your applications that run in AWS. With CloudFormation, you can define your infrastructure as code. You create a template that describes all the AWS resources that you want (like Amazon Elastic Compute Cloud (Amazon EC2) instances), and CloudFormation takes care of provisioning and configuring those resources for you.

## AWS Regions
- Regions are geographical areas around the world that are made up of multiple data centers. These data centers provide scalable and redundant infrastructure for hosting cloud services. Each Region consists of multiple, isolated locations known as Availability Zones. Each Region has three or more Availability Zones.

## Availability Zones
- Availability Zones are distinct locations within a Region, each designed as an independent zone with its own power, networking, and connectivity. Availability Zones maintain high availability and fault tolerance for applications. Each Availability Zones consists of one or more data centers.

## Edge locations
- Edge locations are strategically placed sites around the world that cache content to deliver data, video, and applications with lower latency and higher transfer speeds. Edge locations are considered a vital part of the AWS content delivery network (CDN) and use services like CloudFront to efficiently distribute data to end users.
  
## ***Connection***
## AWS Client VPN
- AWS Client VPN is a networking service you can use to connect your remote workers and on-premises networks to the cloud. It is a fully managed, elastic VPN service that automatically scales up or down based on user demand. Because it is a cloud VPN solution, you don’t need to install and manage hardware or try to estimate how many remote users to support at one time.
> Benefits: AWS Client VPN provides advanced authentication, remote access. It is elastic and fully managed
> Use case: It can be used to quickly scale remote-worker access.

## AWS Site-to-Site VPN
- Site-to-Site VPN creates a secure connection between your data center or branch offices and your AWS Cloud resources.
> Benefits: Site-to-Site VPN provides high availability, secure and private sessions, and accelerates applications.
> Use cases: It can be used for application migration and secure communication between remote locations.

## AWS PrivateLink
- AWS PrivateLink is a highly available, scalable technology that you can use to privately connect your VPC to services and resources as if they were in your VPC. You do not need to use an internet gateway, NAT device, public IP address, Direct Connect connection, or AWS Site-to-Site VPN connection to allow communication with AWS services or resources from your private subnets. Instead, you control the specific API endpoints, sites, services, and resources that are reachable from your VPC.
> Benefits: AWS PrivateLink helps you secure your traffic and connect with simplified management rules.
> Use case: It is used for connecting your clients in your VPC to resources, other VPCs, and endpoints.

## AWS Direct Connect
- Direct Connect is a service that makes it possible for you to establish a dedicated private connection between your network and VPC in the AWS Cloud.
> Benefits: AWS Direct Connect reduces network costs and increases amount of bandwidth.

## ***Additional gateway services***

## AWS Transit Gateway 
- is used to connect your Amazon VPCs and on-premises networks through a central hub. As your cloud infrastructure expands globally, inter-Region peering connects transit gateways together using the AWS Global Infrastructure.

## NAT gateway
- A NAT gateway is a NAT service. You can use a NAT gateway so that instances in a private subnet can connect to services outside your VPC but external services can't initiate a connection with those instances.

## API gateway
- The Amazon API Gateway is an AWS service for creating, publishing, maintaining, monitoring, and securing APIs at any scale. 



