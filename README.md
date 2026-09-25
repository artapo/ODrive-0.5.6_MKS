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

DFU switch on, power-cycle, then `tools/flash.sh <board>`. Saved configuration (NVM) is preserved.

## Changes vs official ODrive fw-v0.5.6

- `Board/v3/board.cpp`: boot with fake OTP when the OTP board version doesn't match (MKS boards would hang).
- `v3.6-56V-MKS-S` board (`-DMKS_ODRIVE_S`): only the M0 power stage exists; axis1 is never set up, checked or armed.
- `Firmware/autogen/version.c` is committed (its generator is disabled); it must keep reporting 0.5.6 for odrivetool.

## License

- Changes and scripts in this repository: MIT, see [LICENSE](LICENSE).
- ODrive firmware (`ODrive-fw-v0.5.6/`): MIT, © ODrive Robotics / Oskar Weigl, see its [LICENSE.md](ODrive-fw-v0.5.6/ODrive-fw-v0.5.6/LICENSE.md). Bundled third-party code (FreeRTOS, STM32 HAL, CMSIS, ...) keeps its own license headers.
- `tools/dfu-util-static.exe`: dfu-util 0.11, **GPL-2.0**, unmodified. License and corresponding source in [tools/dfu-util-src/](tools/dfu-util-src/); it statically links libusb (LGPL-2.1, https://github.com/libusb/libusb).
