#/backend/main.py
from fastapi import FastAPI, WebSocket, WebSocketDisconnect, Request
from fastapi.responses import HTMLResponse
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
import uvicorn
import json
import paramiko

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.mount("/static", StaticFiles(directory="../frontend", html=True), name="static")

servers_data = {}

ADMIN_USERNAME = "admin"
ADMIN_PASSWORD = "admin"

@app.get("/api/status")
def status():
    return {"message": "Server is running"}

@app.post("/api/login")
async def login(request: Request):
    form_data = await request.json()
    username = form_data.get("username")
    password = form_data.get("password")

    if username == ADMIN_USERNAME and password == ADMIN_PASSWORD:
        return {"success": True}
    else:
        return {"success": False}

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    try:
        while True:
            data = await websocket.receive_text()
            server_info = json.loads(data)
            hostname = server_info.get("hostname", "unknown")

            servers_data[hostname] = {
                "cpu": server_info.get("cpu"),
                "cpu_cores": server_info.get("cpu_cores"),
                "ram": server_info.get("ram"),
                "ram_total": server_info.get("ram_total"),
                "disk": server_info.get("disk"),
                "disk_total": server_info.get("disk_total"),
                "block": server_info.get("block"),
                "services": server_info.get("services", {})
            }
    except WebSocketDisconnect:
        servers_data.pop(hostname, None)
    except Exception as e:
        print(f"Error: {e}")
        servers_data.pop(hostname, None)


@app.get("/api/servers")
def get_servers():
    return servers_data

@app.post("/api/restart_tunnel")
async def restart_tunnel(request: Request):
    body = await request.json()
    ip_address = body.get("ip")
    
    if not ip_address:
        return {"success": False, "message": "IP address not provided"}

    SSH_USER = "root"
    SSH_PASSWORD = "Meymatibasimiz47."  # 🔥 كلمة السر هنا

    try:
        client = paramiko.SSHClient()
        client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        client.connect(ip_address, username=SSH_USER, password=SSH_PASSWORD)

        # ✨ تنفيذ أمرين معاً
        commands = [
            "sudo systemctl restart humanode-tunnel.service",
            "sudo systemctl restart whatsbot.service"
        ]

        full_output = ""
        full_error = ""

        for command in commands:
            stdin, stdout, stderr = client.exec_command(command)
            full_output += stdout.read().decode()
            full_error += stderr.read().decode()

        client.close()

        if full_error:
            return {"success": False, "message": full_error}
        return {"success": True, "message": full_output}

    except Exception as e:
        return {"success": False, "message": str(e)}

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
