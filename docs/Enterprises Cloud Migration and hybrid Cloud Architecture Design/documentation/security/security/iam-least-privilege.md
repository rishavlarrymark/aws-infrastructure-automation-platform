<!--
DOC TYPE: Security Design
PHASE: Identity & Access Management Foundation
DAY: 7
SERVICE: AWS IAM (Simulated via LocalStack)
FOCUS: Least-Privilege Access for S3
PURPOSE: Enforce role-based IAM permissions with minimal S3 access
READ MODE: READ
-->



## IAM Least Privilege for S3

### Overview
Set up secure, role-based access to an S3 bucket using Terraform and LocalStack.
The goal was to allow only the minimum required access and avoid common IAM mistakes.

---

### Architecture

EC2
↓
IAM Role
↓
IAM Policy
↓
S3 Bucket

---

### What Was Implemented

- Created an IAM role for accessing S3 (no IAM users)
- Attached a custom IAM policy to the role
- Allowed only:
  - Listing objects in the bucket
  - Reading objects
  - Uploading objects
- Access limited to **one specific S3 bucket**
- No admin access and no wildcard permissions

---

### How Access Is Controlled

- The IAM role defines **who** can access S3
- The IAM policy defines **what** actions are allowed
- The policy is attached to the role to activate access
- Anything not allowed in the policy is automatically denied

---

### Security Highlights

- No public access
- No hard-coded AWS credentials
- No hard-coded ARNs
- Role-based access only
- Clear allow-list permissions

---

### Terraform Structure

- IAM resources: `modules/iam/`
- Environment wiring: `environments/dev/main.tf`

---

### LocalStack Issue & Fix

**Issue:** `InvalidClientTokenId` error during Terraform apply  

- **Cause:** LocalStack does not enable IAM and STS endpoints by default  
- **Fix:** IAM and STS endpoints were explicitly configured in the Terraform provider  

**Learning:**  
LocalStack IAM/STS endpoints must be configured manually.

---

### Validation

After running:

```bash
terraform apply
Confirmed:

IAM role exists

Custom IAM policy exists

Policy is attached to the role

No admin permissions present

Status
✅ IAM access working
✅ S3 secured with least privilege
➡️ Ready for compute integration (EC2 / Lambda)
