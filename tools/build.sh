#!/usr/bin/env bash
# Build ODrive 0.5.6 firmware and copy it to builds/ODrive-fw-v0.5.6-<board>.{bin,hex,elf}.
# Usage: tools/build.sh [board]   e.g. v3.6-56V-MKS-S (default), v3.6-56V, v3.6-24V
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FW="$ROOT/ODrive-fw-v0.5.6/ODrive-fw-v0.5.6/Firmware"
BOARD="${1:-v3.6-56V-MKS-S}"

# Use GCC 13.3: 14.2 (also i686) fails under tup with "cannot execute 'cc1'" (cause not investigated)
export PATH="/c/Tools/tup/tup-latest:/c/Program Files (x86)/Arm GNU Toolchain arm-none-eabi/13.3 rel1/bin:$PATH"

cd "$FW"
[ -f tup.config ] || cp tup.config.default tup.config   # tup.config is gitignored upstream
mkdir -p build/obj autogen                               # ditto; tup won't create them
sed -i "s/^#\?CONFIG_BOARD_VERSION=.*/CONFIG_BOARD_VERSION=$BOARD/" tup.config
tup --no-environ-check

mkdir -p "$ROOT/builds"
for ext in bin hex elf; do
    cp "build/ODriveFirmware.$ext" "$ROOT/builds/ODrive-fw-v0.5.6-$BOARD.$ext"
done
arm-none-eabi-size build/ODriveFirmware.elf
echo "OK -> builds/ODrive-fw-v0.5.6-$BOARD.{bin,hex,elf}"
