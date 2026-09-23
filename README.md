# Watermelon-Wine-1A

Open-source embedded computer project based on the **STM32MP25x** SoC, running
**OpenSTLinux** (Yocto `scarthgap`) with Qt 6 applications (OpenNOW,
NanoBrowser, YtGst).

This repository contains both the **software** (OpenSTLinux build, layers) and
the **hardware** design files (schematics, routing, clocks).

## Repository structure

| Path | Contents |
| --- | --- |
| `watermelon-wine-os` | Software: OpenSTLinux build + meta-layers |
| `schematics` | Board schematics (PDF) |
| `routing` | Signal routing / impedance guidelines, LPDDR4 length tables |
| `datasheets` | Component datasheets |
| `manuals` | ST application notes (DSI, DDR routing, security) |
| `compute` | Clock / timing calculation scripts |
| `LICENSE` | Project license |

## Boards

| Machine | Description |
| --- | --- |
| `watermelon-wine-1a` | Watermelon Wine 1A board that contains PCIe-Mini |
| `watermelon-wine-1b` | Watermelon Wine 1B board that contains USBC 3.0  |

## Prerequisites

- 64-bit Linux host with at least ~8 GB of RAM and enough disk space for an
  OpenSTLinux build (**50–100 GB**).
- **Network access** during the build (sources from GitHub/ST; Cargo crates
  from crates.io for the Rust application).
- `repo` tool installed on the host.

## Getting started

### 1. Clone the repository

```bash
git clone <this-repo-url>
cd watermelon-wine-os
```

### 2. Download the OpenSTLinux distribution

```bash
repo init -u https://github.com/STMicroelectronics/oe-manifest.git \
          -b refs/tags/openstlinux-6.6-yocto-scarthgap-mpu-v26.02.18
repo sync
```

### 3. Create the build environment

```bash
DISTRO=openstlinux-weston MACHINE=stm32mp25-mx source layers/meta-st/scripts/envsetup.sh
cd build-openstlinuxweston-stm32mp25-mx
```

This creates the `build-openstlinuxweston-stm32mp25-mx` folder.

### 4. Add the Watermelon-Wine layer

```bash
bitbake-layers add-layer ../layers/meta-watermelon-wine
bitbake-layers show-layers
```

The output should contain a line similar to:

```
watermelon-wine   /home/mint/Documents/Github/Watermelon-Wine-1A/watermelon-wine-os/layers/meta-watermelon-wine  8
```

### 5. Configure the build

Open the build configuration:

```bash
nano conf/local.conf
```

Set the target board and parallelism. `4` threads is recommended for 8 GB of
RAM; use `6` or `8` on a faster host.

```bash
MACHINE = "watermelon-wine-1a"        # or "watermelon-wine-1b"
BB_NUMBER_THREADS = "4"
PARALLEL_MAKE = "-j4"
```

Then **set the EULA acceptance** for your machine — otherwise the build fails
with Op-TEE panic errors. Replace the existing `ACCEPT_EULA_stm32mp25-mx`
line:

```bash
# =========================================================================
# Set EULA acceptance
# =========================================================================
ACCEPT_EULA_watermelon-wine-1a = "1"
```

### 6. Build an image

```bash
bitbake st-image-weston
```

## Images

| Image | Description |
| --- | --- |
| `st-image-weston` | Full image with Wayland/Weston + applications |
| `st-image-core` | Minimal console image |

## Applications

The board images include the Qt applications packaged by the
`meta-embedded-apps` layer:

| Application | Description |
| --- | --- |
| OpenNOW | Cloud-gaming client (Qt 6 + Rust) |
| NanoBrowser | Minimal QtWebEngine/QML browser |
| YtGst | YouTube client (GStreamer + yt-dlp, V4L2 hardware decode) |

Build them individually with:

```bash
bitbake opennow nanobrowser ytgst
```

## Troubleshooting

| Symptom | Fix |
| --- | --- |
| **Build aborts with Op-TEE panic** | `ACCEPT_EULA_<machine>` is missing or wrong in `local.conf` |
| **Build is very slow / OOM** | Lower `BB_NUMBER_THREADS` / `PARALLEL_MAKE`, e.g. `1` or `2` |
| **OpenNOW Cargo build fails** | Ensure crates.io is reachable during `do_compile` |
