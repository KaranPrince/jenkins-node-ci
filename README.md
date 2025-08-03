<img width="1113" height="630" alt="image" src="https://github.com/user-attachments/assets/148fdf79-b2b5-4b82-b040-714fb78b634d" /><h1 align="center">🚀 Jenkins CI/CD Pipeline with GitHub & EC2 Deployment 🌐</h1>

<p align="center">
  <img src="https://img.shields.io/badge/Built%20With-Jenkins-blue?style=for-the-badge&logo=jenkins&logoColor=white"/>
  <img src="https://img.shields.io/badge/Powered%20By-AWS-orange?style=for-the-badge&logo=amazon-aws&logoColor=white"/>
  <img src="https://img.shields.io/badge/Hosted%20On-EC2-brightgreen?style=for-the-badge&logo=amazon-ec2&logoColor=white"/>
</p>

---

## 🌟 Project Overview

Welcome to my **end-to-end CI/CD DevOps project**!  
This setup demonstrates how to:
- 📥 Automatically **pull code** from GitHub
- 🧪 **Test** it on Jenkins
- 🚢 **Deploy it live** on an AWS EC2 instance  
- 🔁 All triggered by a **GitHub Webhook** 🎯

This is a real-time deployment pipeline built from scratch, fully automated using **Jenkins Declarative Pipeline**.

---

## 🧰 Tech Stack

| Category              | Tools / Services                                  |
|----------------------|---------------------------------------------------|
| CI/CD Pipeline        | Jenkins 🧰                                          |
| Version Control       | Git & GitHub 🐙                                    |
| Deployment Server     | AWS EC2 (Ubuntu) 💻                                 |
| Auth & Security       | SSH using `.pem` key 🔐                            |
| Hosting Path          | `/var/www/html/jenkins-deploy` 🌍                |
| Script Language       | Shell (Bash) 🐚                                     |

---

## 📂 Project Structure

jenkins-node-ci/
├── index.html # Auto-generated build output
├── scripts/
│ └── deploy.sh # SSH + Deploy logic
├── package.json # (Optional for test/build steps)
└── README.md # This file!


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

## 💡 Future Improvements

🐳 Add Docker build/push stage
🧪 Add unit test coverage with JUnit
🧰 Setup Prometheus + Grafana for monitoring
🏗️ Add staging & production environments
💬 Integrate Slack/Mattermost for pipeline alerts


## 🧑‍💻 Author
**Karan S**
💼 DevOps | Cloud | Automation
🌐 LinkedIn
📬 karans.appdev@gmail.com

🙌 Support
If you found this useful:
⭐ Star this repo
🔁 Fork & try it yourself
💬 Drop your feedback

<p align="center"> Made with ❤️ by Karan S | CI/CD Automation - GitHub ⚙️ Jenkins 🚀 EC2 🌐 AWS ☁️</strong></p>
 </p>
