const API_URL = "http://141.98.115.104:8000/api";

async function login() {
    const username = document.getElementById("username").value;
    const password = document.getElementById("password").value;

    const response = await fetch(`${API_URL}/login`, {
        method: "POST",
        headers: {
            "Content-Type": "application/json",
        },
        body: JSON.stringify({ username, password }),
    });

    const result = await response.json();

    if (result.success) {
        document.getElementById("login-section").style.display = "none";
        document.getElementById("dashboard-section").style.display = "block";
        startFetchingServers();
    } else {
        document.getElementById("login-error").innerText = "❌ خطأ في تسجيل الدخول";
    }
}

let servers = {};
let currentSortField = null;
let currentSortDirection = 'desc';

function createProgressBar(percentage, extraText = "") {
    let color = "#4caf50"; // أخضر
    if (percentage > 70) color = "#ffc107"; // أصفر
    if (percentage > 90) color = "#f44336"; // أحمر

    return `
        <div class="progress-container">
            <div class="progress-bar" style="width: ${percentage}%; background-color: ${color};">
                ${percentage}% ${extraText}
            </div>
        </div>
    `;
}


function renderTable() {
    const tbody = document.getElementById("servers-body");
    tbody.innerHTML = "";

    let serverEntries = Object.entries(servers);

    const searchQuery = document.getElementById("searchInput").value.toLowerCase();

    if (currentSortField) {
        serverEntries.sort((a, b) => {
            let aValue = a[1][currentSortField];
            let bValue = b[1][currentSortField];

            if (currentSortDirection === 'desc') {
                return bValue - aValue;
            } else {
                return aValue - bValue;
            }
        });
    }

    let counter = 1; // ✅ عداد يبدأ من 1
    for (const [hostname, data] of serverEntries) {
        const row = document.createElement("tr");
    
        row.innerHTML = `
            <td>${counter++}</td> <!-- ✅ رقم السيرفر -->
            <td>${hostname}</td>
            <td>${createProgressBar(data.cpu, `(${data.cpu_cores} cores)` )}</td>
            <td>${createProgressBar(data.ram, `(${data.ram_total} GB)` )}</td>
            <td>${createProgressBar(data.disk, `(${data.disk_total} GB)` )}</td>
            <td>${data.block}</td>
            <td>${renderServiceStatus(data.services)}</td>
            <td>
                <button onclick="restartTunnel('${hostname}')" class="restart-button">
                    🔄 إعادة تشغيل التونيل والواتسبوت
                </button>
            </td>
        `;
    
        tbody.appendChild(row);
    }
}

async function restartTunnel(ip) {
    if (!confirm(`هل تريد إعادة تشغيل التونيل والواتسبوت للسيرفر ${ip}؟`)) {
        return;
    }

    const response = await fetch(`${API_URL}/restart_tunnel`, {
        method: "POST",
        headers: {
            "Content-Type": "application/json",
        },
        body: JSON.stringify({ ip }),
    });

    const result = await response.json();

    if (result.success) {
        alert("✅ تم إعادة تشغيل التونيل والواتسبوت بنجاح");
    } else {
        alert("❌ حدث خطأ: " + result.message);
    }
}
function renderServiceStatus(services) {
    return `
        <div style="font-size: 11px; display: flex; gap: 6px; justify-content: center; flex-wrap: wrap;">
            <div> Tunnel ${formatStatus(services["humanode-tunnel"])}</div>
            <div> Whatsbot ${formatStatus(services["whatsbot"])}</div>
            <div> Peer ${formatStatus(services["humanode-peer"])}</div>
        </div>
    `;
}



function formatStatus(status) {
    if (status === "running" || status === "active") {
        return '<span style="color:green;">✅</span>';
    } else if (status === "inactive" || status === "failed") {
        return '<span style="color:red;">❌</span>';
    } else {
        return '<span style="color:gray;">❔</span>';
    }
}
async function restartAllTunnels() {
    if (!confirm("⚠️ هل أنت متأكد أنك تريد إعادة تشغيل التونيل لكل السيرفرات؟")) {
        return;
    }

    for (const hostname of Object.keys(servers)) {
        await restartTunnel(hostname);
        await new Promise(resolve => setTimeout(resolve, 300)); // انتظار بسيط بين كل طلب
    }
}

function startFetchingServers() {
    setInterval(async () => {
        const response = await fetch(`${API_URL}/servers`);
        servers = await response.json();
        renderTable();
    }, 3000);
}

function setSort(field) {
    if (currentSortField === field) {
        currentSortDirection = currentSortDirection === 'asc' ? 'desc' : 'asc';
    } else {
        currentSortField = field;
        currentSortDirection = 'desc';
    }
    renderTable();
}
