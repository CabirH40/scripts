import asyncio
import websockets
import json
import subprocess
import psutil
import socket

SERVER_URL = "ws://141.98.115.104:8000/ws"

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
    prev_net = psutil.net_io_counters()
    while True:
        cpu = psutil.cpu_percent(interval=1)
        ram = psutil.virtual_memory()
        disk = psutil.disk_usage('/')

        current_net = psutil.net_io_counters()
        delta_sent = current_net.bytes_sent - prev_net.bytes_sent
        delta_recv = current_net.bytes_recv - prev_net.bytes_recv

        sent_mb = round(delta_sent / (1024 * 1024), 2)
        recv_mb = round(delta_recv / (1024 * 1024), 2)

        prev_net = current_net

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
            "block": block,
            "net_sent_avg": sent_mb,      # الآن يعطي الصرف منذ آخر إرسال
            "net_recv_avg": recv_mb       # الآن يعطي الصرف منذ آخر إرسال
        }

        print(data)
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




