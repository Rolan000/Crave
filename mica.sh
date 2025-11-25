#!/bin/bash

# ================================
# Settings LIbs
# ================================
sudo apt update
sudo apt install -y bc bison build-essential ccache curl flex g++-multilib gcc-multilib git git-lfs gnupg gperf imagemagick lib32ncurses-dev lib32readline-dev lib32z1-dev liblz4-tool libncurses6 libncurses-dev libsdl1.2-dev libssl-dev libwxgtk3.2-dev libxml2 libxml2-utils lzop pngcrush rsync schedtool squashfs-tools xsltproc zip zlib1g-dev p7zip-full unzip lzip apktool 

# ================================
# Clean old manifests
# ================================
echo -e ">>> Cleaning old local manifests Or Old device trees if exists"
rm -rf .repo/local_manifests/
rm -rf device/xiaomi/miatoll
rm -rf vendor/xiaomi/miatoll
rm -rf kernel/xiaomi/sm6250
rm -rf hardware/xiaomi
rm -rf vendor/xiaomi/miuicamera-miatoll
rm -rf hardware/sony/timekeep


# ================================
# Initialize MicaOS repo
# ================================
echo -e ">>> Initializing MicaOS repository"
repo init -u https://github.com/Project-Mica/manifest -b 16-qpr1
echo -e ">>> Downloading MicaOS local manifests"
echo -e ">>> Please wait, this may take a while..."
echo -e ">>> Cloning MicaOS local manifests"
echo -e ">>> Done"


# ================================
# Clone device/vendor/kernel trees
# ================================
echo -e ">>> Cloning Device Trees"
echo -e ">>> Cloning Device, Vendor, Kernel and Hardware Trees"
echo -e ">>> Please wait, this may take a while..."
echo -e ">>> Cloning Device Tree: xiaomi/miatoll"
git clone https://github.com/MiatollForAll/device_xiaomi_miatoll.git -b mic device/xiaomi/miatoll
echo -e ">>> Done"
echo -e ">>> Cloning Vendor Tree: xiaomi/vendor"
git clone https://github.com/MiatollForAll/vendor_xiaomi_miatoll.git -b 16 vendor/xiaomi/miatoll
echo -e ">>> Done"
echo -e ">>> Cloning Kernel Tree: xiaomi/sm6250"
git clone https://github.com/MiatollForAll/kernel_xiaomi_miatoll.git -b 16 kernel/xiaomi/sm6250
echo -e ">>> Done"
echo -e ">>> Cloning Hardware Tree: xiaomi/hardware_xiaomi"
git clone https://github.com/LineageOS/android_hardware_xiaomi.git -b lineage-23.0 hardware/xiaomi
echo -e ">>> Done"
echo -e ">>> Cloning Additional Hardware Trees"
git clone https://github.com/LineageOS/android_hardware_sony_timekeep.git -b lineage-22.2 hardware/sony/timekeep
echo -e ">>> Done"
echo -e ">>> Cloning MIUI Camera Vendor Tree: xiaomi/miuicamera"
git clone https://github.com/MiatollForAll/vendor_xiaomi_miuicamera-miatoll.git -b 16 vendor/xiaomi/miuicamera-miatoll
echo -e ">>> Done"
echo -e ">>> All Device, Vendor, Kernel and Hardware Trees Cloned Successfully"
echo -e ">>> Proceeding to sync remaining sources..."
echo -e ">>> Please wait, this may take a while..."
# ================================
# Sync remaining sources
# ================================
echo -e ">>> Syncing repo"

if [ -f /opt/crave/resync.sh ]; then
    echo "[INFO] Running /opt/crave/resync.sh ..."
    bash /opt/crave/resync.sh
else
    echo "[INFO] /opt/crave/resync.sh not found. Running repo sync instead..."
    repo sync -c -j8 --force-sync --no-clone-bundle --no-tags
fi

echo "[INFO] Running GMS generation script..."

pushd vendor/gms >/dev/null
bash generate-gms.sh
popd >/dev/null


echo -e ">>> Repo sync completed"
echo -e ">>> Proceeding to build setup..."
echo -e ">>> Please wait..."
# ================================
# Setup build environment
# ================================
source build/envsetup.sh
echo -e ">>> Build environment setup completed"
echo -e ">>> Proceeding to apply MicaOS build flags..."
echo -e ">>> Please wait..."

# ================================
# Start build
# ================================
echo ">>> Starting MicaOS Build"
echo -e ">>> Building MicaOS for Xiaomi Miatoll"
export TZ=Africa/Cairo
echo -e ">>> Timezone set to Africa/Cairo"
lunch mica_miatoll-bp3a-userdebug
echo -e ">>> Build command executed: riseup miatoll user"
echo -e ">>> Build process initiated. This may take several hours."
echo -e ">>> You can monitor the build progress above."
m mica-release
echo -e ">>> Build command executed: rise b"
echo -e ">>> MicaOS Build process completed"
echo -e ">>> You can find the built ROM in the out/target/product/miatoll/ directory"
echo -e ">>> Thank you for using this build script. Goodbye!"

# ============================================================
# Upload ROM(s) to PixelDrain automatically + Telegram notify
# ============================================================
echo -e ">>> Searching for ZIP ROM files..."

ROM_DIR="out/target/product/miatoll"
API_KEY="cfb7aad5-0c4b-401b-b5dc-730b71be72a3"

# === Telegram data ===
TELEGRAM_BOT_TOKEN="8235509838:AAHUfOBE7Ni1I1xbX4zOg63TtMtXxsoUEhw"
TELEGRAM_CHAT_ID="-1003121331954"

# Find ANY .zip file
ROM_FILES=$(find "$ROM_DIR" -maxdepth 1 -type f -name "*.zip" -printf "%f\n")

if [[ -z "$ROM_FILES" ]]; then
    echo -e ">>> ERROR: No ZIP ROM files found!"
    exit 1
fi

echo -e ">>> Found ZIP files:"
echo "$ROM_FILES"

for FILE in $ROM_FILES; do
    echo -e "\n>>> Uploading file: $FILE"
    
    UPLOAD_RESPONSE=$(curl -s -T "$ROM_DIR/$FILE" -u :$API_KEY https://pixeldrain.com/api/file/)
    FILE_ID=$(echo $UPLOAD_RESPONSE | grep -o '"id":"[^"]*"' | cut -d '"' -f4)
    
    if [[ -n "$FILE_ID" ]]; then
        DOWNLOAD_LINK="https://pixeldrain.com/u/$FILE_ID"
        echo -e ">>> Upload Successful: $DOWNLOAD_LINK"

        # Extract build date only if present in filename
        BUILD_DATE=$(echo "$FILE" | grep -o "[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}")
        [[ -z "$BUILD_DATE" ]] && BUILD_DATE="Unknown"

        UPLOADED_TIME=$(date "+%Y-%m-%d %H:%M:%S")

        MESSAGE="📱 *Build Uploaded Successfully*  
        
*File:* \`${FILE}\`
*Build Date:* ${BUILD_DATE}
*Uploaded:* ${UPLOADED_TIME}

*Download Link:*  
${DOWNLOAD_LINK}"

        curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
            -d chat_id="${TELEGRAM_CHAT_ID}" \
            -d text="$MESSAGE" \
            -d parse_mode="Markdown"

        echo -e ">>> Telegram notification sent!"
    else
        echo ">>> Upload FAILED!"
        echo "Response: $UPLOAD_RESPONSE"
    fi
done

echo -e ">>> All uploads completed successfully!"

echo -e ">>> All uploads completed successfully!"
