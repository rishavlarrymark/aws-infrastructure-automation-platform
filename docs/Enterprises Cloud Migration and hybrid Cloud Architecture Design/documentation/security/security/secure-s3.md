<!--
DOC TYPE: Security Design
PHASE: Storage Security Foundation
DAY: 6
SERVICE: Amazon S3 (Simulated via LocalStack)
PURPOSE: Secure-by-default S3 bucket design (encryption, versioning, public access block)
READ MODE: READ
-->




## Secure S3 Infrastructure (LocalStack + Terraform)

### Objective
Build a secure-by-default S3 bucket using Terraform and validate it locally with LocalStack,
without using any real AWS resources.

---

### Execution Summary
A secure S3 bucket was implemented as part of the cloud infrastructure engine.
Core security controls were enforced directly in Terraform and validated in a local AWS-like environment.

---

### What Was Implemented
* S3 bucket created using a reusable Terraform module
* Server-side encryption enabled using AES256
* Bucket versioning enabled for data protection
* All public access explicitly blocked
* Integrated with dev environment using LocalStack

---

### Issues Faced & Fixes

**Issue 1: Terraform AWS Provider v6 Breaking Changes**  
* Issue: Terraform plan/apply failed after provider upgrade  
* Root Cause: Deprecated arguments removed or modified in AWS provider v6  
* Fix: Updated Terraform resource definitions as per latest provider documentation  
* Learning: Provider upgrades must always be reviewed for breaking changes before applying

**Issue 2: LocalStack Connection Failure (Port 4566)**  
* Issue: Terraform unable to reach AWS service endpoints  
* Root Cause: LocalStack Docker container was not running  
* Fix: Started LocalStack container and verified service health endpoint  
* Learning: Always confirm LocalStack is running before executing Terraform

---

### Outcome
* Secure S3 bucket provisioned successfully
* All security controls enforced via Terraform code
* Terraform apply completed cleanly in LocalStack

---

### Status
* Secure S3 module complete
* Ready for IAM access control implementation (Day 7)


