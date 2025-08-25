# Jenkins-CI-CD-Pipeline-with-Terraform-SonarQube-Docker-GitHub-Webhooks
Jenkins CI/CD pipeline integrating GitHub Webhooks, SonarQube, and Docker. Automates build, test, code analysis, and containerized deployment. Includes auto-tagging for Docker images and optional Terraform integration for infrastructure provisioning.

## 🖥️ Infrastructure Setup

* **3 Virtual Machines (VMs):**

  * Jenkins Server
  * SonarQube Server
  * Docker Host

---

## ⚙️ Detailed Pipeline Steps

### 1. Jenkins Setup

* Setup the Jenkins server.
* Login to Jenkins → **New Item → Freestyle Project**.
* Configure **Source Code Management (SCM)**.
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
  * Generate a token → copy it.
  * Copy the project key.
* In Jenkins:

  * Install **SonarQube Scanner** plugin.
  * Install **SSH2Easy** plugin.
  * Go to **Manage Jenkins → Global Tool Configuration → Add SonarQube Scanner**.
  * Go to **Manage Jenkins → Configure System → Add SonarQube Server**.
* In Jenkins job:

  * Add SonarQube analysis properties step.
  * Build the job and verify code analysis.

---

### 4. Docker Integration

* Connect Docker server with Jenkins.
* Login to Jenkins server as **jenkins user**.
* Ensure Jenkins user has Docker access:

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
  * On Docker server, build and run container:

    ```bash
    cd /home/ubuntu/website
    docker build -t mywebsite .
    docker run -d -p 8085:80 mywebsite
    ```
* Ensure container is accessible at `http://<server-ip>:8085`.

---

### 6. Automating Docker Image Tagging

* Create script `auto-tag.sh` for auto-incrementing Docker tags:

  ```bash
  #!/bin/bash
  IMAGE_NAME="mywebsite"
  HOMED="/home/azureuser/"
  cd ${HOMED}

  TAG=$(date +%Y%m%d%H%M%S)
  docker build -t ${IMAGE_NAME}:${TAG} .
  docker rmi $(docker images -f "dangling=true" -q)
  ```
* Give execute permission:

  ```bash
  chmod a+rx auto-tag.sh
  ```
* Add script execution in Jenkins job.
* Commit changes → Jenkins pipeline triggers automatically → New Docker container deployed.

---

## ✅ Key Outcomes

* Fully automated CI/CD pipeline.
* Code quality validation with SonarQube.
* Dockerized deployment.
* Auto-tagged Docker images.
* Triggered via GitHub webhooks.
