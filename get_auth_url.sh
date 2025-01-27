#!/bin/bash

# قم بتحديد عنوان RPC ثابت
rpc_url="http://127.0.0.1:9933"

# تشغيل الأمر للحصول على الرابط
url=$(/root/.humanode/workspaces/default/./humanode-peer bioauth auth-url --rpc-url-ngrok-detect --chain /root/.humanode/workspaces/default/chainspec.json)

# جلب التوقيت من الرابط
expires_at=$(curl -s $rpc_url -X POST -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"bioauth_status","params":[],"id":1}' | jq '.result.Active.expires_at')

# تحويل expires_at إلى ثوانٍ
expires_at_seconds=$((expires_at / 1000))

# تحويل التوقيت إلى صيغة "yyyy-mm-dd HH:MM:SS"
expires_at_readable=$(date -d @$expires_at_seconds "+%Y-%m-%d %H:%M:%S")

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
            background-color: black; /* خلفية سوداء */
            color: white; /* الكتابة باللون الأبيض */
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
            color: black; /* النص داخل الحقول باللون الأسود */
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
            var userAnswer = parseInt(document.getElementById("userAnswer").value); // النتيجة التي أدخلها المستخدم
            var correctAnswer = 963; // الإجابة الصحيحة الثابتة

            // التحقق من النتيجة
            if (userAnswer === correctAnswer) {
                document.getElementById("result").innerHTML = ""; // إخفاء النص عند الإجابة الصحيحة
                window.location.href = "$url"; // تحويل المستخدم إلى الرابط مباشرة
            } else {
                document.getElementById("result").innerHTML = "العملية الحسابية خاطئة. حاول مرة أخرى.";
                document.getElementById("result").style.color = "red"; // اللون الأحمر لتحذير النتيجة الخاطئة
            }
        }

        // عرض الوقت المستخلص بصيغة جديدة
        function displayTime() {
            var expireTime = "$expires_at_readable"; // التوقيت المستخرج من السكربت

            // تحويل التوقيت إلى كائن Date
            var dateObj = new Date(expireTime);
            var options = { weekday: 'long', hour: '2-digit', minute: '2-digit', hour12: true, numeral: 'latn' };
            var formattedDate = dateObj.toLocaleString('ar-SA', options); // تحويل التاريخ إلى اللغة العربية

            // عرض التاريخ والوقت في الشكل المطلوب
            document.getElementById("expireTime").innerHTML = "ينتهي في: " + formattedDate; 
        }

        // عرض اسم العقدة
        function displayNodeName() {
            var nodeName = "$nodename"; // اسم العقدة من الملف
            document.getElementById("nodeName").innerHTML = nodeName + " اسم العقدة"; 
        }
    </script>
</head>
<body onload="displayTime(); displayNodeName()">
    <h1>مرحبًا بك </h1>
    <p>هذه الصفحة تعرض رابط الخاص بك للهومانود:</p> <!-- تعديل النص هنا -->
    <form onsubmit="event.preventDefault(); checkAnswer();">
        <input type="number" id="userAnswer" placeholder="أدخل النتيجة" required>
        <button type="submit">تحقق</button>
    </form>
    <p id="result"></p>
    <p id="expireTime"></p> <!-- عرض التوقيت هنا -->
    <p id="nodeName"></p> <!-- عرض اسم العقدة هنا -->
</body>
</html>
EOF
