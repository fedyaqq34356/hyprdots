#!/bin/sh

set -eu

POWER_CAP="${LACT_POWER_CAP:-145}"

for card in "${SYSFS:-/sys}"/class/drm/card[0-9]*; do
    dev="$card/device"
    [ "$(cat "$dev/vendor" 2>/dev/null)" = 0x1002 ] || continue
    [ -e "$dev/gpu_busy_percent" ] || continue
    hex() { sed 's/^0x//' "$dev/$1" | tr 'a-f' 'A-F'; }
    slot=$(basename "$(readlink -f "$dev")")
    id="$(hex vendor):$(hex device)-$(hex subsystem_vendor):$(hex subsystem_device)-$slot"
    break
done

[ -n "${id:-}" ] || { echo "gen-config: no amdgpu card" >&2; exit 1; }

cat <<YAML
version: 5
daemon:
  log_level: info
  admin_group: wheel
  disable_clocks_cleanup: false
apply_settings_timer: 5
gpus:
  $id:
    fan_control_enabled: true
    fan_control_settings:
      mode: curve
      static_speed: 0.4
      temperature_key: junction
      interval_ms: 500
      spindown_delay_ms: 8000
      change_threshold: 3
      curve:
        50: 0.22
        65: 0.32
        75: 0.45
        85: 0.65
        95: 0.9
    pmfw_options:
      zero_rpm: true
      zero_rpm_threshold: 55
    power_cap: $POWER_CAP.0
    performance_level: auto
YAML
