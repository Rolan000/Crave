#!/bin/bash

# ================================
# Clean old manifests
# ================================
echo -e ">>> Cleaning old local manifests Or Old device trees if exists"
rm -rf .repo/local_manifests/
rm -rf device/xiaomi/miatoll
rm -rf vendor/xiaomi/miatoll
rm -rf kernel/xiaomi/sm6250
rm -rf hardware/xiaomi
rm -rf vendor/xiaomi/miuicamera
rm -rf hardware/sony/timekeep


# ================================
# Initialize Evolution X repo
# ================================
echo -e ">>> Initializing Evolution X repository"
repo init -u https://github.com/Evolution-X/manifest -b bka --git-lfs
echo -e ">>> Downloading Evolution X local manifests"
echo -e ">>> Please wait, this may take a while..."
echo -e ">>> Cloning Evolution X local manifests"
echo -e ">>> Done"


# ================================
# Clone device/vendor/kernel trees
# ================================
echo -e ">>> Cloning Device Trees"
echo -e ">>> Cloning Device, Vendor, Kernel and Hardware Trees"
echo -e ">>> Please wait, this may take a while..."
echo -e ">>> Cloning Device Tree: xiaomi/miatoll"
git clone https://github.com/RisingMIatoll/device_xiaomi_miatoll.git -b evo device/xiaomi/miatoll
echo -e ">>> Done"
echo -e ">>> Cloning Common Device Tree: xiaomi/sm6250-common"
git clone https://github.com/RisingMIatoll/device_xiaomi_sm6250-common.git -b 16-volt device/xiaomi/sm6250-common
echo -e ">>> Done"
echo -e ">>> Cloning Vendor Tree: xiaomi/vendor"
git clone https://github.com/RisingMIatoll/vendor_xiaomi_miatoll.git -b 16 vendor/xiaomi/miatoll
echo -e ">>> Done"
echo -e ">>> Cloning Common Vendor Tree: xiaomi/sm6250-common"
git clone https://github.com/RisingMIatoll/vendor_xiaomi_sm6250-common.git -b 16 vendor/xiaomi/sm6250-common
echo -e ">>> Done"
echo -e ">>> Cloning Kernel Tree: xiaomi/sm6250"
git clone https://github.com/RisingMIatoll/kernel_xiaomi_sm6250.git -b 16.0 kernel/xiaomi/sm6250
echo -e ">>> Done"
echo -e ">>> Cloning Hardware Tree: xiaomi/hardware_xiaomi"
git clone https://github.com/LineageOS/android_hardware_xiaomi.git -b lineage-23.0 hardware/xiaomi
echo -e ">>> Done"
echo -e ">>> Cloning Additional Hardware Trees"
git clone https://github.com/LineageOS/android_hardware_sony_timekeep.git -b lineage-22.2 hardware/sony/timekeep
echo -e ">>> Done"
echo -e ">>> Cloning MIUI Camera Vendor Tree: xiaomi/miuicamera"
git clone https://github.com/RisingMIatoll/vendor_xiaomi_miuicamera-miatoll.git -b 16 vendor/xiaomi/miuicamera-miatoll
echo -e ">>> Done"
echo -e ">>> All Device, Vendor, Kernel and Hardware Trees Cloned Successfully"
echo -e ">>> Proceeding to sync remaining sources..."
echo -e ">>> Please wait, this may take a while..."
# ================================
# Sync remaining sources
# ================================
echo -e ">>> Syncing repo"

/opt/crave/resync.sh

echo -e ">>> Repo sync completed"
echo -e ">>> Proceeding to build setup..."
echo -e ">>> Please wait..."


export BUILD_USERNAME=AbdoElbanaa 
export BUILD_HOSTNAME=crave
export BUILD_BROKEN_MISSING_REQUIRED_MODULES=true

# ================================
# Setup build environment
# ================================
source build/envsetup.sh
echo -e ">>> Build environment setup completed"
echo -e ">>> Proceeding to apply Evolution X build flags..."
echo -e ">>> Please wait..."

# ================================
# Start build
# ================================
echo ">>> Starting Evolution X Build"
echo -e ">>> Building Evolution X for Xiaomi Miatoll"
export TZ=Africa/Cairo
echo -e ">>> Timezone set to Africa/Cairo"
lunch lineage_miatoll-bp2a-userdebug
echo -e ">>> Build command executed: riseup miatoll user"
echo -e ">>> Build process initiated. This may take several hours."
echo -e ">>> You can monitor the build progress above."
m evolution
echo -e ">>> Build command executed: rise b"
echo -e ">>> Evolution X Build process completed"
echo -e ">>> You can find the built ROM in the out/target/product/miatoll/ directory"
echo -e ">>> Thank you for using this build script. Goodbye!"

# ============================================================
# Upload ROM(s) to PixelDrain automatically + Telegram notify
# ============================================================
echo -e ">>> Searching for ROM files (Evolution X_Revived*)..."

ROM_DIR="out/target/product/miatoll"
API_KEY="cfb7aad5-0c4b-401b-b5dc-730b71be72a3"

# === Telegram data ===
TELEGRAM_BOT_TOKEN="8235509838:AAHUfOBE7Ni1I1xbX4zOg63TtMtXxsoUEhw"
TELEGRAM_CHAT_ID="-1003121331954"

# Find ALL files starting with Evolution X_Revived
ROM_FILES=$(ls $ROM_DIR | grep "^Evolution X_Revived")

if [[ -z "$ROM_FILES" ]]; then
    echo -e ">>> ERROR: Not Found Any Files Start With Evolution X_Revived"
    exit 1
fi

echo -e ">>> Found ROM files:"
echo "$ROM_FILES"

for FILE in $ROM_FILES; do
    echo -e "\n>>> Uploading file: $FILE"
    
    UPLOAD_RESPONSE=$(curl -s -T "$ROM_DIR/$FILE" -u :$API_KEY https://pixeldrain.com/api/file/)
    FILE_ID=$(echo $UPLOAD_RESPONSE | grep -o '"id":"[^"]*"' | cut -d '"' -f4)
    
    if [[ -n "$FILE_ID" ]]; then
        DOWNLOAD_LINK="https://pixeldrain.com/u/$FILE_ID"
        echo -e ">>> Upload Successful: $DOWNLOAD_LINK"

        # ========================
        # Extract build date
        # Example filename:
        # Evolution X_Revived-6.0-2025-01-17.zip
        # ========================
        BUILD_DATE=$(echo "$FILE" | grep -o "[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}")
        if [[ -z "$BUILD_DATE" ]]; then
            BUILD_DATE="Unknown"
        fi

        # Upload time (now)
        UPLOADED_TIME=$(date "+%Y-%m-%d %H:%M:%S")

        # Send Telegram message
        MESSAGE="📱 *Evolution X Build Uploaded Successfully*  
        
*Rom Name:* \`${FILE}\`
*Build Date:* ${BUILD_DATE}
*Uploaded Time:* ${UPLOADED_TIME}

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
