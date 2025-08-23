<h1 align="center">🚀 Advanced Jenkins CI/CD on AWS (Node.js · ECR · EC2 via SSM)</h1>

<p align="center">
  <a href="https://github.com/KaranPrince/jenkins-node-ci">
    <img src="https://readme-typing-svg.demolab.com?font=Fira+Code&weight=700&size=26&pause=1000&color=00E5FF&center=true&vCenter=true&width=900&lines=GitHub+%E2%9E%9C+Jenkins+%E2%9E%9C+AWS;Build+%7C+Test+%7C+Scan+%7C+Containerize+%7C+Deploy;SonarQube+%2B+Trivy+%2B+Slack;Healthcheck+%2B+Rollback+%2B+Stable+Promotion" alt="Typing animation" />
  </a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/CI/CD-Jenkins-blue?style=for-the-badge&logo=jenkins&logoColor=white"/>
  <img src="https://img.shields.io/badge/Quality-SonarQube-0ea5e9?style=for-the-badge&logo=sonarqube&logoColor=white"/>
  <img src="https://img.shields.io/badge/Security-Trivy-critical?style=for-the-badge&logo=dependabot&logoColor=white"/>
  <img src="https://img.shields.io/badge/Container-Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white"/>
  <img src="https://img.shields.io/badge/Registry-AWS%20ECR-orange?style=for-the-badge&logo=amazon-aws&logoColor=white"/>
  <img src="https://img.shields.io/badge/Deploy-EC2%20via%20SSM-3DDC84?style=for-the-badge&logo=amazon-ec2&logoColor=white"/>
  <img src="https://img.shields.io/badge/Notify-Slack-4A154B?style=for-the-badge&logo=slack&logoColor=white"/>
  <img src="https://img.shields.io/badge/Runtime-Node.js-43853D?style=for-the-badge&logo=nodedotjs&logoColor=white"/>
  <img src="https://img.shields.io/badge/Tests-Jest-C21325?style=for-the-badge&logo=jest&logoColor=white"/>
</p>

<div align="center">

### 🔨 Project Info
<img src="https://img.shields.io/badge/build-passing-brightgreen?style=flat-square"/> 
<img src="https://img.shields.io/badge/license-MIT-blue?style=flat-square"/>
<img src="https://img.shields.io/badge/Made%20With-Jenkins-blue?style=flat-square"/>
<img src="https://img.shields.io/badge/Hosted%20On-AWS%20EC2-orange?style=flat-square"/>

### 📊 Repository Stats
<img src="https://img.shields.io/github/repo-size/KaranPrince/jenkins-node-ci?style=flat-square"/>
<img src="https://img.shields.io/github/last-commit/KaranPrince/jenkins-node-ci?style=flat-square"/>
<img src="https://img.shields.io/github/issues/KaranPrince/jenkins-node-ci?style=flat-square"/>
<img src="https://img.shields.io/github/stars/KaranPrince/jenkins-node-ci?style=flat-square"/>
<img src="https://img.shields.io/github/forks/KaranPrince/jenkins-node-ci?style=flat-square"/>
<img src="https://visitor-badge.laobi.icu/badge?page_id=KaranPrince.jenkins-node-ci"/>
</div>

---

## ✨ Highlights

- ⚙️ **End-to-End Jenkins CI/CD** powered by GitHub Webhooks  
- 🧪 **Unit testing** with Jest & coverage reporting  
- 📊 **SonarQube integration** with Quality Gates  
- 🔒 **Trivy scanning** (filesystem & container image security)  
- 🐳 **Docker BuildKit** builds, pushed to AWS ECR  
- 🚀 **Automated deployment** to EC2 using **AWS SSM** (no SSH keys)  
- 🩺 **Healthcheck & rollback** for safer production delivery  
- 🔔 **Slack notifications** for success/failure/unstable events  
- 📌 **Stable tag promotion** after successful health validation  


---

## 🛠️ Jenkins Pipeline Workflow

<p align="center">
  <img src="https://github.com/KaranPrince/jenkins-node-ci/assets/pipeline-animated.gif" width="800" alt="Pipeline animation"/>
</p>

### 📌 Pipeline Stages

| Stage                         | Description                                                                 |
|-------------------------------|-----------------------------------------------------------------------------|
| 🔄 **Checkout**               | Clones repo & captures Git metadata (commit, branch, author, message)       |
| 🧪 **Quality & Tests**        | Installs dependencies, runs Jest unit tests, SonarQube scan & quality gate  |
| 🔍 **Security Scan (Trivy)**  | Scans filesystem & Docker image for vulnerabilities                        |
| 🐳 **Docker Build & Push**    | Builds container image with BuildKit & pushes to AWS ECR                    |
| 🚀 **Deploy (via SSM)**       | Runs deployment commands inside EC2 using AWS Systems Manager               |
| 🩺 **Healthcheck & Rollback** | Verifies app is live; rolls back to last stable image if healthcheck fails  |
| 📌 **Promote Stable**          | Tags successfully deployed build as `stable` in ECR                        |
| 🔔 **Slack Notifications**    | Sends build status alerts to Slack (success, failure, unstable, aborted)    |

---

## 🔄 Pipeline Visualization (Mermaid)

```mermaid
flowchart TD
    A[GitHub Push] -->|Webhook| B[Jenkins Pipeline]
    B --> C[Checkout Code & Git Metadata]
    C --> D[Quality & Unit Tests (Jest)]
    D --> E[SonarQube Quality Gate]
    E --> F[Trivy Security Scan]
    F --> G[Docker Build & Push to ECR]
    G --> H[Deploy to EC2 via SSM]
    H --> I{Healthcheck}
    I -->|Success| J[Promote Image to Stable]
    I -->|Fail| K[Rollback to Stable Image]
    J --> L[Slack Notification ✅]
    K --> L[Slack Notification ❌]
```


📸 Visual Showcase
|GitHub Webhook | Trigger |	Jenkins Pipeline Console |	SonarQube Quality Report |

	
	
Trivy Security Scan	| Docker Build & Push | Deployment on EC2

	
	
Healthcheck Passed ✅ | Rollback Triggered 🔄 | Slack Notification 🔔


👉 The last **Part 3/3** will include:  
- 🎯 Features / Improvements list  
- 🗺️ Roadmap  
- 🙋 Author & credits  

Do you want me to also add **fun badges/emoji animations like “Made with ❤️ in Jenkins” or pipeline running GIFs** in Part 3?
