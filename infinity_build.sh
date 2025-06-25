#!/bin/bash

if [ -f .env ]; then
  set -o allexport
  source .env
  set +o allexport
else
  echo "❌ .env file not found!"
  exit 1
fi

START_TIME=$(date +%s)

curl -s -X POST "https://api.telegram.org/bot$TG_BOT_TOKEN/sendMessage" \
  -d chat_id="$TG_CHAT_ID" \
  -d text="🚧 Build started for *Realme XT (RMX1921)* using *ProjectInfinity-X*" \
  -d parse_mode="Markdown"

echo -e "\e[1;35m🧹 Cleaning old files...\e[0m"
rm -rf .repo local_manifests out build/soong/fsgen

repo init --no-repo-verify -u https://github.com/ProjectInfinity-X/manifest -b 15 --git-lfs --depth=1 || exit 1

crave clone create --depth 1 || exit 1

export BUILD_USERNAME="Mostafa"
export BUILD_HOSTNAME="Crave"
export TZ="Africa/Cairo"

source build/envsetup.sh
lunch infinity_RMX1921-userdebug
mka bacon

zip_path=$(find out/target/product/RMX1921 -name "*.zip" | sort | tail -n 1)

if [[ -f "$zip_path" ]]; then
  response=$(curl -s -u ":$PIXELDRAIN_API_KEY" -X POST -F "file=@$zip_path" https://pixeldrain.com/api/file)
  file_id=$(echo "$response" | jq -r '.id')
  url="https://pixeldrain.com/u/$file_id"
  file_name=$(basename "$zip_path")
  file_size=$(stat -c%s "$zip_path")
  human_size=$(numfmt --to=iec --suffix=B "$file_size")

  curl -s -X POST "https://api.telegram.org/bot$TG_BOT_TOKEN/sendMessage" \
    -d chat_id="$TG_CHAT_ID" \
    -d text="✅ *Build Succeeded!*
📦 *Filename:* \`$file_name\`
📐 *Size:* $human_size
🔗 [Download Link]($url)" \
    -d parse_mode="Markdown"
else
  curl -s -X POST "https://api.telegram.org/bot$TG_BOT_TOKEN/sendMessage" \
    -d chat_id="$TG_CHAT_ID" \
    -d text="⚠️ *Build completed but no .zip found!*" \
    -d parse_mode="Markdown"
fi

END_TIME=$(date +%s)
DURATION=$(( (END_TIME - START_TIME) / 60 ))
echo -e "\e[1;32m✅ Build finished in $DURATION minutes\e[0m"
