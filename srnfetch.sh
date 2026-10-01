#!/usr/bin/env bash

# SRNFetch
# Simple Neofetch-style Linux system information tool

set -u

# -------------------------
# Colors
# -------------------------
RESET='\033[0m'
BOLD='\033[1m'
CYAN='\033[36m'
BLUE='\033[34m'
MAGENTA='\033[35m'
WHITE='\033[37m'
GREEN='\033[32m'

# -------------------------
# System information
# -------------------------
USER_NAME="$(whoami)"
HOST_NAME="$(hostname)"

if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS="${PRETTY_NAME:-Linux}"
else
    OS="Linux"
fi

KERNEL="$(uname -r)"
ARCH="$(uname -m)"

CPU="$(
    awk -F: '/model name/ {
        gsub(/^[ \t]+/, "", $2);
        print $2;
        exit
    }' /proc/cpuinfo
)"
CPU="${CPU:-Unknown CPU}"

CORES="$(nproc 2>/dev/null || echo "?")"

if command -v free >/dev/null 2>&1; then
    RAM_USED="$(free -h | awk '/^Mem:/ {print $3}')"
    RAM_TOTAL="$(free -h | awk '/^Mem:/ {print $2}')"
else
    RAM_USED="?"
    RAM_TOTAL="?"
fi

if command -v df >/dev/null 2>&1; then
    DISK_USED="$(df -h / | awk 'NR==2 {print $3}')"
    DISK_TOTAL="$(df -h / | awk 'NR==2 {print $2}')"
    DISK_PERCENT="$(df -h / | awk 'NR==2 {print $5}')"
else
    DISK_USED="?"
    DISK_TOTAL="?"
    DISK_PERCENT="?"
fi

UPTIME="$(uptime -p 2>/dev/null || echo "Unknown")"
SHELL_NAME="$(basename "${SHELL:-unknown}")"
TERM_NAME="${TERM:-unknown}"

GPU="Unknown"

if command -v lspci >/dev/null 2>&1; then
    GPU="$(
        lspci 2>/dev/null |
        grep -Ei 'VGA compatible controller|3D controller|Display controller' |
        sed -E 's/.*: //' |
        head -n 1
    )"
fi

GPU="${GPU:-Unknown}"

PACKAGE_MANAGER="Unknown"

if command -v apt >/dev/null 2>&1; then
    PACKAGE_MANAGER="APT"
elif command -v dnf >/dev/null 2>&1; then
    PACKAGE_MANAGER="DNF"
elif command -v pacman >/dev/null 2>&1; then
    PACKAGE_MANAGER="Pacman"
elif command -v apk >/dev/null 2>&1; then
    PACKAGE_MANAGER="APK"
fi

# -------------------------
# Logo
# -------------------------
LOGO=(
"        ███████╗██████╗ ███╗   ██╗"
"        ██╔════╝██╔══██╗████╗  ██║"
"        ███████╗██████╔╝██╔██╗ ██║"
"        ╚════██║██╔══██╗██║╚██╗██║"
"        ███████║██║  ██║██║ ╚████║"
"        ╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝"
""
"        SRNFETCH"
"        Linux System Information"
)

# -------------------------
# Information
# -------------------------
INFO=(
"${BOLD}${CYAN}${USER_NAME}@${HOST_NAME}${RESET}"
""
"${BOLD}${CYAN}OS${RESET}              ${OS}"
"${BOLD}${CYAN}Kernel${RESET}          ${KERNEL}"
"${BOLD}${CYAN}Architecture${RESET}    ${ARCH}"
"${BOLD}${CYAN}CPU${RESET}             ${CPU}"
"${BOLD}${CYAN}CPU Cores${RESET}       ${CORES}"
"${BOLD}${CYAN}GPU${RESET}             ${GPU}"
"${BOLD}${CYAN}Memory${RESET}          ${RAM_USED} / ${RAM_TOTAL}"
"${BOLD}${CYAN}Disk${RESET}            ${DISK_USED} / ${DISK_TOTAL} (${DISK_PERCENT})"
"${BOLD}${CYAN}Uptime${RESET}          ${UPTIME}"
"${BOLD}${CYAN}Shell${RESET}           ${SHELL_NAME}"
"${BOLD}${CYAN}Terminal${RESET}        ${TERM_NAME}"
"${BOLD}${CYAN}Package Manager${RESET} ${PACKAGE_MANAGER}"
)

# -------------------------
# Print
# -------------------------

LOGO_WIDTH=40

printf "\n"

MAX_LINES=${#INFO[@]}

if [ ${#LOGO[@]} -gt "$MAX_LINES" ]; then
    MAX_LINES=${#LOGO[@]}
fi

for ((i=0; i<MAX_LINES; i++)); do
    LEFT="${LOGO[$i]:-}"
    RIGHT="${INFO[$i]:-}"

    # Color logo separately
    if [ -n "$LEFT" ]; then
        printf "${CYAN}%-40s${RESET}" "$LEFT"
    else
        printf "%-40s" ""
    fi

    printf "  %b\n" "$RIGHT"
done

printf "\n"
printf "${BOLD}${GREEN}SRNFetch${RESET} — system information displayed successfully.\n"
