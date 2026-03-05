# 📦 Amazon-Like E-Commerce Platform (Phase 14: AI Customer Support Chatbot)

## 🚀 Phase 14 Overview
This branch (`phase-14-ai-chatbot`) represents the **Grand Finale** of the e-commerce platform journey. We have evolved from a basic UI deployment all the way to a completely automated, observable, FinOps-optimized Kubernetes GitOps architecture.

To cap off the application's capabilities, this phase introduces **Generative AI**. By integrating AWS Bedrock and Anthropic's Claude Foundation Model, we have built a fully interactive, context-aware Customer Support Chatbot directly into the React frontend.

### 🤖 AI Integration Architecture
1. **The LLM Backend (Spring AI & AWS Bedrock)**
   * **Technology**: Java Spring Boot, Spring AI framework, AWS Bedrock (Anthropic Claude 3 Haiku).
   * **Purpose**: Instead of making raw HTTP requests to OpenAI or AWS, the backend leverages the `spring-ai-bedrock` abstraction. This allows the backend to securely authenticate with AWS IAM roles, generate prompts, and stream responses back to the client using a clean, standardized Java API.
   * **Resilience**: The backend is configured with Spring Retry and AOP to gracefully backoff and retry inference requests if the AWS Bedrock API is throttled or temporarily unavailable.
2. **The React UI (Next.js Chat Interface)**
   * **Technology**: React, TailwindCSS, Next.js.
   * **Purpose**: A floating action button was added to the storefront UI that expands into a sleek chat window. It maintains conversation history locally and interfaces with the new `/api/chat` backend endpoint.

```mermaid
graph TD
    %% User
    User[Shopper]
    
    %% Frontend
    subgraph Frontend ["React / Next.js Storefront"]
        ChatUI[Floating Chatbot UI]
    end
    
    %% Backend
    subgraph Backend ["Spring Boot API"]
        Controller["/api/chat Endpoint"]
        SpringAI[Spring AI Abstraction]
    end
    
    %% AI Provider
    subgraph AWS ["Amazon Web Services"]
        Bedrock{"AWS Bedrock API"}
        Claude((Anthropic<br/>Claude 3 Model))
    end
    
    %% Data Flow
    User -->|Types Message| ChatUI
    ChatUI -->|POST Request| Controller
    Controller -->|Formats Prompt| SpringAI
    SpringAI -.->|IAM Authenticated Call| Bedrock
    Bedrock <==>|Inference| Claude
    SpringAI -.->|Streams Response| ChatUI

    %% Styling
    classDef aws fill:#f9f9f9,stroke:#666,stroke-dasharray: 5 5
    classDef app fill:#e1f5fe,stroke:#0288d1,color:black,stroke-width:1px
    classDef ai fill:#f3e5f5,stroke:#8e24aa,color:black,stroke-width:2px
    
    class AWS aws
    class ChatUI,Controller,SpringAI app
    class Bedrock,Claude ai
```

## 📂 Project Structure
```text
.
├── .github/workflows/             # 🐙 GitHub Actions Pipelines (DevSecOps Scans)
├── .gitlab-ci.yml                 # 🦊 GitLab CI Pipeline (Legacy UI/API Deployments)
├── Jenkinsfile                    # 🕴️ Jenkins Pipeline (GitOps Automation & SHA Tagging)
├── backend/                       # ✅ Spring Boot App 
│   ├── build.gradle               # 📦 Updated with spring-ai-bedrock dependencies
│   └── src/main/java.../chat/     # 🧠 ChatModel controllers and service abstractions
├── frontend/                      # ✅ React App 
│   └── src/components/ChatBot.tsx # 💬 New React chatbot component UI
└── ops/
    ├── helm/amazon-app/           # ☸️ Production GitOps charts
    └── ...
```

---
*Created as the Generative AI capstone for a DevOps Reference Architecture journey.*
