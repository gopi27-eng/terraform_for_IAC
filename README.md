# terraform_for_IAC
# AWS Infrastructure Automation with Terraform

An end-to-end Terraform project that automatically provisions a secure, scalable, and highly available web architecture on AWS. The configuration provisions a custom VPC, public routing infrastructure, security groups, an EC2 instance bootstrapping a web application, and an Application Load Balancer (ALB) connected to a Target Group.

## 🏗️ Architecture Overview

The script automates the deployment of the following infrastructure components:
* **VPC**: A dedicated Virtual Private Cloud with DNS support enabled.
* **Subnet**: A Public Subnet configured across Availability Zone `us-east-1a` with automatic public IP assignment on launch.
* **Internet Gateway (IGW)**: Establishes a direct connection between your custom VPC and the outside internet.
* **Route Table**: A public routing configuration mapping all outbound traffic (`0.0.0.0/0`) to the Internet Gateway, explicitly associated with the public subnet.
* **Security Group**: Acts as a virtual firewall allowing inbound SSH (Port 22) and HTTP (Port 80) access.
* **EC2 Instance**: An automated virtual machine bootstrapped via a custom `user_data1.sh` shell script to initialize your application environment.
* **Application Load Balancer (ALB)**: A public-facing traffic distributor routing incoming user requests.
* **Target Group & Attachment**: A logical container that monitors the health of the EC2 backend server on Port 80 and registers the instance to receive load-balanced traffic.

---

## 📁 Project Structure

Ensure your project workspace contains the following files:
```text
├── provider.tf      # Defines HashiCorp AWS provider details and target region
├── main.tf          # Core infrastructure resources (VPC, EC2, ALB, TG)
├── variables.tf     # Input variables definitions (CIDRs, Instance Type)
├── user_data1.sh    # Startup shell script to bootstrap the EC2 application
└── README.md        # Project documentation