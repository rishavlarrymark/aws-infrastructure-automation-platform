
# Terraform Conventions

## 1. File Naming

- main.tf: resources and module calls
- variables.tf: input variables
- outputs.tf: exported values
- versions.tf: Terraform and provider requirements
- providers.tf: provider configuration
- terraform.tfvars.example: example configuration only

## 2. Naming

- Use lowercase snake_case for Terraform identifiers.
- Use descriptive resource and module names.
- Use a consistent project prefix for AWS resource names.
- Use tags consistently wherever the AWS resource supports them.

## 3. Module Responsibilities

- vpc: network infrastructure
- iam: roles, policies, and instance profiles
- s3: application storage
- ec2: application compute configuration
- alb: load balancer, listener, and target group
- rds: PostgreSQL database infrastructure

## 4. Environment Separation

- dev: development and initial integration
- stage: pre-production validation
- prod: controlled production deployment

Each environment must have an explicitly managed state boundary.
Production must not share state with development.

## 5. Security

- Never commit secrets or real credentials.
- Prefer IAM roles and temporary credentials.
- Restrict database access to authorized application resources.
- Review Terraform plans before applying changes.

## 6. Workflow

1. Format Terraform files.
2. Initialize the working directory.
3. Validate Terraform configuration.
4. Review the plan.
5. Apply only through the approved workflow.
