#!/usr/bin/env bash
# Flash builds/ODrive-fw-v0.5.6-<board>.bin over USB DFU.
# Usage: tools/flash.sh [board]   (default v3.6-56V-MKS-S)
# The board must already be in DFU mode (DFU switch + power cycle).
# The .bin only covers 0x08000000..; NVM (0x080C0000) is untouched, so saved config survives.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DFU="$ROOT/tools/dfu-util-static.exe"
[ -x "$DFU" ] || DFU="$ROOT/tools/dfu-util.exe"
BIN="$ROOT/builds/ODrive-fw-v0.5.6-${1:-v3.6-56V-MKS-S}.bin"

[ -x "$DFU" ] || { echo "dfu-util not found: copy dfu-util-static.exe to tools/"; exit 1; }
[ -f "$BIN" ] || { echo "no firmware: run tools/build.sh first"; exit 1; }

# 0483:df11 = STM32 system bootloader
if ! "$DFU" -l 2>/dev/null | grep -q "0483:df11"; then
    echo "No STM32 in DFU mode. Set the DFU switch, power-cycle the board and retry."
    echo "(If the board is in DFU but not listed: install the WinUSB driver for 'STM32 BOOTLOADER' with Zadig.)"
    exit 1
fi

"$DFU" -d 0483:df11 -a 0 -s 0x08000000:leave -D "$BIN"
echo "Flashed. Return the switch to RUN before the next power-up."
