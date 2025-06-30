#agent.py
import asyncio
import websockets
import json
import subprocess
import psutil
import socket

SERVER_URL = "ws://ip:8000/ws"

def get_ip():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        return "unknown"

async def send_data(websocket):
    while True:
        cpu = psutil.cpu_percent(interval=1)
        ram = psutil.virtual_memory()
        disk = psutil.disk_usage('/')

        try:
            block_output = subprocess.check_output(
                "journalctl -u humanode-peer.service -n 10 -o cat | grep -oP '#\\K[0-9]+' | tail -n1",
                shell=True,
                text=True
            ).strip()
            block = int(block_output) if block_output else 0
        except Exception:
            block = 0

        data = {
            "hostname": get_ip(),
            "cpu": cpu,
            "cpu_cores": psutil.cpu_count(logical=True),
            "ram": ram.percent,
            "ram_total": round(ram.total / (1024**3), 2),
            "disk": disk.percent,
            "disk_total": round(disk.total / (1024**3), 2),
            "block": block
        }

        await websocket.send(json.dumps(data))
        await asyncio.sleep(5)

async def connect():
    while True:
        try:
            async with websockets.connect(SERVER_URL) as websocket:
                await send_data(websocket)
        except Exception as e:
            print(f"Connection error: {e}")
            await asyncio.sleep(5)

asyncio.run(connect())
