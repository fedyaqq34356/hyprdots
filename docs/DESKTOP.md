# Desktop: Ryzen 5 5600 + RX 9060 XT on Artix

Everything the installer cannot do for you, in the order you will meet it.

## 1. BIOS (ASRock B550M-HDV)

- Update the BIOS first: RX 9060 XT wants a recent AGESA for Re-Size BAR.
- **XMP / DOCP**: on (OC Tweaker → DRAM Profile).
- **Above 4G Decoding**: on, **Re-Size BAR**: on (Advanced → PCI Configuration).
- **CSM**: off, boot in UEFI.
- **Secure Boot**: off.
- **CPPC**: on (Advanced → AMD CBS → NBIO → SMU Common Options → CPPC, and CPPC Preferred Cores) — `amd_pstate=active` needs it.
- After the first boot: `sudo dmesg | grep -i 'BAR='` and `cat /sys/class/drm/card*/device/mem_info_vis_vram_total` (should be the full 8/16 GiB).

## 2. Installing Artix

### Disk layout (NVMe 1 TB)

Recommended: **btrfs with Timeshift snapshots**. ext4 is fine too, but a snapshot before a big update is what makes a rolling release relaxed.

| partition | size | type | mount |
| --- | --- | --- | --- |
| `nvme0n1p1` | 1 GiB | FAT32, EFI System | `/boot/efi` |
| `nvme0n1p2` | rest | btrfs | `/` |

No swap partition and no swapfile: swap is zram (see 6).

```sh
mkfs.fat -F32 -n EFI /dev/nvme0n1p1
mkfs.btrfs -L artix /dev/nvme0n1p2
mount /dev/nvme0n1p2 /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@log
btrfs subvolume create /mnt/@cache
umount /mnt
o=noatime,compress=zstd:1
mount -o $o,subvol=@ /dev/nvme0n1p2 /mnt
mkdir -p /mnt/{home,var/log,var/cache,boot/efi}
mount -o $o,subvol=@home  /dev/nvme0n1p2 /mnt/home
mount -o $o,subvol=@log   /dev/nvme0n1p2 /mnt/var/log
mount -o $o,subvol=@cache /dev/nvme0n1p2 /mnt/var/cache
mount /dev/nvme0n1p1 /mnt/boot/efi
```

Timeshift needs exactly `@` and `@home`; `@log` and `@cache` stay out of the snapshots on purpose. Kernels live in `/boot` inside `@`, so a restored snapshot boots the kernel it was taken with.

### Base system

```sh
basestrap /mnt base base-devel openrc elogind-openrc \
    linux linux-headers linux-firmware amd-ucode \
    btrfs-progs grub efibootmgr \
    networkmanager networkmanager-openrc \
    openssh openssh-openrc rsync git sudo zsh vim \
    cronie cronie-openrc
fstabgen -U /mnt >> /mnt/etc/fstab
artix-chroot /mnt
```

Inside the chroot:

```sh
ln -sf /usr/share/zoneinfo/Europe/Kyiv /etc/localtime && hwclock --systohc
sed -i 's/^#\(en_US.UTF-8\|ru_RU.UTF-8\)/\1/' /etc/locale.gen && locale-gen
echo 'LANG=en_US.UTF-8' > /etc/locale.conf
echo artix-pc > /etc/hostname
useradd -m -G wheel,video,input -s /bin/zsh f && passwd f && passwd
EDITOR=vim visudo
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=artix
grub-mkconfig -o /boot/grub/grub.cfg
rc-update add NetworkManager default
rc-update add sshd default
rc-update add cronie default
exit
```

The kernel must be 6.14 or newer, `linux-firmware` from 2025 or newer, mesa 25.1 or newer: RDNA4 does not light up on older stacks.

### First login

Log in on the TTY, then:

```sh
nmtui
git clone https://github.com/fedyaqq34356/hyprdots ~/Projects/hyprdots   # after amd-desktop is merged
cd ~/Projects/hyprdots && ./install.sh
sudo pacman -S sddm sddm-openrc plymouth timeshift grub-btrfs
sudo rc-update add sddm default
```

The installer detects a desktop (no battery) and an AMD GPU and then:

- enables Artix `[lib32]` and Arch `[extra]`/`[multilib]` through `artix-archlinux-support`;
- installs mesa, RADV, VA-API, Steam, gamemode, MangoHud, LACT, RNNoise;
- links `~/.config/hypr/config/gpu.conf` to `gpu-amd.conf`;
- adds `amdgpu` to the initramfs, `amd_pstate=active` and `amdgpu.ppfeaturemask=0xffffffff` to GRUB;
- installs the zram swap service and writes the quiet LACT and gamemode configs.

`./install.sh --printer` adds the Canon LBP6000 when it is not plugged in yet.

The Archer T3U Plus first shows up as a USB CD-ROM: `usb_modeswitch` flips it into Wi-Fi mode (driver `rtw88_8822bu`, interface `wlan0` or `wlx…`). The bar does not care about interface names: Wi-Fi and Ethernet (`enp…`) come from `nmcli` by type.

## 3. Services and groups

```sh
sudo rc-update add NetworkManager default
sudo rc-update add bluetoothd default
sudo rc-update add cronie default
sudo rc-update add sddm default
sudo rc-update add lactd default
sudo rc-update add zram boot
sudo rc-update add cupsd default    # printer only
sudo rc-update add ccpd default     # printer only
sudo rc-update add elogind boot
rc-update show
sudo usermod -aG video,input,gamemode,lp "$USER"
```

Log out and back in after changing groups.

## 4. Boot: Plymouth and SDDM

- `/etc/mkinitcpio.conf.d/10-amdgpu.conf` holds `MODULES+=(amdgpu)`. Keep `kms` and `plymouth` in `HOOKS` of `/etc/mkinitcpio.conf`, then `sudo mkinitcpio -P`.
- `GRUB_CMDLINE_LINUX_DEFAULT` gets `loglevel=3 quiet splash` and, as on the laptop, `lsm=landlock,lockdown,yama,integrity,apparmor` (with `apparmor apparmor-openrc` installed, for the firejail profiles); then `sudo grub-mkconfig -o /boot/grub/grub.cfg`. The laptop-only `acpi_backlight=vendor nvidia_drm.modeset=1` do not belong here.
- SDDM theme: `extras/sddm/install.sh`.

## 5. CPU and GPU

- `cat /sys/devices/system/cpu/amd_pstate/status` → `active`; `cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_driver` → `amd-pstate-epp`.
- `~/.config/gamemode.ini`: while a game runs the governor is `performance`, EPP `performance`, the GPU `power_dpm_force_performance_level` is `high`; gamemode puts everything back when the game exits. Check with `gamemoded -s` during a game.
- LACT (`lact` GUI, daemon `lactd`): `/etc/lact/config.yaml` starts quiet — zero RPM up to 55 °C, a gentle curve on the junction temperature, power cap 145 W. Raise the cap in the GUI if a game needs the last few percent; `LACT_POWER_CAP=160 sh extras/lact/gen-config.sh | sudo tee /etc/lact/config.yaml` rewrites it.
- The fan curve on RDNA3/4 goes through the PMFW and needs `amdgpu.ppfeaturemask=0xffffffff`. The kernel then logs that overdrive is enabled; that is expected.

## 6. Memory: zram

- `/etc/init.d/zram` creates a zstd zram swap of half the RAM (16 GiB for 32 GiB) with priority 100; `/etc/conf.d/zram` changes the size.
- `/etc/sysctl.d/99-zram.conf`: `vm.swappiness=180`, `vm.page-cluster=0`.
- No swapfile: if the Artix installer made one, remove its line from `/etc/fstab`, `sudo swapoff -a && sudo rm /swapfile`.
- Check: `zramctl`, `swapon --show`.

## 7. Audio: Pulse Elite over Bluetooth

The PlayStation Link dongle stays with the PS5, so on the desktop the headset is Bluetooth only (TP-Link UB500).

```sh
bluetoothctl
  power on
  scan on
  pair @PULSE_MAC@
  trust @PULSE_MAC@
  connect @PULSE_MAC@
```

- Default profile is A2DP (AAC/SBC-XQ). WirePlumber switches to HFP (mSBC 16 kHz) only while an app actually records from the headset microphone, and goes back to A2DP after.
- `pulse-autoconnect` reconnects the headset every 5 s while it is on.
- Noise suppression: `mic-denoise on` starts a separate PipeWire filter-chain with RNNoise on the headset mic, makes `Pulse Elite Mic (RNNoise)` the default source and remembers the previous one; `mic-denoise off` restores it, `mic-denoise toggle` / `status`. It costs nothing while off, and while on HFP still kicks in only when something records.
- The PlayStation Link rule stays in `53-playstation-link.conf` and wins whenever the dongle is plugged in; nothing depends on it.
- Check: `wpctl status`, `pactl list short sources`.

## 8. Monitor

- `monitors.conf` matches `desc:Lenovo Group Limited R24s` at `1920x1080@143.85`, whatever the port (DP-1 here).
- VRR in fullscreen (`misc:vrr = 2`), tearing allowed for `steam_app_*` and Arma 3 windows (`immediate`).
- Quickshell animations are time-based, so they run at the same speed at 60 and 144 Hz.
- While a fullscreen game is focused the shell pauses its shaders, looping animations, Cava, lyrics and wallpaper rotation, and resumes them when the game leaves fullscreen.
- Super+Ctrl+D rewrites the layout and keeps the `desc:` match.
- Check: `hyprctl monitors` → `vrr`, the monitor OSD shows FreeSync active in a game.

## 9. Steam and games

- Steam → Settings → Compatibility → enable Steam Play for all titles.
- Proton-GE: `yay -S protonup-qt`, install the latest GE-Proton, restart Steam.
- MangoHud is hidden until **Right Shift + F12**; it shows FPS, frametime graph, CPU/GPU load and temperatures (GPU edge and junction), VRAM, RAM and the gamemode state. Its colours follow the wallpaper (matugen template `mangohud.conf`).
- `vulkaninfo --summary` should show `RADV GFX1200`, `vainfo` should show `radeonsi`.

### Arma 3 (107410)

- Compatibility: **GE-Proton**.
- Launch options: `gamemoderun mangohud %command% -noLauncher -skipIntro -noSplash -world=empty -enableHT -hugePages`
- Workshop mods land in `~/.local/share/Steam/steamapps/workshop/content/107410/`.
- Your own mods (`~/Projects/ArmaMods`): link them into the game folder and load them by name:

  ```sh
  cd ~/.local/share/Steam/steamapps/common/Arma\ 3
  ln -s ~/Projects/ArmaMods/@MyMod .
  ```

  then add `-mod=@MyMod;@Other` to the launch options. The Linux launcher (`~/.config/a3unixlauncher`) can manage the same list.

### Hearts of Iron IV (394360)

- Native Linux build, no Proton.
- Launch options: `gamemoderun mangohud %command%`
- Mods: Steam Workshop, or local mods in `~/.local/share/Paradox Interactive/Hearts of Iron IV/mod/` (a folder plus a `.mod` descriptor next to it), enabled in the Paradox launcher playset.

### Cities: Skylines II (949230)

- Compatibility: **Proton Experimental** or GE-Proton.
- Launch options: `gamemoderun mangohud %command%`
- Graphics: start from the **High** preset, never Ultra, then:
  - Global Illumination: **Low**
  - Volumetrics: Low, Fog: Low
  - Depth of Field: Off, Motion Blur: Off
  - Level of Detail: Medium
  - Dynamic Resolution: FSR, Quality
  - Shadows: Medium
- Mods: Paradox Mods in the game menu (Paradox account). Local mods go to
  `~/.local/share/Steam/steamapps/compatdata/949230/pfx/drive_c/users/steamuser/AppData/LocalLow/Colossal Order/Cities Skylines II/Mods/`.

## 10. Moving from the laptop

On the desktop: `sudo rc-service sshd start`. On the laptop, with Telegram closed:

```sh
dots-migrate f@artix-pc            # dry run: sizes, file counts, links, crontab
dots-migrate --apply f@artix-pc    # copy for real
```

It copies `~/Projects` (with `~/SEC`), `~/.ssh`, `~/.gnupg`, `~/.local/share/TelegramDesktop`, recreates the `~/X -> ~/Projects/X` links and installs the crontab (the old one is kept as `~/crontab.before-migrate`). Build artefacts, virtualenvs, `node_modules`, Telegram caches and agent sockets are skipped — the list is `extras/migrate/exclude.txt`. Run it again later: only the difference is sent.

## 11. Cron

The crontab comes over with `dots-migrate`: borg backup, borg check, secrets backup, thumbnail cleanup, the weekly privacy report and sortdir. It relies on `~/SEC` and `~/.local/bin/sortdir` being there, and on `cronie` running. Cache cleanup: `~/.config/hypr/scripts/system/clean-cache.sh`.

## 12. Sensors

`sensors` shows `k10temp` (Tctl) and `amdgpu` (edge, junction, mem). The bar reads them straight from sysfs, no `sensors-detect` needed.
