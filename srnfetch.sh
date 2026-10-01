#!/usr/bin/env bash

# SRNFetch - compact Linux system fetch

ESC=$'\033'
RESET="${ESC}[0m"
BOLD="${ESC}[1m"
DIM="${ESC}[2m"
CYAN="${ESC}[36m"
BLUE="${ESC}[34m"
GREEN="${ESC}[32m"
WHITE="${ESC}[37m"

# ---------- System ----------
USER_NAME="$(id -un 2>/dev/null || echo unknown)"
HOST_NAME="$(hostname 2>/dev/null || echo unknown)"

if [ -r /etc/os-release ]; then
    . /etc/os-release
    OS="${PRETTY_NAME:-Linux}"
else
    OS="Linux"
fi

KERNEL="$(uname -r)"
ARCH="$(uname -m)"

CPU="$(awk -F: '
/model name/ {
    gsub(/^[ \t]+/, "", $2)
    print $2
    exit
}' /proc/cpuinfo)"

CPU="${CPU:-Unknown}"
CORES="$(nproc 2>/dev/null || echo '?')"

RAM_USED="$(free -h | awk '/^Mem:/ {print $3}')"
RAM_TOTAL="$(free -h | awk '/^Mem:/ {print $2}')"

DISK_USED="$(df -h / | awk 'NR==2 {print $3}')"
DISK_TOTAL="$(df -h / | awk 'NR==2 {print $2}')"
DISK_PERCENT="$(df -h / | awk 'NR==2 {print $5}')"

UPTIME="$(uptime -p 2>/dev/null | sed 's/^up //' || echo unknown)"
SHELL_NAME="$(basename "${SHELL:-unknown}")"
TERM_NAME="${TERM:-unknown}"

GPU="Unknown"
if command -v lspci >/dev/null 2>&1; then
    GPU="$(lspci 2>/dev/null |
        grep -Ei 'VGA compatible controller|3D controller|Display controller' |
        sed -E 's/.*: //' |
        head -n1)"
fi
GPU="${GPU:-Unknown}"

VIRT="Unknown"
if command -v systemd-detect-virt >/dev/null 2>&1; then
    VIRT="$(systemd-detect-virt 2>/dev/null)"
    [ -z "$VIRT" ] && VIRT="none"
fi

PKG="Unknown"
command -v apt >/dev/null 2>&1 && PKG="APT"
command -v dnf >/dev/null 2>&1 && PKG="DNF"
command -v pacman >/dev/null 2>&1 && PKG="Pacman"

# ---------- Box ----------
printf "\n"

printf "${CYAN}${BOLD}┌─ SRNFETCH${RESET}"
printf "${DIM} ─────────────────────────────────────────────${RESET}\n"

printf "${CYAN}│${RESET} ${GREEN}${BOLD}%s@%s${RESET}" "$USER_NAME" "$HOST_NAME"
printf " ${DIM}·${RESET} %s\n" "$OS"

printf "${CYAN}│${RESET} ${BLUE}Kernel${RESET} %s ${DIM}·${RESET} ${BLUE}Arch${RESET} %s\n" \
    "$KERNEL" "$ARCH"

printf "${CYAN}│${RESET} ${BLUE}CPU${RESET} %s ${DIM}·${RESET} ${BLUE}Cores${RESET} %s\n" \
    "$CPU" "$CORES"

printf "${CYAN}│${RESET} ${BLUE}GPU${RESET} %s\n" "$GPU"

printf "${CYAN}│${RESET} ${BLUE}RAM${RESET} %s / %s ${DIM}·${RESET} ${BLUE}Disk${RESET} %s / %s (%s)\n" \
    "$RAM_USED" "$RAM_TOTAL" "$DISK_USED" "$DISK_TOTAL" "$DISK_PERCENT"

printf "${CYAN}│${RESET} ${BLUE}Uptime${RESET} %s ${DIM}·${RESET} ${BLUE}Shell${RESET} %s ${DIM}·${RESET} ${BLUE}Pkg${RESET} %s\n" \
    "$UPTIME" "$SHELL_NAME" "$PKG"

printf "${CYAN}│${RESET} ${BLUE}Terminal${RESET} %s ${DIM}·${RESET} ${BLUE}Virt${RESET} %s\n" \
    "$TERM_NAME" "$VIRT"

printf "${CYAN}└─────────────────────────────────────────────────${RESET}\n"
printf "${DIM}SRNFetch 1.0${RESET}\n\n"
