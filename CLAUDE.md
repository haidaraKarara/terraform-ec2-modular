# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a modular Terraform project for deploying EC2 instances on AWS with complete environment separation. The project uses a three-tier architecture: bootstrap (backend setup), environments (dev/prod), and reusable modules (compute, networking).

## Architecture

### Key Components
- **Bootstrap**: Creates S3 buckets and DynamoDB tables for Terraform state management
- **Environments**: Environment-specific configurations (dev/prod) that consume modules
- **Modules**: Reusable Terraform modules for compute and networking

### Module Dependencies
1. `networking` module: Creates VPC, subnets, security groups, and internet gateway
2. `load-balancer` module: Creates Application Load Balancer with target groups and health checks
3. `compute` module: Creates EC2 instances or Auto Scaling Groups with optional Elastic IP and SSM access

## Essential Commands

### Initial Setup (Required First)
```bash
# Bootstrap dev environment backend
cd bootstrap/dev
terraform init && terraform apply

# Bootstrap prod environment backend  
cd bootstrap/prod
terraform init && terraform apply
```

### Environment Management
```bash
# Initialize and deploy dev environment
cd environments/dev
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your configuration
terraform init
terraform plan
terraform apply

# Initialize and deploy prod environment
cd environments/prod
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your configuration
terraform init
terraform plan
terraform apply
```

### Common Operations
```bash
# View current state
terraform show

# List all resources
terraform state list

# View outputs
terraform output

# Destroy environment (be careful!)
terraform destroy
```

### Access Methods

**Primary: AWS Systems Manager Session Manager (Recommended)**
```bash
# Install Session Manager plugin (one-time setup)
curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/mac_arm64/sessionmanager-bundle.zip" -o "sessionmanager-bundle.zip"
unzip sessionmanager-bundle.zip
sudo ./sessionmanager-bundle/install -i /usr/local/sessionmanagerplugin -b /usr/local/bin/session-manager-plugin

# Connect to instance (interactive terminal)
aws ssm start-session --target <instance-id> --region <region>

# Get connection command from Terraform
terraform output ssm_session_command
```


## Required Configuration

### terraform.tfvars Variables
Each environment requires configuration of:
- `aws_region`: AWS region for deployment
- `allowed_http_cidrs`: List of IP addresses allowed HTTP access to load balancer
- `enable_https`: Boolean to enable HTTPS listener on load balancer
- `health_check_path`: Path for load balancer health checks (default: "/")
- `enable_auto_scaling`: Boolean to enable Auto Scaling Group deployment (recommended: true for both dev and prod)
- `asg_min_size`, `asg_max_size`, `asg_desired_capacity`: Auto Scaling Group sizing parameters
- `common_tags`: Tags applied to all resources

### Security Requirements
- **Access via AWS Systems Manager Session Manager only** - no SSH keys or open ports required
- SSH port 22 is closed by default
- **Load balancer provides HTTP/HTTPS access** to applications running on instances
- **Auto Scaling Group instances don't receive public IPs** for enhanced security
- terraform.tfvars files are gitignored and contain sensitive configuration
- IAM roles automatically grant SSM access to EC2 instances

## State Management

- Each environment has its own S3 backend for state isolation
- State files are encrypted and versioned in S3
- DynamoDB tables provide state locking to prevent concurrent modifications
- Backend configuration is in each environment's backend.tf file

## Development Workflow

1. Always test changes in dev environment first
2. Bootstrap backends must be created before deploying environments
3. Environments are completely isolated - no shared resources
4. Use terraform plan before apply to review changes
5. **Access applications via Load Balancer URL** for HTTP/HTTPS traffic
6. **Access instances via AWS SSM Session Manager only** - no IP restrictions or SSH keys needed
7. Install Session Manager plugin for interactive terminal access
8. **Auto Scaling Groups provide high availability** and can automatically replace unhealthy instances

## Load Balancer and Auto Scaling

### Application Load Balancer
- **HTTP/HTTPS access**: Public-facing load balancer distributes traffic to backend instances
- **Health checks**: Configurable health check path (default: "/")
- **Security groups**: Dedicated security group allows HTTP (80) and optional HTTPS (443) from internet
- **Target groups**: Automatic registration/deregistration of instances
- **Multi-AZ**: Load balancer spans multiple availability zones for high availability

### Auto Scaling Group
- **Unified architecture**: Both dev and prod environments use Load Balancer + Auto Scaling
- **Rolling updates**: Instance refresh with 50% minimum healthy percentage
- **Health checks**: ELB-based health checking with 300-second grace period
- **Multi-AZ distribution**: Instances distributed across multiple subnets/AZs
- **Configurable sizing**: Different min/max/desired capacity for dev vs prod
- **Launch templates**: Standardized instance configuration with encryption and tagging

### Key Outputs
- `alb_dns_name` and `alb_url`: Load balancer access URLs
- `deployment_type`: Shows whether deployment is "instance" or "autoscaling" 
- `autoscaling_group_name`: Name of ASG for management commands
- `get_instance_ids_command`: AWS CLI command to fetch current ASG instance IDs