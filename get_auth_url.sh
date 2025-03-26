#!/bin/bash

# تحديد عنوان RPC ثابت
rpc_url="http://127.0.0.1:9944"

# تشغيل الأمر للحصول على الرابط
url=$(/root/.humanode/workspaces/default/./humanode-peer bioauth auth-url --rpc-url-ngrok-detect --chain /root/.humanode/workspaces/default/chainspec.json)

# جلب حالة bioauth
bioauth_status=$(curl -s $rpc_url -X POST -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"bioauth_status","params":[],"id":1}' | jq -r '.result')

# جلب اسم العقدة من workspace.json
workspace_file="/root/.humanode/workspaces/default/workspace.json"
nodename=$(jq -r '.nodename' $workspace_file)

# إنشاء صفحة HTML
cat <<EOF > /root/website/index.html
<!DOCTYPE html>
<html lang="ar">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Humanode</title>
    <link href="https://fonts.googleapis.com/css2?family=Roboto:wght@400;700&display=swap" rel="stylesheet">
    <style>
        body {
            font-family: 'Roboto', sans-serif;
            background-color: #121212;
            color: white;
            text-align: center;
            padding: 20px;
            margin: 0;
        }
        
        h1 {
            font-size: 2.5em;
            margin-bottom: 20px;
            color: #FF0000;
        }
        
        p {
            font-size: 1.2em;
            margin-bottom: 20px;
        }

        #link {
            display: inline-block;
            padding: 12px 25px;
            background-color: #28a745;
            color: white;
            text-decoration: none;
            border-radius: 10px;
            margin-top: 30px;
            font-size: 1.2em;
            box-shadow: 0 5px 15px rgba(0, 0, 0, 0.2);
            transition: background-color 0.3s, transform 0.3s;
        }

        #link:hover {
            background-color: #218838;
            transform: scale(1.05);
        }

        .warning {
            color: #FF4500;
            font-size: 1.4em;
            font-weight: bold;
            margin-top: 30px;
        }

        .time-info {
            background-color: #333333;
            padding: 20px;
            margin-top: 40px;
            border-radius: 8px;
            box-shadow: 0 4px 10px rgba(0, 0, 0, 0.2);
        }

        .time-info p {
            font-size: 1.3em;
        }

        @media (max-width: 600px) {
            h1 {
                font-size: 2em;
            }

            p {
                font-size: 1em;
            }

            #link {
                padding: 10px 20px;
                font-size: 1em;
            }

            .time-info p {
                font-size: 1em;
            }
        }

    </style>
</head>
<body>
    <h1>مرحبًا بك في صفحة الهومانود</h1>
    <p>هذه الصفحة تعرض رابط الخاص بك للهومانود:</p>
    <p id="nodeName">$nodename - اسم العقدة</p>
EOF

# التحقق من حالة bioauth_status
if [[ "$bioauth_status" == "Inactive" ]]; then
    # إذا كانت الحالة inactive، نعرض التحذير
    echo "<p class='warning'>⚠ يجب إعادة التصوير</p>" >> /root/website/index.html
    echo "<a id='link' href='$url' target='_blank'>اذهب إلى الرابط</a>" >> /root/website/index.html
else
    # إذا لم تكن inactive (أي active أو حالة أخرى)، نحسب الوقت المتبقي
    expires_at=$(curl -s $rpc_url -X POST -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"bioauth_status","params":[],"id":1}' | jq '.result.Active.expires_at')

    # تحويل expires_at إلى ثوانٍ
    expires_at_seconds=$((expires_at / 1000))

    # حساب الفرق الزمني
    current_time=$(date +%s)
    difference=$(( expires_at_seconds - current_time ))

    # حساب الأيام، الساعات، والدقائق المتبقية
    remaining_days=$(( difference / 86400 ))
    remaining_hours=$(( (difference % 86400) / 3600 ))
    remaining_minutes=$(( (difference % 3600) / 60 ))

    # حساب التاريخ والوقت الذي سينتهي فيه الوقت المتبقي
    end_time_seconds=$((current_time + difference))
    end_time_turkey=$(TZ="Europe/Istanbul" date -d @$end_time_seconds +"%Y-%m-%d %H:%M:%S")

    echo "<div class='time-info'>" >> /root/website/index.html
    echo "<p>الوقت المتبقي: $remaining_days يوم $remaining_hours ساعة $remaining_minutes دقيقة</p>" >> /root/website/index.html
    echo "<p>الوقت الذي سينتهي فيه: $end_time_turkey</p>" >> /root/website/index.html
    echo "</div>" >> /root/website/index.html

    # الزر يظهر عندما تكون الحالة غير inactive
    echo "<a id='link' href='$url' target='_blank'>اذهب إلى الرابط</a>" >> /root/website/index.html
fi

echo "</body></html>" >> /root/website/index.html
