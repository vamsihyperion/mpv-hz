# mpv-hz

> A portable, high-performance multimedia player distribution based on **[mpv](https://mpv.io/)** (`v0.41.0+`), engineered with **libplacebo** `gpu-next`, AI upscaling shaders, spatial HRTF surround sound, and a modern UI.

---

## 📋 Table of Contents
- [Overview & Specifications](#-overview--specifications)
- [mpv v0.41.0 Release Highlights](#-mpv-v0410-release-highlights)
- [Key Features of mpv-hz](#-key-features-of-mpv-hz)
  - [Modern UI & Controller (uosc + thumbfast)](#1-modern-ui--controller-uosc--thumbfast)
  - [Next-Gen Video Rendering (gpu-next)](#2-next-gen-video-rendering-gpu-next)
  - [AI Upscaling & Shaders (FSR, NIS, Anime4K, ArtCNN)](#3-ai-upscaling--shaders-fsr-nis-anime4k-artcnn)
  - [Binaural 3D Surround Audio (SOFALizer / HRTF)](#4-binaural-3d-surround-audio-sofalizer--hrtf)
  - [Streaming & YouTube Support (yt-dlp)](#5-streaming--youtube-support-yt-dlp)
  - [Automation & Cropping Utilities](#6-automation--cropping-utilities)
- [Quick Start & Installation](#-quick-start--installation)
- [Keyboard & Mouse Shortcuts](#-keyboard--mouse-shortcuts)
- [Updating mpv-hz](#-updating-mpv-hz)

---

## 🔍 Overview & Specifications

| Component | Bundled Version / Details |
| :--- | :--- |
| **Core Player** | `mpv v0.41.0-724-g71ebd0840` (64-bit Windows) |
| **Video Renderer** | `libplacebo v7.365.0` via `vo=gpu-next` |
| **Multimedia Engine** | `FFmpeg N-124864 / N-124930` (Clang LTO build) |
| **Stream Downloader**| `yt-dlp 2026.08.17+` |
| **Interface** | Modern `uosc` overlay + `thumbfast` real-time seek previews |
| **Spatial Audio** | FFmpeg `sofalizer` with 24-bit 96kHz 512-tap FIR HRTF |
| **Configuration** | Fully self-contained portable configuration (`portable_config`) |

---

## 🚀 mpv v0.41.0 Release Highlights

The `mpv v0.41.0` release series brings significant architectural modernization:

- **`gpu-next` Enabled by Default**: Built on **libplacebo**, providing state-of-the-art HDR10 tone mapping, Dolby Vision dynamic metadata parsing, wide color gamut mapping, and advanced scaling filters.
- **Vulkan Hardware Decoding Priority**: Prioritizes modern Vulkan video decoding acceleration (`hwdec=vulkan`) alongside D3D11 and NVDEC for lower latency and smoother playback.
- **Wayland & Presentation Overhauls**: Introduced color representation protocol support (`wp-color-representation-v1`), tablet input mapping, and refined fractional scaling handling.
- **Audio Subsystem Updates**: Low-latency native AAudio backend for Android and modernized channel mapping across platforms.
- **App Registration Utilities**: Streamlined Windows shell registration (`mpv-register` and `mpv-unregister`).
- **Demuxer & Seeking Efficiency**: Optimized demuxer cache readahead and backbuffer retention for instantaneous forward and backward seeks.

---

## ✨ Key Features of mpv-hz

### 1. Modern UI & Controller (uosc + thumbfast)
- **Minimalist OSD/OSC**: Powered by **uosc**, providing fluid menus for audio tracks, subtitle selection, stream quality, aspect ratio, and chapter lists.
- **Hover Thumbnail Previews**: Driven by **thumbfast**, showing instant seek-bar video frame thumbnails while hovering without stuttering playback.
- **Playlist Manager**: Interactive playlist drawer (`P` or `TAB`) to reorder, delete, and switch tracks on the fly.

### 2. Next-Gen Video Rendering (`gpu-next`)
- **Auto-Quality Profiles**: Automatically detects hardware capabilities and video resolution:
  - **High-Quality Desktop Profile**: Utilizes `ewa_lanczossharp` luma scaling, `ewa_lanczossoft` chroma scaling, `mitchell` downscaling, and debanding.
  - **Laptop & Battery Optimization**: Low-power spline36/bilinear fallbacks when running on battery to conserve power.
  - **4K Decoding Threads**: Automatic multi-thread allocation (`vd-lavc-threads=32`) for high-bitrate UHD content.

### 3. AI Upscaling & Shaders (FSR, NIS, Anime4K, ArtCNN)
Quickly toggle industry-leading spatial and neural upscalers via hotkeys:
- **AMD FidelityFX Super Resolution (FSR 1.0)**: Press <kbd>Ctrl</kbd> + <kbd>A</kbd> for crisp edge reconstruction.
- **NVIDIA Image Scaling (NIS)**: Press <kbd>Ctrl</kbd> + <kbd>N</kbd> for directional scaling and adaptive sharpening.
- **Anime4K Shaders**: High-quality CNN restorative upscaling tailored for animation (<kbd>Ctrl</kbd> + <kbd>1</kbd> to <kbd>Ctrl</kbd> + <kbd>6</kbd>).
- **ArtCNN & Adaptive Sharpen**: <kbd>Ctrl</kbd> + <kbd>8</kbd> for deep-learning artifact removal and sharpening.
- **Clear Shaders**: Press <kbd>Ctrl</kbd> + <kbd>Z</kbd> or <kbd>Ctrl</kbd> + <kbd>0</kbd> to return to baseline rendering.

### 4. Binaural 3D Surround Audio (SOFALizer / HRTF)
- **True Headphone Spatial Audio**: Transforms multichannel audio (5.1, 7.1, Dolby Atmos soundtracks) into an immersive 3D binaural soundstage using Head-Related Transfer Functions (`D1_96K_24bit_512tap_FIR_SOFA.sofa`).
- **Surround Auto-Detection**: Activates conditionally when more than 2 audio channels are present.
- **Dolby Helpers**:
  - `dolby.bat` - Launch files directly in high-precision `gpu-next` surround mode.
  - `dolby_screens.bat` - Automatically generate an 8-point timestamped screenshot sequence of the video via `takeSsSequence.js`.

### 5. Streaming & YouTube Support (`yt-dlp`)
- Integrated **`yt-dlp`** binary with YouTube cookie authentication support (`cookies.txt`).
- On-the-fly resolution and codec selector menu via `youtube-quality.lua`.
- 500 MB demuxer forward cache and 100 MB backbuffer for smooth network streaming.

### 6. Automation & Cropping Utilities
- **Interactive Crop (`easycrop.lua`)**: Press <kbd>C</kbd> and draw a box with your cursor to crop out black bars or zoom in.
- **Auto-Crop (`autocrop.lua`)**: Press <kbd>X</kbd> to automatically detect and crop hardcoded letterbox bars.
- **Autoload (`autoload.lua`)**: Automatically loads subsequent episodes and media in the same directory.
- **Watch Later (`autosave.lua` / `Q`)**: Automatically bookmarks timestamp, volume, audio, and subtitle track choices upon exit.

---

## 🛠️ Quick Start & Installation

### Option 1: Standalone Portable Mode
No installation required. Run `mpv.exe` directly or drag-and-drop any media file onto `mpv.exe` or `dolby.bat`. All configs reside locally in `portable_config/`.

### Option 2: Register as Default Windows Player
1. Navigate to the `installer/` directory.
2. Right-click **`mpv-install.bat`** and select **Run as Administrator**.
3. mpv will be registered in Windows Default Apps and the "Open with" context menu for all popular audio and video extensions.
4. To uninstall, run `mpv-uninstall.bat` as Administrator.

---

## ⌨️ Keyboard & Mouse Shortcuts

### Playback & Navigation
| Key | Action |
| :--- | :--- |
| <kbd>Space</kbd> | Play / Pause |
| <kbd>→</kbd> / <kbd>←</kbd> | Seek forward / backward 3 seconds |
| <kbd>↑</kbd> / <kbd>↓</kbd> | Seek forward / backward 6 seconds |
| <kbd>Ctrl</kbd> + <kbd>→</kbd> / <kbd>←</kbd> | Seek forward / backward 30 seconds |
| <kbd>Ctrl</kbd> + <kbd>↑</kbd> / <kbd>↓</kbd> | Seek forward / backward 60 seconds |
| <kbd>Shift</kbd> + <kbd>→</kbd> / <kbd>←</kbd> | Seek forward / backward 5 minutes |
| <kbd>Shift</kbd> + <kbd>↑</kbd> / <kbd>↓</kbd> | Seek forward / backward 10 minutes |
| <kbd>[</kbd> / <kbd>]</kbd> | Adjust playback speed (±0.01x) |
| <kbd>{</kbd> / <kbd>}</kbd> | Adjust playback speed (±0.2x) |
| <kbd>\</kbd> | Reset playback speed to 1.0x |
| <kbd>Home</kbd> | Jump to start of video |
| <kbd>Q</kbd> | Save playback position and quit |

### Video & Display
| Key | Action |
| :--- | :--- |
| <kbd>F</kbd> / <kbd>Double Left Click</kbd> | Toggle Fullscreen |
| <kbd>T</kbd> / <kbd>Right Click</kbd> | Toggle Always-on-Top |
| <kbd>A</kbd> / <kbd>Shift</kbd> + <kbd>Enter</kbd> | Cycle Aspect Ratio (`16:9`, `4:3`, `2.35:1`, auto) |
| <kbd>R</kbd> / <kbd>Ctrl</kbd> + <kbd>Enter</kbd> | Rotate Video (90° / 180° / 270° / 0°) |
| <kbd>Z</kbd> | Toggle Keep Aspect Ratio |
| <kbd>C</kbd> | Draw interactive crop area (`easycrop`) |
| <kbd>X</kbd> | Auto-detect and crop black bars (`autocrop`) |
| <kbd>D</kbd> | Toggle Deinterlacing |
| <kbd>S</kbd> | Take high-quality screenshot |
| <kbd>V</kbd> | Toggle enhanced color & contrast filter |
| <kbd>Backspace</kbd> / <kbd>F12</kbd> | Reset zoom, pan, colors, aspect ratio, audio & sub delay |

### Shaders & Upscaling
| Shortcut | Preset / Filter |
| :--- | :--- |
| <kbd>Ctrl</kbd> + <kbd>A</kbd> | **AMD FidelityFX Super Resolution (FSR 1.0)** |
| <kbd>Ctrl</kbd> + <kbd>N</kbd> | **NVIDIA Image Scaling (NIS)** |
| <kbd>Ctrl</kbd> + <kbd>1</kbd> | **Anime4K: Mode A (HQ)** (Restore CNN + Upscale) |
| <kbd>Ctrl</kbd> + <kbd>2</kbd> | **Anime4K: Mode B (HQ)** (Restore Soft + Upscale) |
| <kbd>Ctrl</kbd> + <kbd>3</kbd> | **Anime4K: Mode C (HQ)** (Denoise + Upscale) |
| <kbd>Ctrl</kbd> + <kbd>4</kbd> - <kbd>6</kbd> | **Anime4K Combined Modes** (A+A, B+B, C+A) |
| <kbd>Ctrl</kbd> + <kbd>8</kbd> | **ArtCNN C4F16** + Adaptive Sharpen |
| <kbd>Ctrl</kbd> + <kbd>Z</kbd> / <kbd>Ctrl</kbd> + <kbd>0</kbd> | Clear all active GLSL shaders |

### Audio & Subtitles
| Key | Action |
| :--- | :--- |
| <kbd>Mouse Wheel</kbd> / <kbd>"</kbd> / <kbd>'</kbd> | Volume Up / Down |
| <kbd>M</kbd> | Toggle Mute |
| <kbd>K</kbd> | Cycle Audio Track |
| <kbd>J</kbd> | Cycle Subtitle Track |
| <kbd>Ctrl</kbd> + <kbd>J</kbd> / <kbd>Alt</kbd> + <kbd>J</kbd> | Increase / Decrease Subtitle Size |
| <kbd>Alt</kbd> + <kbd>↑</kbd> / <kbd>↓</kbd> | Shift Subtitle Position Up / Down |
| <kbd>-</kbd> / <kbd>=</kbd> | Adjust Audio-to-Video Delay (±0.10s) |
| <kbd>0</kbd> | Reset Audio Delay to 0 |
| <kbd>N</kbd> | Toggle ASS Subtitle Style Override |

### Playlist & OSD
| Key | Action |
| :--- | :--- |
| <kbd>P</kbd> / <kbd>Tab</kbd> | Toggle Playlist Menu |
| <kbd><</kbd> / <kbd>></kbd> | Previous / Next file in playlist |
| <kbd>L</kbd> | Toggle Loop Playlist |
| <kbd>:</kbd> | Toggle Loop Current File |
| <kbd>W</kbd> | Show on-screen system clock |
| <kbd>I</kbd> | Toggle media statistics and cache readout |
| <kbd>`</kbd> / <kbd>~</kbd> | Show Chapter List |

---

## 🔄 Updating mpv-hz

To keep mpv and `yt-dlp` up to date with the latest upstream builds:

- **Automatic Updater**: Double-click **`updater.bat`** (or execute `updater.ps1` in PowerShell).
- **Direct SourceForge Checker**: Run **`update_mpv.bat`** to fetch the latest Windows 64-bit build.
