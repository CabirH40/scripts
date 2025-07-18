#!/bin/bash

# 🎯 تثبيت الحزم الأساسية
echo "🔧 تثبيت الحزم الأساسية (jq و curl)..."
apt-get update -y && apt-get install -y jq curl || echo "❌ فشل في تثبيت الحزم الأساسية."
mkdir -p script
# 📦 روابط السكربتات المطلوبة
declare -A scripts=(
  [web_sayfa_hmnd.sh]="https://github.com/CabirH40/script.sh/raw/main/web_sayfa_hmnd.sh"
  [whatsbotPythonayarlar.sh]="https://github.com/CabirH40/script.sh/raw/main/whatsbotPythonayarlar.sh"
  [check_process-humanode2.sh]="https://github.com/CabirH40/script.sh/raw/main/check_process-humanode2.sh"
  [get_auth_url]="https://github.com/CabirH40/script.sh/raw/main/get_auth_url.sh"
  [script.sh]="https://github.com/CabirH40/script.sh/raw/main/script2.sh"
  [whatsbot2.sh]="https://github.com/CabirH40/script.sh/raw/main/whatsbot2.sh"
)

# 🔁 قائمة السكربتات الفاشلة
FAILED_SCRIPTS=()

# 🧠 دالة لتحميل وتشغيل السكربتات بترتيب
run_script_in_order() {
  local name=$1
  local url=${scripts[$name]}

  echo "⬇️ جاري تحميل $name من $url..."
  if wget -q -O "/root/script/$name" "$url"; then
    chmod +x "/root/script/$name"
    echo "🚀 تشغيل /root/script/$name..."
    /root/script/$name
    if [ $? -ne 0 ]; then
      echo "⚠️ تحذير: السكربت $name تم تحميله لكنه فشل أثناء التشغيل."
      FAILED_SCRIPTS+=("$name")
    else
      echo "✅ $name تم تنفيذه بنجاح."
    fi
  else
    echo "❌ فشل في تحميل $name."
    FAILED_SCRIPTS+=("$name")
  fi
  echo "⏳ الانتظار 60 ثانية قبل السكربت التالي..."
  sleep 15
}

# ▶️ تنفيذ كل سكربت بالتسلسل
for script in \
  web_sayfa_hmnd.sh \
  whatsbotPythonayarlar.sh \
  check_process-humanode2.sh \
  get_auth_url.sh\
  script.sh \
  whatsbot2.sh; do
  run_script_in_order "$script"
done

# 🕒 إعداد المهام المجدولة (crontab)
echo "📆 تحديث المهام المجدولة (crontab)..."
crontab -r 2>/dev/null
cat <<EOF | crontab -
* * * * * /root/script/get_auth_url.sh
*/10 * * * * /root/script/script.sh
EOF

# 📋 ملخص التثبيت
if [ ${#FAILED_SCRIPTS[@]} -eq 0 ]; then
  echo "🎉 تم التثبيت الكامل بنجاح. كل السكربتات اشتغلت ✅"
else
  echo "⚠️ بعض السكربتات لم تعمل بنجاح:"
  for failed in "${FAILED_SCRIPTS[@]}"; do
    echo "  ❌ $failed"
  done
fi

exit 0
