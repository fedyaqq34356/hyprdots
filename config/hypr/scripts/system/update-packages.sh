#!/usr/bin/env bash

NVIDIA_PKGS="lib32-nvidia-580xx-utils,linux-firmware-nvidia,nvidia-580xx-dkms,nvidia-580xx-utils"

echo "=== Updating packages (nvidia held back) ==="
echo "   Held back: $NVIDIA_PKGS"
echo ""

yay -Syu --ignore "$NVIDIA_PKGS"

echo ""
echo "=== Done ==="
read -n1 -p "Press any key..."
