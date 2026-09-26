# ODrive 0.5.6_MKS

[![Buy Me a Coffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-ffdd00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black)](https://buymeacoffee.com/artapo)

ODrive fw-v0.5.6 adapted for the Makerbase MKS ODrive S and MKS ODrive v3.6.

## Build

Requires tup (`C:\Tools\tup\tup-latest`) and Arm GNU Toolchain **13.3** (14.2 fails under tup). From Git Bash:

```bash
tools/build.sh v3.6-56V-MKS-S   # MKS ODrive S (default)
tools/build.sh v3.6-56V         # MKS ODrive v3.6, 56V
tools/build.sh v3.6-24V         # MKS ODrive v3.6, 24V
```

Output: `builds/ODrive-fw-v0.5.6-<board>.{bin,hex,elf}`. In VS Code: `Ctrl+Shift+B`.

## Flash (USB DFU)

Needs dfu-util, not included: download `dfu-util-0.11-binaries` from https://dfu-util.sourceforge.net/releases/ and copy `win64/dfu-util-static.exe` to `tools/`. On Windows the STM32 bootloader may also need the WinUSB driver (Zadig).

DFU switch on, power-cycle, then `tools/flash.sh <board>`. Saved configuration (NVM) is preserved.

## Changes vs official ODrive fw-v0.5.6

- `Board/v3/board.cpp`: boot with fake OTP when the OTP board version doesn't match (MKS boards would hang).
- `v3.6-56V-MKS-S` board (`-DMKS_ODRIVE_S`): only the M0 power stage exists; axis1 is never set up, checked or armed.
- `Firmware/autogen/version.c` is committed (its generator is disabled); it must keep reporting 0.5.6 for odrivetool.
- CAN contract for the ODrive_Motion project (`docs/specs/xdrive_can.md` in the parent repo),
  all off unless configured:
  - `Get_Identity` (0x1E, RTR): 48-bit serial + contract version (1).
  - `Get_Temperature` (0x1F): FET + motor temperature, cyclic via `axis.config.can.temperature_rate_ms`.
  - Watchdog is fed only by `Set_Input_Pos/Vel/Torque`.
  - Single-axis boards (`MKS_ODRIVE_S`): axis1 is not on the CAN bus.
  - Mechanical brake: `release_delay_ms` (default 30, clamped 20..100) before PWM and
    `engage_delay_ms` (default 20, max 30) before engaging; any engage (idle, error, fibre call)
    disarms the motor first; state in heartbeat motor flags bit 1.
- New config fields change the saved-config layout: `odrivetool backup-config` before
  flashing, `restore-config` after.

## License

- Changes and scripts in this repository: MIT, see [LICENSE](LICENSE).
- ODrive firmware (`ODrive-fw-v0.5.6/`): MIT, © ODrive Robotics / Oskar Weigl, see its [LICENSE.md](ODrive-fw-v0.5.6/ODrive-fw-v0.5.6/LICENSE.md). Bundled third-party code (FreeRTOS, STM32 HAL, CMSIS, ...) keeps its own license headers.
