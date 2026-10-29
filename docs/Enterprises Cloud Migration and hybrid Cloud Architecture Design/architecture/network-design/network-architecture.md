# Network Design

## 1. Purpose

This document defines the proposed network architecture for the **Enterprise Cloud Migration and Hybrid Architecture Design** project.

The network design provides a structured and secure foundation for connecting AWS workloads with the existing on-premises environment while supporting scalability, high availability, security, and controlled communication.

> **Architecture Status:** Proposed / Reference Network Design  
> This document describes the target network architecture. Components should not be interpreted as production deployment unless supported by implementation and validation evidence.

---

## 2. Network Design Objectives

The network architecture is designed to:

- Provide an isolated AWS network boundary using Amazon VPC.
- Separate public-facing, application, and database workloads.
- Control traffic using routing and network security controls.
- Provide secure connectivity between AWS and on-premises infrastructure.
- Support multi-AZ application deployment.
- Provide centralized connectivity where Transit Gateway is required.
- Support secure and controlled internet access.
- Minimize unnecessary exposure of internal workloads.
- Support future expansion of workloads and network segments.

---

## 3. High-Level Network Architecture

```text
                           USERS
                              |
                              v
                            DNS
                              |
                              v
                    +-------------------+
                    | Application Load  |
                    | Balancer (ALB)    |
                    +---------+---------+
                              |
                    +---------+---------+
                    |                   |
                    v                   v
              Public Subnet       Public Subnet
                  AZ-A                 AZ-B
                    |                   |
                    +---------+---------+
                              |
                              v
                    Private Application
                         Subnets
                    +---------+---------+
                    |                   |
                    v                   v
                 EC2 / ASG           EC2 / ASG
                    |                   |
                    +---------+---------+
                              |
                              v
                       Private DB
                         Subnets
                              |
                              v
                       RDS PostgreSQL


             AWS VPC
                |
                v
        AWS Transit Gateway
                |
          +-----+------+
          |            |
          v            v
        VPN      Direct Connect
          |            |
          +-----+------+
                |
                v
        ON-PREMISES NETWORK

```

## 4. AWS VPC Architecture

Amazon VPC provides the primary network boundary for AWS workloads.

The VPC design considers:

- CIDR planning.
- Public subnets.
- Private application subnets.
- Private database subnets.
- Route tables.
- Internet Gateway.
- NAT Gateway.
- Security Groups.
- Network ACLs.
- Transit Gateway where required.

The network is logically segmented so that public-facing components are separated from internal application and database resources.

---

## 5. CIDR and Subnet Planning

CIDR planning should be performed before implementation to avoid overlapping address ranges between AWS and on-premises networks.

The design should provide sufficient address space for:

- Current workloads.
- Multiple Availability Zones.
- Application expansion.
- Database resources.
- Future VPC connectivity.
- Hybrid network routing.

A conceptual subnet structure is:

```text
AWS VPC
|
+-- Public Subnet - AZ-A
|     |
|     +-- Application Load Balancer
|
+-- Public Subnet - AZ-B
|     |
|     +-- Application Load Balancer
|
+-- Private Application Subnet - AZ-A
|     |
|     +-- EC2 / Application Workloads
|
+-- Private Application Subnet - AZ-B
|     |
|     +-- EC2 / Application Workloads
|
+-- Private Database Subnet - AZ-A
|     |
|     +-- RDS
|
+-- Private Database Subnet - AZ-B
      |
      +-- RDS

```

## 6. Public Subnet Design

Public subnets are intended for resources that require controlled connectivity through an Internet Gateway.

The primary application-facing component considered in the public subnet is the **Application Load Balancer**.

Public subnets should:

- Have routes to the Internet Gateway where required.
- Avoid hosting sensitive database workloads.
- Restrict inbound traffic through appropriate security controls.
- Be deployed across multiple Availability Zones for resilience.

## 7. Private Application Subnets

The application tier is placed in private subnets.

Typical workloads include:

- EC2 application instances.
- Auto Scaling workloads.
- Internal application services.

Private application subnets should not accept direct inbound internet traffic.

Outbound internet access, when required, can be provided through a NAT Gateway.

The intended traffic flow is:

```text
Internet
   |
   v
Internet Gateway
   |
   v
Public Subnet
   |
   v
Application Load Balancer
   |
   v
Private Application Subnet
   |
   v
EC2 / Application Tier

```

## 8. Private Database Subnets

The database tier is isolated from public network access.

Amazon RDS for PostgreSQL is considered the primary database service for the proposed architecture.

Database subnets should:

- Remain private.
- Avoid direct internet access.
- Accept application traffic only from authorized application resources.
- Use controlled route tables.
- Use Security Groups to restrict database connectivity.

The logical flow is:

```text
Application Tier
      |
      | Authorized Database Traffic
      v
Private Database Subnet
      |
      v
RDS PostgreSQL

```

## 9. Routing Architecture

Route tables control traffic between the different network segments.

The design considers separate routing requirements for:

- Public subnets.
- Private application subnets.
- Private database subnets.
- Hybrid connectivity.
- Transit Gateway connectivity.

Conceptually:

```text
Public Subnet
     |
     v
Internet Gateway
     |
  Internet


Private Application Subnet
     |
     +----> NAT Gateway ----> Internet
     |
     +----> Transit Gateway ----> On-Premises


Private Database Subnet
     |
     +----> Application Tier
     |
     +----> Required Internal Services

```

## 10. Internet Gateway

The Internet Gateway provides controlled internet connectivity for resources that require public network access.

It is primarily associated with public subnet routing.

The Internet Gateway should not be used as a mechanism for directly exposing private application or database resources.

## 11. NAT Gateway

A NAT Gateway provides outbound internet connectivity for resources located in private subnets.

Typical use cases include:

- Operating system package updates.
- Application dependency downloads.
- External API communication where required.
- Software repository access.

The NAT Gateway allows outbound connectivity without providing unsolicited inbound internet connectivity to private instances.

## 12. Hybrid Connectivity

The target architecture requires secure connectivity between AWS and the existing on-premises environment.

Potential connectivity mechanisms include:

- AWS Site-to-Site VPN.
- AWS Direct Connect architecture.
- BGP-based route exchange where applicable.
- AWS Transit Gateway.
- Appropriate route controls.

Conceptual architecture:

```text
                  AWS VPC
                     |
                     v
             Transit Gateway
                     |
              +------+------+
              |             |
              v             v
         Site-to-Site    Direct Connect
             VPN          Architecture
              |             |
              +------+------+
                     |
                     v
             On-Premises Network

The final connectivity mechanism should be selected according to:

Bandwidth requirements.
Latency requirements.
Availability requirements.
Security requirements.
Cost.
Organizational requirements.

```

## 13. Transit Gateway

AWS Transit Gateway can provide centralized connectivity between multiple VPCs and on-premises networks.

It can simplify network management by providing a centralized routing architecture.

Conceptually:

```text
                Transit Gateway
                 /     |      \
                /      |       \
               v       v        v
             VPC-A   VPC-B   On-Premises

Transit Gateway should be introduced where centralized connectivity provides a clear architectural benefit.

```

## 14. Security Groups

Security Groups provide stateful traffic controls for AWS resources.

The proposed architecture uses Security Groups to restrict communication between application layers.

Example:

```text
Internet
   |
   v
ALB Security Group
   |
   | HTTPS
   v
Application Security Group
   |
   | PostgreSQL
   v
Database Security Group

The database Security Group should allow database traffic only from authorized application resources rather than from unrestricted network ranges.

```

## 15. Network ACLs

Network ACLs provide an additional subnet-level network control layer.

They can be used to:

- Control inbound traffic.
- Control outbound traffic.
- Provide subnet-level filtering.
- Add an additional security boundary.

Security Groups and Network ACLs should be designed together rather than treated as interchangeable controls.

## 16. DNS Integration

DNS provides name resolution for application endpoints and hybrid services.

The architecture considers:

- Amazon Route 53.
- Application DNS records.
- Internal DNS requirements.
- Hybrid DNS integration where required.
- DNS-based disaster recovery or failover.

The final DNS architecture depends on application requirements and the existing on-premises DNS environment.

## 17. Network Security Principles

The network design follows these principles:

1. **Network Segmentation** – Separate public, application, and database workloads.
2. **Least Connectivity** – Allow only required communication paths.
3. **Private by Default** – Keep internal workloads in private subnets where possible.
4. **Controlled Internet Access** – Expose only components that require public connectivity.
5. **Defense in Depth** – Use routing, Security Groups, Network ACLs, and additional network controls where appropriate.
6. **Centralized Connectivity** – Use Transit Gateway where centralized network management is required.
7. **Secure Hybrid Connectivity** – Use VPN or Direct Connect according to business and technical requirements.
8. **Scalable Addressing** – Plan CIDR ranges for current and future workloads.

## 18. Network Traffic Flow

The primary application traffic flow is:

```text
User
  |
  v
DNS
  |
  v
Application Load Balancer
  |
  v
Private Application Tier
  |
  v
Private Database Tier
  |
  v
RDS PostgreSQL
```
```
On-Premises
     |
     v
VPN / Direct Connect
     |
     v
Transit Gateway
     |
     v
AWS VPC
     |
     +----> Application Tier
     |
     +----> Required AWS Services

```

## 19. Network Design Validation

Before production deployment, the network architecture should be validated for:

- CIDR overlap.
- Route correctness.
- Security Group rules.
- Network ACL rules.
- Internet connectivity.
- Private subnet isolation.
- NAT connectivity.
- Hybrid connectivity.
- DNS resolution.
- Multi-AZ routing.
- Application-to-database connectivity.
- Failure and recovery scenarios.

Validation results should be documented separately when the corresponding infrastructure is implemented and tested.

## 20. Implementation Status

This document represents the proposed target network architecture for the project.

Network components that have been implemented should be supported by Terraform configuration, screenshots, configuration evidence, or validation results in the repository where applicable.

Network components that have not been deployed or validated remain **proposed or reference architecture** and should not be represented as completed production infrastructure.
