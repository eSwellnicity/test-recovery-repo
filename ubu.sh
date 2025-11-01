#!/usr/bin/env bash
set -euo pipefail

echo "=== Ubuntu Reinstall Bootstrap ==="
MOUNT_POINT="/mnt/cdrom"
DEVICE="/dev/sr0"

# Step 1 — Make sure CD is mounted
if mount | grep -q "$MOUNT_POINT"; then
  echo "✅ $MOUNT_POINT is already mounted."
else
  echo "📀 Mounting $DEVICE to $MOUNT_POINT..."
  sudo mkdir -p "$MOUNT_POINT"
  sudo mount "$DEVICE" "$MOUNT_POINT" || {
    echo "❌ Could not mount $DEVICE. Check disc and try again."
    exit 1
  }
fi

# Step 2 — Confirm casper directory
if [ ! -d "$MOUNT_POINT/casper" ]; then
  echo "❌ $MOUNT_POINT/casper not found. Are you sure this is an Ubuntu CD?"
  exit 1
fi

# Step 3 — Detect kernel and initrd
KERNEL=$(find "$MOUNT_POINT/casper" -type f -name "vmlinuz*" | head -n 1)
INITRD=$(find "$MOUNT_POINT/casper" -type f -name "initrd*" | head -n 1)

if [ -z "$KERNEL" ] || [ -z "$INITRD" ]; then
  echo "❌ Kernel or initrd not found under $MOUNT_POINT/casper."
  echo "Files present:"
  ls -l "$MOUNT_POINT/casper"
  exit 1
fi

echo "🧩 Found kernel: $KERNEL"
echo "🧩 Found initrd: $INITRD"

# Step 4 — Install kexec-tools if missing
if ! command -v kexec >/dev/null 2>&1; then
  echo "📦 Installing kexec-tools..."
  sudo apt update -y
  sudo apt install -y kexec-tools
fi

# Step 5 — Load and execute the Ubuntu installer
echo "🚀 Loading Ubuntu installer kernel..."
sudo kexec -l "$KERNEL" \
  --initrd="$INITRD" \
  --command-line="boot=casper iso-scan/filename=$DEVICE noprompt noeject quiet"

echo "✅ Kernel loaded. Executing now..."
sleep 2
sudo kexec -e
