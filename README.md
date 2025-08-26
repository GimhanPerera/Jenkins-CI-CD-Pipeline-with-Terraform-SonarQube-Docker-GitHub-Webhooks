# Jenkins-CI-CD-Pipeline-with-Terraform-SonarQube-Docker-GitHub-Webhooks
<img width="681" height="469" alt="pipeline drawio" src="https://github.com/user-attachments/assets/0c810d6c-fbc0-4d8a-a432-abd689284fe0" />

Jenkins CI/CD pipeline integrating GitHub Webhooks, SonarQube, and Docker. Automates build, test, code analysis, and containerized deployment. Includes auto-tagging for Docker images and optional Terraform integration for infrastructure provisioning.

☁️ Provisioning Infrastructure with Terraform on Azure

This project uses Terraform to provision the required 3 Virtual Machines (VMs) in Azure:

* Jenkins Server
* SonarQube Server
* Docker Server

## 🔧 Prerequisites

Before running Terraform files, install:
* [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
* [Terraform](https://developer.hashicorp.com/terraform/downloads)

Also:
Create an SSH key pair on your local machine.
```bash
ssh-keygen -t rsa -b 4096
```

Update the path of the SSH public key in the ssh_key variable inside variables.tf.

Update your Azure Subscription ID in main.tf under the provider block:
```bash
provider "azurerm" {
  features {}
  subscription_id = "XXXX"
}
```
▶️ Run Terraform Commands

Go inside the terraform file folder and run:
```bash
terraform init
```

Initializes the Terraform working directory and downloads required provider plugins.
```bash
terraform plan
```

Creates an execution plan and shows what resources will be created in Azure.
```bash
terraform apply
```

Applies the plan and provisions the VMs in Azure.

## ⚙️ Detailed Pipeline Steps

### 1. Jenkins Setup

* Login to Jenkins → **New Item →**Create a **Freestyle Project**.
* Configure **Source Code Management (SCM)** in the job as Git.
* Add GitHub repository:
  * Example: [Simple Node.js App](https://github.com/GimhanPerera/simple-nodejs-app)
* Set branch name and save.

### 2. Configure GitHub Webhooks

* Enable **GitHub hook trigger** in Jenkins.
* Go to GitHub repo → **Settings → Webhooks → Create webhook**.

  * URL: `http://<PUBLIC-IP-of-Jenkins-server>:8080/github-webhook/`
* Trigger a commit and verify Jenkins build.
* Confirm that build files appear in the workspace.

---

### 3. SonarQube Integration

* Configure SonarQube in Jenkins.
* In SonarQube:

  * Create a **manual project**.
  * Select **analysis method = Jenkins**.
  * Generate a token → copy and save it.
  * Copy the project key and save.
* In Jenkins:

  * Install **SonarQube Scanner** and **SSH2Easy** plugin.
  * Go to **Manage Jenkins → Global Tool Configuration → Add SonarQube Scanner**.
  * Go to **Manage Jenkins → Configure System → Add SonarQube Server**.
* In Jenkins job:

  * Add SonarQube analysis properties step.
  * Build the job and verify code analysis.

---

### 4. Docker Integration

* Login to Jenkins server as **jenkins user**.
* Check whether Jenkins user can connet to Docker server via SSH.
* If unable to login, Login to the Docker server and go to /etc/ssh/ssd_config file.
* Then change the following settings
```bash
  PasswordAuthentication yes
  PubkeyAuthentication yes
```
* Restart the SSH service.
* Ensure the current Docker user has Docker access:

  ```bash
  sudo usermod -aG docker <user>
  newgrp docker
  ```
* If login fails, check `/etc/ssh/sshd_config.d/` settings.

* On Jenkins server:
  * Use `ssh-keygen` & `ssh-copy-id` to connect with Docker server.
* Add Docker server to Jenkins credentials.
  * In Jenkins UI → **Manage Jenkins → Nodes & Clouds** → add Docker host.
* Configure Remote Shell to deploy code.

---

### 5. Build & Deployment Steps

* In Jenkins job:

  * Add **Execute Shell** step:

    ```bash
    scp -r ./* ubuntu@<Docker Server>:~/website
    ```
  * In the Job: Add another remote shell script in the job to build the image in Docker server

    ```bash
    cd /home/<USER>/website
    docker build -t mywebsite .
    docker run -d -p 8085:80 mywebsite
    ```
* Run the job and ensure container is accessible at `http://<server-ip>:8085`.

---

### 6. Automating Docker Image Tagging

* Create script `auto-tag.sh` for auto-incrementing Docker tags:

  ```bash
  #!/bin/bash

  IMAGE_NAME=""mywebsite""
  HOMED=""/home/azureuser""
  ENV_FILE=""${HOMED}/.envfile""

  # Make sure the env file exists
  touch ""$ENV_FILE""
  
  # Step 1: Get all tags for the image
  TAGS=$(docker images --format '{{.Repository}}:{{.Tag}}' | grep ""^${IMAGE_NAME}:"" | awk -F: '{print $2}')
  
  # Step 2: Find the highest version
  MAX_VERSION=0
  for TAG in $TAGS; do
      if [[ $TAG =~ ^v([0-9]+)$ ]]; then
          VERSION=${BASH_REMATCH[1]}
          if (( VERSION > MAX_VERSION )); then
              MAX_VERSION=$VERSION
          fi
      fi
  done
  
  # Step 3: Compute new tag
  NEW_VERSION=$((MAX_VERSION + 1))
  NEW_TAG="v$NEW_VERSION"
  
  echo "Latest tag is v$MAX_VERSION"
  echo "New tag will be $NEW_TAG"
  
  # Step 4: Stop and remove the container
  docker stop ${IMAGE_NAME} 2>/dev/null
  docker rm ${IMAGE_NAME} 2>/dev/null
  
  # Step 5: Save new tag to env file
  echo "NEW_TAG=${NEW_TAG}" > "$ENV_FILE"
  ```
* Give execute permission:

  ```bash
  chmod a+rx auto-tag.sh
  ```
* Add script execution in Jenkins job.
  ```bash
  HOMED="/home/azureuser/"
  cd ${HOMED}
  ./auto-tag.sh
  source ${HOMED}/.envfile
  cd ${HOMED}/website
  docker build -t mywebsite:${NEW_TAG} .
  docker run -d -p 3000:3000 --name=mywebsite mywebsite:${NEW_TAG}"
  ```
* Update the Remote shell script.
  ```bash
  chmod a+rx auto-tag.sh
  ```
* Commit changes → Jenkins pipeline triggers automatically → New Docker container deployed.

---

### 6. Automating Docker Image Tagging
* To secure Jenkins, Role-Based Access Control (RBAC) was configured:
1. Installed the Role-Based Authorization Strategy plugin.
2. Navigated to Manage Jenkins → Configure Global Security.
3. Enabled Role-Based Strategy for authorization.
4. Created a Developer role with view-only permissions (read access to jobs, builds, and pipelines).
5. Created a dev user and assigned them the Developer role.
🔒 This ensures developers can monitor pipeline runs but cannot modify configurations.
---

## ✅ Key Outcomes

* Infrastructure provisioning on Azure using Terraform.
* Fully automated CI/CD pipeline.
* Code quality validation with SonarQube.
* Dockerized deployment.
* Auto-tagged Docker images.
* Jenkins role-based access control with restricted dev user access.
* Triggered via GitHub webhooks.
