# 📘 **README — DevOps Tech Challenge (Terraform + Ansible)**

## 🛠 **1. Environment Setup**

### **Install Required Tools**

Make sure the following tools are installed on your system:

1. **Terraform**
   [https://developer.hashicorp.com/terraform/downloads](https://developer.hashicorp.com/terraform/downloads)

2. **WSL + Ubuntu (for Windows users)**

   ```
   wsl --install
   ```

3. **Ansible** (inside WSL/Ubuntu)

   ```bash
   sudo apt update
   sudo apt install ansible -y
   ```

4. **AWS CLI**

   ```bash
   sudo apt install awscli -y
   ```

5. **Configure AWS credentials**

   ```bash
   aws configure
   ```

   Provide:

   * AWS Access Key
   * AWS Secret Key
   * Region (ex: us-east-2)

6. **Move SSH Key into WSL**

   ```bash
   mkdir -p ~/.ssh
   mv /mnt/c/Users/<yourWindowsUser>/Downloads/tech-challenge3-key.pem ~/.ssh/
   chmod 600 ~/.ssh/tech-challenge3-key.pem
   ```

---

## 🏗 **2. Deploying the Infrastructure (Terraform)**

Navigate into your Terraform folder:

```bash
cd terraform
```

Initialize Terraform:

```bash
terraform init
```

View the resources to be created:

```bash
terraform plan
```

Create infrastructure:

```bash
terraform apply
```

Terraform provisions:

* An **EC2 instance** (Amazon Linux 2023)
* An **S3 bucket**
* A **Security Group** (port 22 + port 80)
* An **IAM Role** with SSM permissions
* Outputs the **EC2 public IP**

---

## ⚙ **3. Configuring the Server (Ansible)**

Navigate into your Ansible folder:

```bash
cd ../ansible
```

### **Inventory File (`inventory`)**

Defines the EC2 host Ansible should connect to:

```
[webservers]
<EC2_PUBLIC_IP> ansible_user=ec2-user ansible_ssh_private_key_file=~/.ssh/tech-challenge3-key.pem ansible_ssh_common_args='-o StrictHostKeyChecking=no'
```

### **Run a connection test**

```bash
ansible -i inventory webservers -m ping
```

### **Run the configuration playbook**

```bash
ansible-playbook -i inventory setup-web.yaml
```

This installs Apache and deploys `index.html`.

---

## 📄 **4. Code Explanation**

### **Terraform Code (main.tf)**

* **aws_instance**
  Creates an EC2 instance using Amazon Linux 2023 AMI and instance type `t3.micro`.

* **aws_security_group**
  Allows SSH (22) and HTTP (80) access so Ansible can connect and Apache can serve traffic.

* **aws_iam_role + instance profile**
  Provides SSM permissions in case remote system management is needed.

* **aws_s3_bucket**
  Creates an S3 bucket as part of the infrastructure requirement.

* **Outputs**
  Prints the EC2 public IP and bucket name so Ansible can use them.

---

### **Ansible Playbook (`setup-web.yaml`)**

Breakdown of tasks:

1. **Install Apache**

   ```yaml
   yum:
     name: httpd
     state: present
   ```

   Installs the web server package.

2. **Start Apache Service**

   ```yaml
   systemd:
     name: httpd
     state: started
     enabled: yes
   ```

   Starts Apache and ensures it runs on every reboot.

3. **Deploy index.html**

   ```yaml
   copy:
     src: files/index.html
     dest: /var/www/html/index.html
   ```

   Copies your webpage to the Apache document root.

---

## 🎉 **Completed Workflow**

1. **Terraform** builds the infrastructure.
2. **Ansible** configures the server after it is created.
3. Visiting the EC2 public IP in a browser shows the deployed webpage.
