![Build Status](https://img.shields.io/badge/build-passing-brightgreen?style=flat-square)
![License](https://img.shields.io/badge/license-MIT-blue?style=flat-square)
![Made With](https://img.shields.io/badge/Made%20With-Jenkins-blue?style=flat-square)
![Hosted On](https://img.shields.io/badge/Hosted%20On-AWS%20EC2-orange?style=flat-square)

<h1 align="center">🚀 Jenkins CI/CD Pipeline with GitHub & EC2 Deployment 🌐</h1>

<p align="center">
  A complete end-to-end CI/CD pipeline setup using <strong>GitHub Webhook</strong>, <strong>Jenkins</strong>, and <strong>AWS EC2</strong> that automatically builds, tests, and deploys code with every push!
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Built%20With-Jenkins-blue?style=for-the-badge&logo=jenkins&logoColor=white"/>
  <img src="https://img.shields.io/badge/Powered%20By-AWS-orange?style=for-the-badge&logo=amazon-aws&logoColor=white"/>
  <img src="https://img.shields.io/badge/Hosted%20On-EC2-brightgreen?style=for-the-badge&logo=amazon-ec2&logoColor=white"/>
</p>

---

## 🌟 Project Overview

Welcome to my **end-to-end CI/CD DevOps project**!  
This project demonstrates a complete **CI/CD pipeline** using:

- 🔁 **GitHub Webhook** for triggering Jenkins on code push
- ⚙️ **Jenkins Pipeline** (Declarative) to build, test, and deploy
- ☁️ **AWS EC2** instance for deployment
- 🌐 Stylish **HTML output** showing commit details after deployment

This is a real-time deployment pipeline built from scratch, fully automated using **Jenkins Declarative Pipeline**.

---

## 🧰 Tech Stack

| Category              | Tools / Services                                  |
|----------------------|---------------------------------------------------|
| CI/CD Pipeline        | Jenkins 🧰                                          |
| Version Control       | Git & GitHub 🐙                                    |
| Deployment Server     | AWS EC2 (Ubuntu) 💻                                 |
| Auth & Security       | SSH using `.pem` key 🔐                            |
| Hosting Path          | `/var/www/html/jenkins-deploy` 🌍                 |
| 🎨 Frontend           |  HTML, CSS                                          |
| Script Language       | Shell (Bash) 🐚                                     |

---
## ⚙️ Jenkins Pipeline Stages

| Stage     | Description |
|-----------|-------------|
| 🔄 **Checkout** | Pulls latest code from GitHub repo |
| 🔧 **Build**    | Simulated build/compilation |
| 🧪 **Test**     | Runs basic validation tests |
| 🚀 **Deploy**   | Deploys to AWS EC2 and updates `index.html` |
| ✅ **Post**     | Prints build success/failure |


## 📂 Project Structure

├── Jenkinsfile
├── app/
│ └── index.html # HTML output template with placeholders
├── assets/
│ ├── screenshot1.png # GitHub webhook screenshot
│ ├── screenshot2.png # Jenkins pipeline stages
│ └── screenshot3.png # EC2 Deployment result
└── README.md


---

## 🛠️ Jenkins Pipeline Workflow

1. 🟢 **Code Pushed to GitHub**  
2. 🔔 **Webhook triggers Jenkins Job**  
3. 🧱 **Build & Test Stage**  
4. 🚀 **SSH into EC2 & Deploy HTML**  
5. ✅ **Post Build Summary**

### ✨ Final Output:
> Visit: `http://<your-ec2-ip>/jenkins-deploy/`  
> You’ll see:
<h1>Deployed via Jenkins from GitHub Webhook 🚀</h1>


---

## 📸 Screenshots

| 🔗 GitHub Webhook | ⚙️ Jenkins Build | 🌐 EC2 Output |
|------------------|------------------|----------------|
| ![](assets/screenshot1.png) | ![](assets/screenshot2.png) | ![](assets/screenshot3.png) |

---

## 🛠 How It Works

1. ✅ **GitHub push** triggers Jenkins via Webhook
2. ✅ Jenkins executes pipeline from `Jenkinsfile`
3. ✅ Git commit metadata is injected into `index.html`
4. ✅ `index.html` is uploaded to `/var/www/html/jenkins-deploy` on EC2
5. ✅ Output shows all commit details in styled format

---

## 📌 Setup Instructions

> Assumes:
> - Jenkins is installed on an EC2 instance
> - GitHub Webhook is configured
> - SSH access (PEM key) to target EC2

### 🔗 GitHub Webhook Setup

1. Go to GitHub repo → Settings → Webhooks → Add:


## 💡 Future Improvements

🐳 Add Docker build/push stage
🧪 Add unit test coverage with JUnit
🧰 Setup Prometheus + Grafana for monitoring
🏗️ Add staging & production environments
💬 Integrate Slack/Mattermost for pipeline alerts


## 📢 Author

<p align="center">
  <strong>Karan S</strong><br>
  💼 <a href="https://linkedin.com/in/karan-devops" target="_blank">LinkedIn</a> |
  📁 <a href="https://github.com/KaranPrince" target="_blank">GitHub</a>
</p>

🙌 Support
If you found this useful:
⭐ Star this repo
🔁 Fork & try it yourself
💬 Drop your feedback

<p align="center"> Made with ❤️ by Karan S | CI/CD Automation - GitHub ⚙️ Jenkins 🚀 EC2 🌐 AWS ☁️</strong></p>
 </p>
