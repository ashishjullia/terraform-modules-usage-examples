# HIPAA-Aware Secure Backend API Deployment on AWS using Terraform/

This repository contains Terraform code to provision a secure infrastructure on AWS for a backend service aligning with HIPAA best practices.

## Architecture Overview

The infrastructure consists of the following core components, managed by Terraform modules:

1.  **VPC (`vpc`, `vpc_endpoint`):** A custom Virtual Private Cloud (VPC) spanning two Availability Zones (AZs) with separate public and private subnets for network isolation. VPC Endpoints are configured for necessary AWS services (like ECR, Secrets Manager, CloudWatch Logs) to ensure private communication.
2.  **RDS (`rds`):** A PostgreSQL database instance deployed in the private subnets. It is configured with:
    * Encryption at rest using AWS Key Management Service (KMS).
    * Automated backups enabled.
    * Multi-AZ deployment for high availability.
    * Performance Insights enabled for monitoring.
3.  **ECS (`ecs`, `ecr`):** An Elastic Container Service (ECS) cluster running a sample backend API (Node) as a Fargate service within the private subnets. Elastic Container Registry (ECR) is used to store the container image.
4.  **Load Balancer (`load_balancer`, `acm`, `cloudflare`):** An Application Load Balancer (ALB) deployed in the public subnets to expose the backend service securely over HTTPS only. AWS Certificate Manager (`acm`) is used to provision the TLS certificate. Cloudflare is used for automatic DNS management. The ALB enforces TLS 1.2.
5.  **Secrets Manager (`secretsmanager`):** Used to securely store and manage database credentials and can be used potentially for future sensitive API keys or sensitive data in general.
6.  **CloudWatch & SNS (`cloudwatch_alarm`, `sns`):** Basic CloudWatch Logs and Alarms are set up for monitoring the ECS service and RDS database. SNS topics are configured for alarm notifications.
7.  **IAM (`iam`):** Minimal, least-privilege IAM roles and policies are created for the ECS task, RDS database access, and other services.


## Project Structure

```
.
├── README.md
├── backend.tf
├── dev.tfvars
├── main.tf
├── modules
│   ├── acm
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── cloudflare
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   ├── providers.tf
│   │   └── variables.tf
│   ├── cloudwatch_alarm
│   │   ├── main.tf
│   │   └── variables.tf
│   ├── ecr
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── ecs
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── iam
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── load_balancer
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── rds
│   │   ├── intermediate
│   │   │   ├── build
│   │   │   │   ├── index.js  # Lambda for IAM DB user setup
│   │   │   │   ├── package-lock.json
│   │   │   │   ├── package.json
│   │   │   │   └── package_lambda.sh # Script to build Lambda package
│   │   │   └── to_upload # Potentially for zipped Lambda artifact
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── secretsmanager
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── sns
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── vpc
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   └── vpc_endpoint
│       ├── main.tf
│       ├── outputs.tf
│       └── variables.tf
├── outputs.tf
├── providers.tf
└── variables.tf
```

## HIPAA Considerations Implemented

This infrastructure addresses several HIPAA requirements:

* **Encryption at Rest:**
    * RDS database is encrypted using AWS KMS (managed via `rds` module).
    * Secrets stored in Secrets Manager are encrypted using AWS KMS (managed via `secretsmanager` module).
* **Encryption in Transit:**
    * Communication to the backend service is enforced over HTTPS via the ALB (managed via `load_balancer` module).
    * The ALB is configured to enforce TLS 1.2 using certificates managed by the `acm` module.
* **Least Privilege:**
    * Specific IAM roles with minimal permissions are created for the ECS task to access necessary services (like Secrets Manager, CloudWatch Logs, ECR), managed by the `iam` module.
    * IAM database authentication is used for RDS, avoiding embedding static credentials. A Lambda function (`modules/rds/intermediate/build/index.js`) dynamically creates the necessary IAM user within the database and grants `rds_iam` role access.
* **Audit Logging:**
    * CloudWatch Logs are enabled for the ECS service (configured in `ecs` module).
    * RDS database logs (e.g., audit, error, general) are configured to be sent to CloudWatch Logs (configured in `rds` module).
    * CloudWatch Alarms (`cloudwatch_alarm` module) are set up based on logs or metrics.
* **Private Networking:**
    * The RDS database instance resides only in private subnets (defined in `vpc` module, used by `rds` module), inaccessible directly from the internet.
    * The ECS Fargate service runs in private subnets (defined in `vpc` module, used by `ecs` module).
    * VPC Endpoints (`vpc_endpoint` module) ensure traffic to AWS services stays within the AWS network where possible.
* **Access Control:**
    * Security Groups restrict ingress traffic strictly (managed within `vpc`, `load_balancer`, `ecs`, `rds` modules):
        * ALB Security Group allows HTTPS traffic (port 443).
        * ECS Service Security Group allows traffic only from the ALB Security Group on the application port.
        * RDS Security Group allows traffic only from the ECS Service Security Group on the PostgreSQL port (5432).

## Deployment Steps

**(Manual Deployment - See CI/CD section for automated deployment)**


**Prerequisites:**

* Terraform installed.
* AWS Account configured with appropriate credentials (e.g., via AWS CLI profiles, environment variables).
* Docker installed (required by the `package_lambda.sh` script).
* Cloudflare API Token (if using the `cloudflare` module for DNS).

**Deployment:**

1.  **Clone the repository:**
    ```bash
    git clone <your-repo-url>
    cd <your-repo-directory>
    ```
2.  **Prepare Lambda Package:** The RDS module requires a Lambda function to set up the IAM database user. Run the packaging script:
    ```bash
    # Ensure the script has execute permissions
    chmod +x modules/rds/intermediate/build/package_lambda.sh
    # Execute the script, passing the build directory
    ./modules/rds/intermediate/build/package_lambda.sh modules/rds/intermediate/build
    ```
    This script uses Docker to install Node.js dependencies (`@aws-sdk/client-secrets-manager`, `pg`) needed by the `index.js` Lambda function. Ensure the output exists (potentially a zip file in `modules/rds/intermediate/to_upload/`).
3.  **Prepare Variables:**
    * Review `variables.tf` to understand required inputs.
    * Create a `dev.tfvars` file (or use another name like `terraform.tfvars`) and populate it with values for your deployment (region, VPC CIDR, environment name, domain names, Cloudflare credentials if applicable, etc.).
    * **Sensitive values** like the initial RDS master password or API keys should ideally be handled securely (e.g., environment variables, `secrets.auto.tfvars` added to `.gitignore`, or CI/CD secrets) rather than committed directly in `.tfvars` files. I opted for resource `random_password` to generate random string for password and then directly using it's output via `random_password.example.result` to the variables of modules marked as sensitive.

    ```tfvars
    # Example dev.tfvars (add other required variables)
    aws_region         = "ap-south-1"
    environment        = "dev"
    vpc_cidr           = "10.0.0.0/16"
    db_master_username = "dbadmin"
    ...
    ```
4.  **Initialize Terraform:**
    ```bash
    terraform init
    ```
5.  **Plan the deployment:**
    ```bash
    terraform plan -var-file="dev.tfvars"
    ```
    Review the plan carefully.
6.  **Apply the configuration:**
    ```bash
    terraform apply -var-file="dev.tfvars"
    ```
    Confirm by typing `yes` when prompted.

## CI/CD Workflows (GitHub Actions)

This repository utilizes GitHub Actions for automating Terraform deployment and destruction processes for the `dev` environment.

### `deploy-dev.yml`

This workflow automates the deployment of the `dev` infrastructure.

* **Triggers:**
    * Runs on pushes to tags matching `dev-*`. Benefit: Allows triggering deployments by creating specific tags (e.g., `dev-v1.2.0`).
    * Runs on pushes to the `main` branch. Benefit: Enables CI/CD from the main development line.
    * Runs on pull requests targeting `main`. Benefit: Allows planning and validation before merging.
    * `paths-ignore`: Skips runs if only the `README.md` file is changed. Benefit: Avoids unnecessary runs for documentation updates.
* **Environment Variables (`env`):**
    * `STAGE`: Sets the target environment ('dev').
    * `TF_STATE_*`: Configures the S3 bucket name, key (path within the bucket), region, and DynamoDB table name for Terraform remote state storage, pulling values from GitHub Variables (`vars.*`). Benefit: Centralizes state configuration.
    * `WORKING_CODE_*`: Captures repository context (name, owner). Benefit: Useful for potential scripting or tagging.
* **Permissions:**
    * `id-token: write`: Required for OpenID Connect (OIDC) authentication with AWS. Benefit: Allows the workflow to securely assume an IAM role in AWS without static credentials.
    * `contents: write`: Required for `actions/checkout` to fetch code and potentially for other actions interacting with the repo.
    * `pull-requests: write`, `issues: write`: Required for posting plan comments back to pull requests. Benefit: Improves PR review process.
* **Job: `deploy-dev`:**
    * `runs-on: ubuntu-latest`: Specifies the runner environment.
    * **Steps:**
        1.  `actions/checkout@v3`: Checks out the repository code.
        2.  `aws-actions/configure-aws-credentials@v1-node16`: Configures AWS credentials by assuming the IAM role specified in the `DEPLOY_ROLE` GitHub Variable using OIDC. Benefit: Secure, keyless authentication to AWS.
        3.  `Setup TF backend`: A script block that checks if the specified S3 bucket and DynamoDB table for Terraform state exist. If not, it creates them with secure defaults (versioning, encryption, public access block for S3; basic provisioned throughput and tagging for DynamoDB). Benefit: Automates the setup of the required backend infrastructure, ensuring consistency.
        4.  `Get Terraform Version`: Reads the required Terraform version from the `.terraform-version` file in the repository. Benefit: Ensures the correct Terraform version is used.
        5.  `hashicorp/setup-terraform@v3`: Installs the specific Terraform version identified in the previous step. Benefit: Guarantees consistent Terraform execution environment.
        6.  `Check Terraform Code Format`: Runs `terraform fmt -check`. Benefit: Enforces code style consistency.
        7.  `Terraform Init`: Runs `terraform init`, configuring the S3 backend using the environment variables. The `CLOUDFLARE_API_TOKEN` is passed from GitHub Secrets. Benefit: Prepares Terraform, connecting to the remote state.
        8.  `Validate Terraform Code`: Runs `terraform validate`. Benefit: Performs syntax and basic configuration checks early.
        9.  `Generate Terraform Plan`: Runs `terraform plan`, saving the plan to `${STAGE}.tfplan` and using the corresponding `${STAGE}.tfvars` file. `-detailed-exitcode` provides specific exit codes based on plan status (no changes, changes, error). `continue-on-error: true` allows subsequent steps (like PR commenting) to run even if the plan fails. Benefit: Generates a preview of changes.
        10. `Update Pull Request`: (Runs only on `pull_request` events) Uses `actions/github-script` to post a formatted comment to the PR containing the outcome of format check, init, plan, validation, and the plan output itself within a collapsible section. Benefit: Provides immediate feedback on the PR regarding infrastructure changes.
        11. `Terraform Plan Status`: Exits the workflow with an error if the plan step failed. Benefit: Prevents proceeding to apply if the plan has errors.
        12. `Current WF run date`: Captures the current timestamp.
        13. `Manual Approval`: Uses `trstringer/manual-approval` to pause the workflow and require manual approval from users listed in the `APPROVERS` GitHub Variable before proceeding. Requires a GitHub Personal Access Token (`CD_READ_ORG_USERS_FOR_MANUAL_APPROVAL_GH_ACTION` secret) with org read permissions. Benefit: Critical control step to prevent unintended applies, allowing human review.
        14. `Terraform Apply`: (Runs only after manual approval) Runs `terraform apply` using the saved plan file (`${STAGE}.tfplan`). Benefit: Executes the planned infrastructure changes.

### `destroy-dev.yml`

This workflow automates the destruction of the `dev` infrastructure.

* **Triggers:**
    * `workflow_dispatch`: Allows manual triggering from the GitHub Actions UI. Benefit: Provides controlled execution for destruction.
    * Runs on pushes to tags matching `destroy-dev-*`. Benefit: Allows triggering destruction via specific Git tags.
* **Environment Variables (`env`):**
    * Similar `STAGE` and `TF_STATE_*` variables as the deploy workflow to correctly locate the Terraform state.
* **Permissions:**
    * `id-token: write`, `contents: write`: Similar permissions as the deploy workflow for AWS OIDC authentication and code checkout.
* **Job: `destroy`:**
    * `runs-on: ubuntu-latest`: Specifies the runner environment.
    * **Steps:**
        1.  `actions/checkout@v3`: Checks out the repository code.
        2.  `aws-actions/configure-aws-credentials@v1-node16`: Configures AWS credentials via OIDC, assuming the specified IAM role.
        3.  `Get Terraform Version`: Reads the version from `.terraform-version`.
        4.  `hashicorp/setup-terraform@v3`: Installs the specific Terraform version.
        5.  `Terraform Init`: Initializes Terraform, connecting to the remote S3 backend.
        6.  `Terraform Validate`: Performs basic validation.
        7.  `Terraform Destroy`: (Runs only if validation succeeds) Runs `terraform destroy -auto-approve` using the `${STAGE}.tfvars` file for any required input variables during destruction. Benefit: Automates the removal of all resources managed by Terraform for the specified state.

**Note on Secrets and Variables:** These workflows rely heavily on GitHub Actions Secrets (e.g., `CLOUDFLARE_API_TOKEN`, `CD_READ_ORG_USERS_FOR_MANUAL_APPROVAL_GH_ACTION`) and Variables (e.g., `TF_STATE_BUCKET_NAME`, `AWS_REGION`, `DEPLOY_ROLE`, `APPROVERS`). These must be configured correctly in the repository or organization settings for the workflows to function.


## Cleanup

To destroy the infrastructure and avoid ongoing charges:

1.  **Run Terraform Destroy:**
    ```bash
    terraform destroy -var-file="dev.tfvars"
    ```
    Confirm by typing `yes` when prompted.
2.  **Verify Cleanup:** Log in to the AWS Console to ensure all resources (VPC, RDS, ECS, ECR images, ALB, Secrets, IAM roles/policies, CloudWatch Log Groups, ACM certificates, SNS topics) have been terminated.

## Future Improvements

* **WAF Integration:** Add AWS WAF to the ALB (`load_balancer` module) for protection against common web exploits.
* **Bastion Host/Session Manager:** Implement secure access to resources in private subnets using AWS Systems Manager Session Manager or a Bastion Host.
* **Detailed Auditing:** Enable VPC Flow Logs and CloudTrail, potentially sending logs to a central security account.
* **Disaster Recovery:** Implement cross-region replication for RDS backups and potentially the ECS service.
* **Advanced Monitoring & Alerting:** Configure more specific CloudWatch Alarms (`cloudwatch_alarm` module) and potentially integrate with a monitoring dashboard service.
