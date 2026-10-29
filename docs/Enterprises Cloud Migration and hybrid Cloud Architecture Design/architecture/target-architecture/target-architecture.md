# Target Architecture

## 1. Purpose

This document defines the proposed target architecture for the **Enterprise Cloud Migration and Hybrid Architecture Design** project.

The architecture is designed for migrating an existing on-premises three-tier enterprise application to a hybrid cloud environment, with **AWS as the primary cloud platform**. The design focuses on scalability, security, high availability, disaster recovery, operational visibility, and cost-aware cloud adoption.

> **Architecture Status:** Proposed / Reference Architecture  
> This document describes the target-state design. Components shown here should not be interpreted as fully deployed production infrastructure unless supported by implementation evidence in the repository.

---

## 2. Architecture Objectives

The target architecture is designed to achieve the following objectives:

- Support migration of an existing three-tier enterprise application.
- Establish secure connectivity between on-premises infrastructure and AWS.
- Provide highly available application infrastructure across multiple Availability Zones.
- Separate web, application, and database tiers.
- Protect workloads using identity, network, encryption, and monitoring controls.
- Support backup, disaster recovery, and multi-region recovery planning.
- Provide scalability through load balancing and Auto Scaling.
- Improve operational visibility through centralized monitoring and logging.
- Apply infrastructure automation using Terraform where applicable.
- Support cost optimization and governance through tagging, budgets, and resource management.

---

## 3. High-Level Target Architecture

```text
                         USERS
                           |
                           v
                    DNS / Route 53
                           |
                           v
                +---------------------+
                | Application Load    |
                | Balancer (ALB)      |
                +----------+----------+
                           |
              +------------+------------+
              |                         |
              v                         v
        Availability Zone A       Availability Zone B
        +---------------+         +---------------+
        | Web/App Tier  |         | Web/App Tier  |
        | EC2 / ASG     |         | EC2 / ASG     |
        +-------+-------+         +-------+-------+
                |                         |
                +------------+------------+
                             |
                             v
                    +----------------+
                    | RDS PostgreSQL |
                    | Database Tier  |
                    +----------------+
                             |
                             v
                         Amazon S3
                    Backup / Object Data


       ON-PREMISES ENVIRONMENT
                 |
                 | Site-to-Site VPN /
                 | Direct Connect
                 v
          +-------------------+
          | AWS Transit       |
          | Gateway           |
          +---------+---------+
                    |
                    v
                AWS VPC

```

## 4. Core Architecture Components

### 4.1 AWS VPC

The AWS VPC provides the primary network boundary for cloud workloads.

The VPC is logically divided into:

- Public subnets
- Private application subnets
- Private database subnets
- Route tables
- Internet Gateway
- NAT Gateway
- Security Groups
- Network ACLs

Private workloads are isolated from direct internet access wherever possible.

### 4.2 Application Load Balancer

The Application Load Balancer provides the entry point for application traffic.

Responsibilities include:

- Distributing HTTP/HTTPS requests.
- Routing traffic to healthy application instances.
- Performing health checks.
- Supporting highly available application deployment across Availability Zones.
- Providing a controlled entry point for the application tier.

### 4.3 EC2 and Auto Scaling

The application tier is hosted on Amazon EC2 instances managed through an Auto Scaling Group.

The design supports:

- Multiple application instances.
- Multi-AZ deployment.
- Automatic replacement of unhealthy instances.
- Horizontal scaling based on workload demand.
- Integration with the Application Load Balancer.

The application tier remains inside private subnets where direct inbound internet access is not required.

### 4.4 Amazon RDS

Amazon RDS for PostgreSQL represents the managed database tier.

The design provides:

- Managed database operations.
- Private database connectivity.
- Multi-AZ availability considerations.
- Automated backup capabilities.
- Controlled access from the application tier.
- Separation between application and database networks.

Database access should be restricted through security groups and least-privilege connectivity rules.

### 4.5 Amazon S3

Amazon S3 provides object storage for appropriate application data and supporting artifacts.

Potential uses include:

- Application objects.
- Backup data.
- Static assets.
- Logs or exported data.
- Migration-related storage.

Access should be controlled using IAM policies, bucket policies, encryption, and appropriate public-access restrictions.

## 5. Hybrid Connectivity

The architecture maintains connectivity between the existing on-premises environment and AWS.

The connectivity layer can use:

- AWS Site-to-Site VPN for encrypted connectivity.
- AWS Direct Connect as a dedicated connectivity option for suitable enterprise requirements.
- BGP for dynamic route exchange where applicable.
- AWS Transit Gateway for centralized network connectivity.

The final connectivity mechanism depends on business requirements, traffic volume, latency requirements, availability requirements, and cost considerations.

## 6. Security Architecture

Security is implemented as multiple control layers rather than relying on a single security mechanism.

### Identity and Access

- IAM roles and policies.
- Least-privilege access.
- MFA for privileged access.
- Role-based access control.
- Separation of administrative and workload permissions.

### Network Security

- Public/private subnet separation.
- Security Groups.
- Network ACLs.
- Network Firewall where required.
- Restricted inbound and outbound traffic.
- Private database connectivity.

### Data Protection

- Encryption at rest using AWS encryption services.
- TLS for data in transit.
- Controlled access to S3 objects.
- Managed database encryption where applicable.

### Security Monitoring

- AWS CloudTrail.
- Amazon GuardDuty.
- AWS Config.
- Amazon CloudWatch.
- Application and infrastructure logs.

## 7. High Availability

The target architecture uses multiple Availability Zones for critical application components.

The intended availability model is:

```text
                    Application Traffic
                           |
                           v
                         ALB
                      /       \
                     /         \
                    v           v
                 AZ-A         AZ-B
               EC2/ASG      EC2/ASG
                    \         /
                     \       /
                       RDS
```

## 8. Disaster Recovery and Multi-Region Design

The primary workload is designed for a multi-AZ architecture within the primary AWS Region.

For regional-level disaster recovery, a secondary AWS Region can be maintained according to the required recovery strategy.

The DR design considers:

- Database replication or backup-based recovery.
- Cross-region data protection.
- Infrastructure recreation through Terraform.
- Application deployment automation.
- DNS-based traffic recovery.
- Recovery procedures and validation.

### Target Recovery Objectives

- **RTO:** Less than 1 hour.
- **RPO:** Less than 15 minutes.

These targets are architectural objectives and require actual implementation and testing before they can be considered achieved.

---

## 9. Monitoring and Operations

The target architecture includes centralized operational visibility.

### Monitoring Areas

- EC2 CPU, memory, and disk utilization.
- Application health.
- ALB request count and target health.
- HTTP 4xx and 5xx responses.
- RDS CPU utilization and database connections.
- Network traffic.
- Application logs.
- Infrastructure logs.
- Security events.
- Availability and recovery events.

AWS CloudWatch is the primary AWS-native monitoring component, with Prometheus and Grafana considered where deeper metrics collection and visualization are required.

---

## 10. Infrastructure Automation

Terraform is used where infrastructure automation is applicable.

The intended approach includes:

```text
Terraform Configuration
        |
        v
Terraform Modules
        |
        v
Infrastructure Plan
        |
        v
Validation
        |
        v
Controlled Deployment
        |
        v
AWS Infrastructure
```
