#!/bin/bash

# 👑 EvolutionX GApps Auto Build Script for RMX1921

# ============ تحميل بيانات .env ============
if [ -f .env ]; then
  set -o allexport
  source .env
  set +o allexport
else
  echo "❌ .env file not found!"
  exit 1
fi

START_TIME=$(date +%s)

# ============ Telegram: بدأ البناء ============
curl -s -X POST "https://api.telegram.org/bot$TG_BOT_TOKEN/sendMessage" \
  -d "chat_id=$TG_CHAT_ID" \
  -d "text=🚀 Build (GApps) started for *Realme XT (RMX1921)* using *EvolutionX*" \
  -d "parse_mode=Markdown"

echo -e "\e[1;35m🧹 Cleaning old files...\e[0m"
rm -rf out/target/product/RMX1921
echo -e "\e[1;32m✅ Cleaned.\e[0m"

# ============ تحميل السورسات ============
[ ! -d device/realme/RMX1921 ] && git clone --depth=1 -b 15-matrixx https://github.com/kaderbava/device_realme_RMX1921.git device/realme/RMX1921
[ ! -d vendor/realme/RMX1921 ] && git clone --depth=1 -b 15 https://gitlab.com/kaderbava/vendor_realme_RMX1921.git vendor/realme/RMX1921
[ ! -d kernel/realme/sdm710 ] && git clone --depth=1 -b 14-r5p https://github.com/kaderbava/android_kernel_realme_sdm710.git kernel/realme/sdm710
[ ! -d prebuilts/clang/host/linux-x86/clang-proton ] && git clone --depth=1 https://github.com/kdrag0n/proton-clang.git prebuilts/clang/host/linux-x86/clang-proton

# ============ إعداد البيئة ============
source build/envsetup.sh
lunch evolution_RMX1921-user
mka installclean
mka bacon -j$(nproc) || {
  curl -s -X POST "https://api.telegram.org/bot$TG_BOT_TOKEN/sendMessage" \
    -d "chat_id=$TG_CHAT_ID" \
    -d "text=❌ *Build failed for RMX1921 (GApps)*" \
    -d "parse_mode=Markdown"
  exit 1
}

# ============ رفع الملف ============
upload_latest_zip() {
  zip_path=$(find out/target/product/RMX1921 -name "*.zip" -printf "%T@ %p\n" | sort -n | tail -1 | cut -d' ' -f2-)

  if [[ -f "$zip_path" ]]; then
    echo -e "\e[1;36m⬆ Uploading to Pixeldrain...\e[0m"

    response=$(curl -s -u ":$PIXELDRAIN_API_KEY" \
      -X POST -F "file=@$zip_path" https://pixeldrain.com/api/file)

    file_id=$(echo "$response" | jq -r '.id')
    file_name=$(basename "$zip_path")
    file_size=$(numfmt --to=iec --suffix=B "$(stat -c%s "$zip_path")")
    upload_date=$(date +"%Y-%m-%d %H:%M")

    if [[ "$file_id" != "null" ]]; then
      url="https://pixeldrain.com/u/$file_id"

      curl -s -X POST "https://api.telegram.org/bot$TG_BOT_TOKEN/sendMessage" \
        -d "chat_id=$TG_CHAT_ID" \
        -d "text=✅ *GApps Build Success!*\n\n📎 *Filename:* \`$file_name\`\n📦 *Size:* $file_size\n🕓 *Date:* $upload_date\n🔗 [Download Link]($url)" \
        -d "parse_mode=Markdown"
      echo -e "\e[1;32m✅ Uploaded: $url\e[0m"
    else
      echo -e "\e[1;31m❌ Upload failed.\e[0m"
    fi
  else
    echo -e "\e[1;31m❌ No zip found!\e[0m"
  fi
}

upload_latest_zip

# ============ إنهاء ============
END_TIME=$(date +%s)
DURATION=$(( (END_TIME - START_TIME) / 60 ))
echo -e "\e[1;32m✅ GApps Build finished in $DURATION minutes\e[0m"
