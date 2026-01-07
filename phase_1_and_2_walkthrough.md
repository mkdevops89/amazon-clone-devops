================================================================================
MASTER RUNBOOK: PHASE 1 & 2 (AMAZON-LIKE PROJECT)
================================================================================
Author: DevOps Architecture Team
Date: 2026-01-05
Goal: From "Empty Laptop" to "Running Full Stack Application"

--------------------------------------------------------------------------------
PREREQUISITES (Do this on your new computer first)
--------------------------------------------------------------------------------
1. INSTALL VS CODE: https://code.visualstudio.com/
2. INSTALL GIT: https://git-scm.com/downloads
3. INSTALL DOCKER DESKTOP: https://www.docker.com/products/docker-desktop/
   - Ensure it is running (Look for the whale icon in your taskbar).
4. (Optional) INSTALL VAGRANT & VIRTUALBOX (Only for Phase 1 VM method)
   - VirtualBox: https://www.virtualbox.org/
   - Vagrant: https://www.vagrantup.com/

--------------------------------------------------------------------------------
STEP 0: CLONE THE REPO (The "Clean" Start)
--------------------------------------------------------------------------------
Open your terminal (Command Prompt or Terminal.app) and run:

1. Clone the specific learning branch:
   git clone -b phase-1-source --single-branch https://github.com/mkdevops89/amazon-clone-devops.git amazon-phase-1

2. Open it in VS Code:
   cd amazon-phase-1
   code .

--------------------------------------------------------------------------------
PHASE 1: THE MANUAL / VM Setup
--------------------------------------------------------------------------------
Goal: Understand "SysAdmin" work. We will spin up a Virtual Machine (ubuntu) 
that acts like a real production server.

INSTRUCTIONS:
1. Open the Integrated Terminal in VS Code (Ctrl + `).

2. Navigate to the Vagrant folder:
   cd ops/vagrant

3. Start the Virtual Machine:
   # Pass your Datadog API Key (or ignore if not using Datadog)
   DD_API_KEY=your_api_key_here vagrant up
   
   # (This will take 5-10 minutes. It downloads Ubuntu, installs Docker, and starts the app automatically)

4. Log into the Server:
   vagrant ssh

5. Verify you are "Inside" the server:
   hostname
   # Output should be "vagrant" or similar.

6. Check the App:
   # On your HOST machine (your browser), go to:
   http://192.168.33.10:3000

7. SHUTDOWN (When finished):
   exit       # Leave the SSH session
   vagrant halt # Stop the VM to save battery

--------------------------------------------------------------------------------
PHASE 2: THE DOCKER SETUP (Modern Method)
--------------------------------------------------------------------------------
Goal: Understand "Containerization". Run the exact same app, but without 
needing a heavy VM. This is how we work 99% of the time.

INSTRUCTIONS:
1. Ensure your terminal is at the PROJECT ROOT (amazon-phase-1/):
   cd ../..  # (If you were still in ops/vagrant)

2. Build and Start the Containers:
   docker compose up -d --build
   # -d: Detached (Runs in background)
   # --build: Recompiles the Java/Node code if you changed it.

3. Verify they are running:
   docker compose ps
   # You should see 5 services:
   # - amazon-backend
   # - amazon-frontend
   # - amazon-mysql
   # - amazon-redis
   # - amazon-rabbitmq

4. ACCESS THE APP:
   Frontend: http://localhost:3000
   Backend API: http://localhost:8080
   Database: Port 3306

5. VIEW LOGS (Debugging):
   # View Backend logs (Java Spring Boot)
   docker compose logs -f backend

   # View Frontend logs (Next.js)
   docker compose logs -f frontend

6. CLEANUP (Important!):
   docker compose down
   # This stops and removes the containers.

--------------------------------------------------------------------------------
HOW TO "WORK" & LEARN
--------------------------------------------------------------------------------
1. PLAY WITH CODE:
   - Go to `frontend/src/app/page.tsx`
   - Change "Welcome to Amazon" to "Welcome to Michael's Shop".
   - Run `docker-compose up -d --build`
   - Refresh localhost:3000 to see your change.

2. PLAY WITH DATABASE:
   - Connect a DB Tool (like DBeaver or TablePlus) to `localhost:3306`.
   - User: root / Password: root
   - Look at the `products` table. Manually add a product.
   - Refresh the website. It should appear!

3. BREAK THINGS:
   - Stop the database: `docker stop amazon-mysql`
   - Refresh the page. See how the app handles errors.
   - Start it again: `docker start amazon-mysql`

--------------------------------------------------------------------------------
TROUBLESHOOTING
--------------------------------------------------------------------------------
ISSUE: "Port already in use"
SOLUTION: You might have another web server running.
- Run `docker ps` to see what is running.
- Run `docker-compose down` to kill ghosts.

ISSUE: "Connection refused"
SOLUTION: The Backend takes ~15 seconds to start (Java is slow).
- Wait 30 seconds.
- Check logs: `docker-compose logs backend`

================================================================================
END OF RUNBOOK
================================================================================

--------------------------------------------------------------------------------
OPTION 3: AWS EC2 (The Cloud Method)
--------------------------------------------------------------------------------
Goal: Use a real cloud server instead of Vagrant/VirtualBox. Cost: ~$0.01/hour.

1. Launch Instance (AWS Console):
   - Name: Amazon-Dev-Server
   - OS: Ubuntu 22.04 LTS
   - Instance Type: t3.small (t2.micro might freeze with Java)
   - Key Pair: Create new (download the .pem file)
   - Security Group: Allow Ports 22 (SSH), 3000 (Frontend), 8080 (Backend)

2. Connect (SSH):
   # From your laptop terminal
   chmod 400 key.pem
   ssh -i key.pem ubuntu@<PUBLIC-IP>

3. Install Tools (Automated):
   # Clone the repo first to get the script
   git clone -b phase-1-source --single-branch https://github.com/mkdevops89/amazon-clone-devops.git
   cd amazon-clone-devops

   # Run the Setup Script (Installs Docker Engine + Compose V2)
   chmod +x ops/scripts/setup_ec2.sh
   # Usage: ./ops/scripts/setup_ec2.sh <DD_API_KEY> <DOCKER_USERNAME>
   ./ops/scripts/setup_ec2.sh your_datadog_key your_dockerhub_user

   # IMPORTANT: Log out and log back in for group changes to take effect!
   exit
   # Then SSH back in: ssh -i key.pem ubuntu@<PUBLIC-IP>

4. Clone & Run:
   git clone -b phase-1-source --single-branch https://github.com/mkdevops89/amazon-clone-devops.git
   cd amazon-clone-devops
   docker compose up -d --build

5. Access:
   http://<PUBLIC-IP>:3000
