#!/bin/bash
socket="/run/user/$(id -u)/pipewire-0"
until [ -S "$socket" ]; do
    sleep 0.2
done
sleep 0.3
exec wireplumber
