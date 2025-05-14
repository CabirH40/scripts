# 🖥️ Server Monitoring Scripts

This folder contains lightweight and customizable Bash scripts to help monitor and manage remote servers from a centralized monitoring server.

---

## 📁 Structure

- `server_monitoring/`
  - `agent.sh` → This script runs on the **monitoring server**.
  - Other helper scripts may also reside here, depending on your setup.

---

## 🧩 Use Case

- 🧠 **Main server**: The target server that you want to monitor.  
- 👁️‍🗨️ **Monitoring server**: The server that runs the `agent.sh` script to check the health and availability of the main server(s).

---

## ⚙️ Requirements

- Linux OS (Ubuntu/Debian/CentOS, etc.)
- Bash shell
- SSH access between servers
- Basic Unix tools: `ping`, `curl`, `top`, `grep`, `awk`

---

## 🛠️ Installation & Setup

### 🔸 On the **Main Server** (server being monitored)

No special installation is needed. Just ensure:
- The SSH service is active
- You place any required scripts or config files inside `/opt/server_monitoring/` or your custom path
- You allow SSH access from the monitoring server (preferably using key-based authentication)

### 🔹 On the **Monitoring Server**

```bash
# Go to working directory
cd /opt/

# Clone the GitHub repository
git clone https://github.com/CabirH40/scripts.git

# Navigate to the monitoring folder
cd scripts/server_monitoring

# Make scripts executable
chmod +x *.sh
```

---

## ▶️ Usage

To run the monitoring manually:

```bash
./agent.sh
```

Or, schedule it with cron for automated periodic checks:

```bash
*/5 * * * * /opt/scripts/server_monitoring/agent.sh >> /var/log/server_monitor.log 2>&1
```

---

## 📌 Tips

- Set up SSH key-based authentication to avoid password prompts.
- You can extend the scripts to send alerts via:
  - Telegram bots
  - Email
  - Discord webhooks
- Ideal for managing 5 to 100+ servers easily via scripts.

---

## 🤝 Contributions

Feel free to fork the repo, submit issues, or create pull requests to improve the toolset!

---

## 📄 License

MIT License – Use it freely and adapt it as needed.

---

🧠 Built with care by [CabirH40](https://github.com/CabirH40)
