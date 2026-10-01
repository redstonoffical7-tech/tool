#!/usr/bin/env bash

# ============================================================
# SRNFetch
# Simple Linux system information fetcher
# ============================================================

set -o pipefail

# -------------------------
# Colors
# -------------------------
ESC=$'\033'

RESET="${ESC}[0m"
BOLD="${ESC}[1m"
DIM="${ESC}[2m"

RED="${ESC}[31m"
GREEN="${ESC}[32m"
YELLOW="${ESC}[33m"
BLUE="${ESC}[34m"
MAGENTA="${ESC}[35m"
CYAN="${ESC}[36m"
WHITE="${ESC}[37m"

# -------------------------
# Helpers
# -------------------------
info() {
    printf "%s%-16s%s %s\n" "${CYAN}" "$1" "${RESET}" "$2"
}

section() {
    printf "\n%s%s%s\n" "${BOLD}${MAGENTA}" "$1" "${RESET}"
    printf "%s\n" "----------------------------------------"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# -------------------------
# User / Host
# -------------------------
USER_NAME="$(id -un 2>/dev/null || echo unknown)"
HOST_NAME="$(hostname 2>/dev/null || echo unknown)"

# -------------------------
# OS
# -------------------------
if [ -r /etc/os-release ]; then
    . /etc/os-release
    OS_NAME="${PRETTY_NAME:-${NAME:-Linux}}"
else
    OS_NAME="Linux"
fi

# -------------------------
# Kernel
# -------------------------
KERNEL="$(uname -r 2>/dev/null || echo unknown)"
ARCH="$(uname -m 2>/dev/null || echo unknown)"

# -------------------------
# CPU
# -------------------------
CPU="Unknown"

if [ -r /proc/cpuinfo ]; then
    CPU="$(awk -F: '
        /model name/ {
            gsub(/^[ \t]+/, "", $2)
            print $2
            exit
        }
        /Hardware/ {
            gsub(/^[ \t]+/, "", $2)
            print $2
            exit
        }
    ' /proc/cpuinfo)"
fi

CPU="${CPU:-Unknown}"

CORES="$(nproc 2>/dev/null || echo "?")"

# -------------------------
# RAM
# -------------------------
if command_exists free; then
    RAM_TOTAL="$(free -h | awk '/^Mem:/ {print $2}')"
    RAM_USED="$(free -h | awk '/^Mem:/ {print $3}')"
    RAM_AVAILABLE="$(free -h | awk '/^Mem:/ {print $7}')"
else
    RAM_TOTAL="?"
    RAM_USED="?"
    RAM_AVAILABLE="?"
fi

# -------------------------
# Disk
# -------------------------
if command_exists df; then
    DISK_TOTAL="$(df -h / | awk 'NR==2 {print $2}')"
    DISK_USED="$(df -h / | awk 'NR==2 {print $3}')"
    DISK_FREE="$(df -h / | awk 'NR==2 {print $4}')"
    DISK_PERCENT="$(df -h / | awk 'NR==2 {print $5}')"
else
    DISK_TOTAL="?"
    DISK_USED="?"
    DISK_FREE="?"
    DISK_PERCENT="?"
fi

# -------------------------
# GPU
# -------------------------
GPU="Not detected"

if command_exists lspci; then
    GPU="$(lspci 2>/dev/null |
        grep -Ei 'VGA compatible controller|3D controller|Display controller' |
        sed -E 's/.*: //' |
        head -n 1)"
fi

GPU="${GPU:-Not detected}"

# -------------------------
# Uptime
# -------------------------
UPTIME="$(uptime -p 2>/dev/null || echo unknown)"

# -------------------------
# Shell
# -------------------------
SHELL_NAME="$(basename "${SHELL:-unknown}")"

# -------------------------
# Terminal
# -------------------------
TERMINAL="${TERM:-unknown}"

# -------------------------
# Package manager
# -------------------------
PACKAGE_MANAGER="Unknown"

if command_exists apt; then
    PACKAGE_MANAGER="APT"
elif command_exists dnf; then
    PACKAGE_MANAGER="DNF"
elif command_exists yum; then
    PACKAGE_MANAGER="YUM"
elif command_exists pacman; then
    PACKAGE_MANAGER="Pacman"
elif command_exists apk; then
    PACKAGE_MANAGER="APK"
elif command_exists zypper; then
    PACKAGE_MANAGER="Zypper"
fi

# -------------------------
# Architecture / virtualization
# -------------------------
VIRTUALIZATION="Unknown"

if command_exists systemd-detect-virt; then
    VIRTUALIZATION="$(systemd-detect-virt 2>/dev/null)"

    if [ -z "$VIRTUALIZATION" ]; then
        VIRTUALIZATION="None"
    fi
else
    VIRTUALIZATION="Unknown"
fi

# -------------------------
# Load average
# -------------------------
LOAD="Unknown"

if [ -r /proc/loadavg ]; then
    LOAD="$(awk '{print $1 "  " $2 "  " $3}' /proc/loadavg)"
fi

# -------------------------
# Local IP
# -------------------------
IP_ADDRESS="Unknown"

if command_exists hostname; then
    IP_ADDRESS="$(hostname -I 2>/dev/null | awk '{print $1}')"
fi

IP_ADDRESS="${IP_ADDRESS:-Unknown}"

# ============================================================
# OUTPUT
# ============================================================

clear 2>/dev/null || true

printf "\n"

printf "%s%s" "${BOLD}${CYAN}"
cat <<'EOF'
   _____ _____  _   _  ______ ______ _____ _______ _______ _____ _    _ 
  / ____|  __ \| \ | | |  ____|  ____/ ____|__   __|__   __/ ____| |  | |
 | (___ | |__) |  \| | | |__  | |__ | (___    | |     | | | |    | |__| |
  \___ \|  _  /| . ` | |  __| |  __| \___ \   | |     | | | |    |  __  |
  ____) | | \ \| |\  | | |____| |____ ____) |  | |    _| |_| |____| |  | |
 |_____/|_|  \_\_| \_| |______|______|_____/   |_|   |_____\_____|_|  |_|
EOF
printf "%s\n" "${RESET}"

printf "%s%s@%s%s\n" \
    "${BOLD}${GREEN}" \
    "$USER_NAME" \
    "$HOST_NAME" \
    "${RESET}"

printf "%s\n" "=============================================="

section "SYSTEM"

info "OS" "$OS_NAME"
info "Kernel" "$KERNEL"
info "Architecture" "$ARCH"
info "Virtualization" "$VIRTUALIZATION"

section "HARDWARE"

info "CPU" "$CPU"
info "CPU Cores" "$CORES"
info "GPU" "$GPU"

section "MEMORY"

info "RAM Used" "$RAM_USED"
info "RAM Total" "$RAM_TOTAL"
info "RAM Available" "$RAM_AVAILABLE"

section "STORAGE"

info "Disk Used" "$DISK_USED"
info "Disk Total" "$DISK_TOTAL"
info "Disk Free" "$DISK_FREE"
info "Disk Usage" "$DISK_PERCENT"

section "SESSION"

info "Uptime" "$UPTIME"
info "Shell" "$SHELL_NAME"
info "Terminal" "$TERMINAL"
info "Package Manager" "$PACKAGE_MANAGER"
info "IP Address" "$IP_ADDRESS"
info "Load Average" "$LOAD"

printf "\n"
printf "%s%sSRNFetch%s %sv1.0%s\n\n" \
    "${BOLD}" \
    "${GREEN}" \
    "${RESET}" \
    "${DIM}" \
    "${RESET}"
