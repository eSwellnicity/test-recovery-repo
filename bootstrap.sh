#!/usr/bin/env bash
set -euo pipefail

echo "=== MintOS Bootstrap Script ==="
echo "Detecting Mint media..."

# Try to find CD or ISO
MOUNT_POINT="/mnt/mintos"
DEVICE="/dev/sr0"

# If CD device doesn't exist, try to find an ISO in /mnt or /home
if [ ! -b "$DEVICE" ]; then
  echo "No CD device found at /dev/sr0. Searching for Mint ISO..."
  ISO_PATH=$(find /mnt /home -maxdepth 2 -type f -name "linuxmint-*.iso" | head -n 1 || true)
  if [ -n "$ISO_PATH" ]; then
    echo "Found ISO at $ISO_PATH"
    sudo mkdir -p "$MOUNT_POINT"
    sudo mount -o loop "$ISO_PATH" "$MOUNT_POINT"
  else
    echo "❌ No ISO or CD device found."
    exit 1
  fi
else
  echo "Found CD device at $DEVICE"
  sudo mkdir -p "$MOUNT_POINT"
  sudo mount "$DEVICE" "$MOUNT_POINT"
fi

echo "Mounted Mint media at $MOUNT_POINT"
ls "$MOUNT_POINT/casper" || true

# Identify kernel/initrd
KERNEL=$(find "$MOUNT_POINT/casper" -name "vmlinuz*" | head -n 1)
INITRD=$(find "$MOUNT_POINT/casper" -name "initrd*" | head -n 1)

if [ -z "$KERNEL" ] || [ -z "$INITRD" ]; then
  echo "❌ Could not locate kernel or initrd in $MOUNT_POINT/casper"
  exit 1
fi

echo "Using kernel: $KERNEL"
echo "Using initrd: $INITRD"

# Install kexec-tools if missing
if ! command -v kexec >/dev/null 2>&1; then
  echo "Installing kexec-tools..."
  sudo apt update && sudo apt install -y kexec-tools
fi

# Load Mint kernel
echo "Loading Mint kernel via kexec..."
sudo kexec -l "$KERNEL" \
  --initrd="$INITRD" \
  --command-line="boot=casper iso-scan/filename=$DEVICE noprompt noeject"

# Confirm load success
echo "Kernel loaded. Executing now..."
sudo kexec -e
