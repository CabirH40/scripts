#!/bin/bash

# تحديد عنوان RPC ثابت
rpc_url="http://127.0.0.1:9933"

# تشغيل الأمر للحصول على الرابط
url=$(/root/.humanode/workspaces/default/./humanode-peer bioauth auth-url --rpc-url-ngrok-detect --chain /root/.humanode/workspaces/default/chainspec.json)

# جلب التوقيت من الرابط
expires_at=$(curl -s $rpc_url -X POST -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"bioauth_status","params":[],"id":1}' | jq '.result.Active.expires_at')

# تحويل expires_at إلى ثوانٍ
expires_at_seconds=$((expires_at / 1000))

# حساب الوقت المتبقي
current_time=$(date +%s)
difference=$(( expires_at_seconds - current_time ))

# حساب الأيام، الساعات، والدقائق المتبقية
remaining_days=$(( difference / 86400 ))
remaining_hours=$(( (difference % 86400) / 3600 ))
remaining_minutes=$(( (difference % 3600) / 60 ))

# جلب اسم العقدة من الملف workspace.json
workspace_file="/root/.humanode/workspaces/default/workspace.json"
nodename=$(jq -r '.nodename' $workspace_file)

# طباعة رابط HTML مع نموذج إدخال النتيجة
cat <<EOF > /root/website/index.html
<!DOCTYPE html>
<html lang="ar">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Humanode</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background-color: black;
            color: white;
            text-align: center;
            padding: 50px;
        }
        
        h1 {
            font-size: 2.5em;
            margin-bottom: 20px;
        }
        
        p {
            font-size: 1.2em;
            margin-bottom: 20px;
        }

        input {
            padding: 10px;
            font-size: 1em;
            border-radius: 5px;
            border: 1px solid #ccc;
            color: black;
        }

        button {
            padding: 10px 20px;
            font-size: 1em;
            background-color: #007BFF;
            color: white;
            border: none;
            border-radius: 5px;
            cursor: pointer;
        }

        button:hover {
            background-color: #0056b3;
        }

        #result {
            font-size: 1.5em;
            margin-top: 20px;
        }

        #expireTime {
            font-size: 1.2em;
            margin-top: 20px;
        }

        #link {
            display: inline-block;
            padding: 10px 20px;
            background-color: #007BFF;
            color: white;
            text-decoration: none;
            border-radius: 5px;
            margin-top: 30px;
        }

        #link:hover {
            background-color: #0056b3;
        }
    </style>
    <script>
        // إنشاء أرقام ثابتة
        function checkAnswer() {
            var userAnswer = parseInt(document.getElementById("userAnswer").value);
            var correctAnswer = 963;

            if (userAnswer === correctAnswer) {
                document.getElementById("result").innerHTML = "";
                document.getElementById("link").style.display = "inline-block";
            } else {
                document.getElementById("result").innerHTML = "العملية الحسابية خاطئة. حاول مرة أخرى.";
                document.getElementById("result").style.color = "red";
                document.getElementById("link").style.display = "none";
            }
        }

        // عرض الوقت المتبقي
        function displayRemainingTime() {
            var remainingDays = "$remaining_days";
            var remainingHours = "$remaining_hours";
            var remainingMinutes = "$remaining_minutes";

            document.getElementById("remainingTime").innerHTML = "الوقت المتبقي: " + remainingDays + " يوم " + remainingHours + " ساعة " + remainingMinutes + " دقيقة";
        }

        // عرض اسم العقدة
        function displayNodeName() {
            var nodeName = "$nodename";
            document.getElementById("nodeName").innerHTML = nodeName + " اسم العقدة"; 
        }
    </script>
</head>
<body onload="displayRemainingTime(); displayNodeName()">
    <h1>مرحبًا بك</h1>
    <p>هذه الصفحة تعرض رابط الخاص بك للهومانود:</p>
    <form onsubmit="event.preventDefault(); checkAnswer();">
        <input type="number" id="userAnswer" placeholder="أدخل النتيجة" required>
        <button type="submit">تحقق</button>
    </form>
    <p id="result"></p>
    <p id="remainingTime"></p> <!-- عرض الوقت المتبقي -->
    <p id="nodeName"></p>
    <a id="link" href="$url" target="_blank" style="display: none;">اذهب إلى الرابط</a>
</body>
</html>
EOF
