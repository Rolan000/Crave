#!/bin/bash

# ================================
# Clean old manifests
# ================================
echo -e ">>> Cleaning old local manifests Or Old device trees if exists"
rm -rf .repo/local_manifests/
rm -rf device/xiaomi/miatoll
rm -rf vendor/xiaomi/miatoll
rm -rf hardware/xiaomi
rm -rf vendor/xiaomi/miuicamera-miatoll
rm -rf hardware/sony/timekeep


# ================================
# Initialize RisingOS repo
# ================================
echo -e ">>> Initializing RisingOS repository"
repo init -u https://github.com/RosMiatoll/android -b sixteen --git-lfs
echo -e ">>> Downloading RisingOS local manifests"
echo -e ">>> Please wait, this may take a while..."
echo -e ">>> Cloning RisingOS local manifests"
echo -e ">>> Done"


# ================================
# Clone device/vendor/kernel trees
# ================================
echo -e ">>> Cloning Device Trees"
echo -e ">>> Cloning Device, Vendor, Kernel and Hardware Trees"
echo -e ">>> Please wait, this may take a while..."
echo -e ">>> Cloning Device Tree: xiaomi/miatoll"
git clone https://github.com/RosMiatoll/device_xiaomi_miatoll_rebase.git -b prebuild-kernel device/xiaomi/miatoll
echo -e ">>> Done"
echo -e ">>> Cloning Vendor Tree: xiaomi/vendor"
git clone https://github.com/RosMiatoll/vendor_xiaomi_miatoll_rebase.git -b prebuild vendor/xiaomi/miatoll
echo -e ">>> Done"
echo -e ">>> Cloning Kernel Tree: xiaomi/sm6250"
git clone https://github.com/RosMiatoll/device_xiaomi_miatoll-kernel.git -b sixteen device/xiaomi/miatoll-kernel
echo -e ">>> Done"
echo -e ">>> Cloning Hardware Tree: xiaomi/hardware_xiaomi"
git clone https://github.com/LineageOS/android_hardware_xiaomi.git -b lineage-23.0 hardware/xiaomi
echo -e ">>> Done"
echo -e ">>> Cloning Additional Hardware Trees"
git clone https://github.com/LineageOS/android_hardware_sony_timekeep.git -b lineage-22.2 hardware/sony/timekeep
echo -e ">>> Done"
echo -e ">>> Cloning MIUI Camera Vendor Tree: xiaomi/miuicamera"
git clone https://github.com/Miatoll720G/vendor_xiaomi_miuicamera-miatoll.git -b 16 vendor/xiaomi/miuicamera-miatoll
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
# ================================
# Setup build environment
# ================================
source build/envsetup.sh
echo -e ">>> Build environment setup completed"
echo -e ">>> Proceeding to apply RisingOS build flags..."
echo -e ">>> Please wait..."

# ================================
# Start build
# ================================
echo ">>> Starting RisingOS Build"
echo -e ">>> Building RisingOS for Xiaomi Miatoll"
export TZ=Africa/Cairo
echo -e ">>> Timezone set to Africa/Cairo"
riseup miatoll userdebug
echo -e ">>> Build command executed: riseup miatoll user"
echo -e ">>> Build process initiated. This may take several hours."
echo -e ">>> You can monitor the build progress above."
rise b
echo -e ">>> Build command executed: rise b"
echo -e ">>> RisingOS Build process completed"
echo -e ">>> You can find the built ROM in the out/target/product/miatoll/ directory"
echo -e ">>> Thank you for using this build script. Goodbye!"

# ============================================================
# Upload ROM(s) to PixelDrain automatically + Telegram notify
# ============================================================
echo -e ">>> Searching for ROM files (RisingOS_Revived*)..."

ROM_DIR="out/target/product/miatoll"
API_KEY="cfb7aad5-0c4b-401b-b5dc-730b71be72a3"

# === Telegram data ===
TELEGRAM_BOT_TOKEN="8235509838:AAHUfOBE7Ni1I1xbX4zOg63TtMtXxsoUEhw"
TELEGRAM_CHAT_ID="-1003121331954"

# Find ALL files starting with RisingOS_Revived
ROM_FILES=$(ls $ROM_DIR | grep "^RisingOS_Revived")

if [[ -z "$ROM_FILES" ]]; then
    echo -e ">>> ERROR: Not Found Any Files Start With RisingOS_Revived"
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
        # RisingOS_Revived-6.0-2025-01-17.zip
        # ========================
        BUILD_DATE=$(echo "$FILE" | grep -o "[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}")
        if [[ -z "$BUILD_DATE" ]]; then
            BUILD_DATE="Unknown"
        fi

        # Upload time (now)
        UPLOADED_TIME=$(date "+%Y-%m-%d %H:%M:%S")

        # Send Telegram message
        MESSAGE="📱 *RisingOS Build Uploaded Successfully*  
        
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

