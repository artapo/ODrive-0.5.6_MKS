#!/usr/bin/env bash
# Flash builds/ODrive-fw-v0.5.6-<board>.bin over USB DFU.
# Usage: tools/flash.sh [board]   (default v3.6-56V-MKS-S)
# Enters DFU by itself over the ASCII port ("sd") when the firmware supports it; otherwise the board
# must already be in DFU mode (DFU switch + power cycle). Flash one board at a time.
# The .bin only covers 0x08000000..; NVM (0x080C0000) is untouched, so saved config survives.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DFU="$ROOT/tools/dfu-util-static.exe"
[ -x "$DFU" ] || DFU="$ROOT/tools/dfu-util.exe"
BIN="$ROOT/builds/ODrive-fw-v0.5.6-${1:-v3.6-56V-MKS-S}.bin"

[ -x "$DFU" ] || { echo "dfu-util not found: download dfu-util-0.11-binaries (https://dfu-util.sourceforge.net/releases/) and copy dfu-util-static.exe to tools/"; exit 1; }
[ -f "$BIN" ] || { echo "no firmware: run tools/build.sh first"; exit 1; }

# 0483:df11 = STM32 system bootloader. "Found DFU": the bare ID also shows up while the WinUSB driver is still loading.
dfu_alt0() { "$DFU" -l 2>/dev/null | grep "Found DFU: \[0483:df11\].*alt=0" || true; }
in_dfu() { [ -n "$(dfu_alt0)" ]; }

# Not in DFU: ask the running firmware over its ASCII port ("sd", refused while a motor is armed). No DFU switch needed.
if ! in_dfu; then
    COM="$(powershell -NoProfile -Command "Get-CimInstance Win32_PnPEntity | Where-Object { \$_.PNPDeviceID -match 'VID_1209&PID_0D32' -and \$_.Name -match '\((COM\d+)\)' } | ForEach-Object { \$Matches[1] } | Select-Object -First 1" 2>/dev/null | tr -d '\r')"
    if [ -n "$COM" ]; then
        echo "Asking the ODrive on $COM to enter DFU (sd)..."
        printf 'sd\n' > "/dev/ttyS$(( ${COM#COM} - 1 ))" || true
        for _ in $(seq 20); do in_dfu && break; sleep 0.5; done
    fi
fi

if ! in_dfu; then
    echo "No STM32 in DFU mode. Firmware without 'sd', motor armed or board not on USB:"
    echo "set the DFU switch, power-cycle the board and retry."
    echo "(If the board is in DFU but not listed: install the WinUSB driver for 'STM32 BOOTLOADER' with Zadig.)"
    exit 1
fi

# Every STM32 ROM uses 0483:df11. Flash only a single board whose flash map is the F405's 1 MB
# (another MCU on the same PC, e.g. an F446 with 03*128Kg, would otherwise get this image).
[ "$(dfu_alt0 | wc -l)" = 1 ] || { echo "More than one board in DFU mode: leave only the ODrive. Nothing flashed."; exit 1; }
dfu_alt0 | grep -q '07\*128Kg' || { echo "The board in DFU mode is not an ODrive (F405, 1 MB flash). Nothing flashed."; exit 1; }

"$DFU" -d 0483:df11 -a 0 -s 0x08000000:leave -D "$BIN"
echo "Flashed and restarted. If the DFU switch was used, return it to RUN before the next power-up."
