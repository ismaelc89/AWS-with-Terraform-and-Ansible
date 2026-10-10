# AWS-with-Terraform-and-Ansible

Repo to create a basic AWS architecture using Terraform as IaC and Ansible as CM

# Architecture Overview
```
Internet
                  │
                  ▼
        ┌───────────────────┐
        │ Internet Gateway  │
        └─────────┬─────────┘
                  │
 ┌────────────────┼────────────────────────────────────────────┐
 │ VPC (10.0.0.0/16)                                           │
 │                                                             │
 │   ┌─────────────────────────────────────────────────────┐   │
 │   │ Public Subnet (10.0.1.0/24)                         │   │
 │   │   - Route Table -> Internet Gateway                 │   │
 │   │                                                     │   │
 │   │   ┌─────────────────────────────────────────────┐   │   │
 │   │   │ Public EC2: Nginx Reverse Proxy             │   │   │
 │   │   │ Security Group: Allow HTTP (80) & SSH (22)  │   │   │
 │   │   └──────────────────────┬──────────────────────┘   │   │
 │   └──────────────────────────┼──────────────────────────┘   │
 │                              │ Internal Traffic (Port 8080) │
 │   ┌──────────────────────────┼──────────────────────────┐   │
 │   │ Private Subnet (10.0.2.0/24)                        │   │
 │   │   - Route Table -> Local Only (No Internet)         │   │
 │   │                                                     │   │
 │   │   ┌─────────────────────────────────────────────┐   │   │
 │   │   │ Private EC2: Application Server             │   │   │
 │   │   │ Security Group: Allow Port 8080 & SSH (22)  │   │   │
 │   │   │                 ONLY from Public EC2 SG     │   │   │
 │   │   └─────────────────────────────────────────────┘   │   │
 │   └─────────────────────────────────────────────────────┘   │
 └─────────────────────────────────────────────────────────────┘
```

# Repository Layout
```
.
├── ansible
│   ├── ansible.cfg                         # Main configuration to be used with AWS
│   ├── group_vars
│   │   └── role_app_server.yml             # Vars to acess the private server
│   ├── inventory
│   │   └── aws_ec2.yml                     # Dynamuc AWS EC2 inventory
│   ├── roles
│   │   ├── app_server
│   │   │   ├── tasks
│   │   │   │   └── main.yml                # tasks to be perform for app_server role
│   │   │   └── templates
│   │   │       └── index.html.j2           # index file used for the app_server
│   │   └── web_proxy
│   │       ├── handlers
│   │       │   └── main.yml                # handler to reload nginx service
│   │       ├── tasks
│   │       │   └── main.yml                # tasks to be perform for web_proxy role
│   │       └── templates
│   │           └── nginx_proxy.conf.j2     # template used for the web_proxy config
│   └── site.yml                            # main playbook
├── README.md                               # This README file
└── terraform
    ├── datasource.tf                       # AMI and instnace_type datasource
    ├── main.tf                             # Main terraform file
    ├── outpurs.tf                          # Output to get public ip and AZs
    ├── providers.tf                        # AWS provider confif
    └── variables.tf                        # Environment variable used
```
# Prerequisites

- Terraform CLI installed (v1.0.0+).
- Ansible installed
- AWS CLI configured via aws configure.
- An SSH key pair created on your AWS account (for this practice we used one called "MyEC2KeyPair")

# Step-by-Step Deployment Guide

### Step 1: Clone the Repository & Navigate to Terraform Directory
```
git clone [https://github.com/](https://github.com/)/.git
cd /terraform
```
### Step 2: Initialize Terraform
Download the required AWS provider modules:
```
terraform init
```
### Step 3: Preview the Execution Plan
Review all resources Terraform intends to provision:
```
terraform plan
```
### Step 4: Apply Configuration
Deploy the architecture to AWS:
```
terraform apply -auto-approve
```
Upon completion, Terraform will output the server details:
- public_ip_ec2

# Start Configuration Management via Ansible

### Step 1: Navigate to Ansible Directory
```
cd /ansible
```
### Step 2: Verify that Ansible get proper info of inventory
```
ansible-inventory --graph
```
You should get the ip address of the ec2 public and private instance under the proper group
If you get any error please confirm that the path of the `private_key_file` is the correct one where your key pair is located if not please update and save file

### Step 3: Apply Ansible Playbook 
```
ansible-playbook site.yml
```

# Verification & Testing
1. Allow some minutes for the Ansible Playbook to finish installing and initializing Apache service.

2. Verify HTTP routing via `curl`:
```
curl http://<PUBLIC_IP>
```
3. Alternatively, open your browser and navigate to:
```
http://<PUBLIC_IP>
```
# Automated Teardown
To avoid incurring cloud provider charges after testing, destroy all provisioned infrastructure with a single command:
```
terraform destroy -auto-approve
```