#!/usr/bin/env bash

NVIDIA_PKGS="lib32-nvidia-580xx-utils,linux-firmware-nvidia,nvidia-580xx-dkms,nvidia-580xx-utils"

echo "=== Обновление пакетов (без nvidia) ==="
echo "   Игнорируем: $NVIDIA_PKGS"
echo ""

yay -Syu --ignore "$NVIDIA_PKGS"

echo ""
echo "=== Готово! ==="
read -n1 -p "Нажмите любую клавишу..."
