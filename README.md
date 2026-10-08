# Flashback Touch

**Flashback Touch** is the Android ARM64 (`aarch64`) native runtime companion mod for the [Flashback](https://github.com/Moulberry/Flashback) Minecraft replay editor mod. It enables Flashback to run smoothly on Android launchers like **PojavLauncher** and **ZalithLauncher** without modifying Flashback's JAR.

[![Support on Ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/wild_drs)

---

## Features

- **Dear ImGui ARM64 Engine**: Native compilation of Dear ImGui v1.90.0 docking branch with 100% symbol parity (`Java_imgui_moulberry90_*`), enabling the full NLE timeline, docking panels, 3D viewport navigation, and keyframe editors.
- **Integrated Video Export (FFmpeg)**: Bundles Android Bionic ARM64 FFmpeg & JavaCPP binaries for direct in-game MP4, MKV, and WebM rendering without desktop dependencies.
- **Android Export Dialog Bypass**: Intercepts desktop SDL file dialog calls (`SDL_ShowSaveFileDialog`) on Android launchers, resolving export paths automatically to `.minecraft/flashback/videos/` to prevent UI freezing.
- **Audio Loopback Safe Guard**: Guards desktop OpenAL loopback recording calls (`ALC_SOFT_loopback`) on Android's OpenSL ES/AAudio audio driver, ensuring uninterrupted rendering.
- **Zero Linker Collisions**: Uses an isolated C++ runtime (`libc++_flashtoch.so`) to completely avoid collisions with launcher renderers (such as MobileGlues, Angle, or Turnip).
- **Android Bionic Namespace Protector**: Automatically extracts native binaries into the app's internal `/data/...` directory during pre-launch, preventing Android `permitted_paths` security violations when running from SD card storage.
- **Universal Version Support**: Pure math and layout engine with zero Blaze3D/OpenGL/GLFW coupling, making it compatible across all Flashback versions (Minecraft 1.21.x, 26.x, and beyond).

---

## Installation

1. Grab **[`flashbacktouch-1.0.0.jar`](dist/flashbacktouch-1.0.0.jar)** from the `dist/` folder.
2. Place both **Flashback** and **`flashbacktouch-1.0.0.jar`** into your launcher's `mods` folder:
   ```
   .minecraft/mods/
   ├── flashback-<version>.jar
   └── flashbacktouch-1.0.0.jar
   ```
3. Launch Minecraft with Fabric Loader in PojavLauncher or ZalithLauncher.

---

## Recommended Controls (On-Screen Mapping)

Configure your launcher's custom on-screen touch controls with the following mappings:

| Button | Action | Flashback Function |
| :--- | :--- | :--- |
| **L-CLICK** | Left Mouse Button | Scrub timeline, click UI buttons, drag docking panels |
| **R-CLICK** | Right Mouse Button | Select entities in 3D viewport, open entity popup |
| **WHEEL UP** | Mouse Wheel Up | Increase flying camera speed / Zoom timeline |
| **WHEEL DN** | Mouse Wheel Down | Decrease flying camera speed / Zoom out timeline |
| **SPACE** | Spacebar | Play / Pause replay playback |
| **ESC** | Escape | Close popup dialogs, exit timeline modals |

---

## Project Structure

```
FlashbackTouch/
├── README.md                      # Project overview and quick start guide
├── LICENSE                        # Licenses (MIT, Apache 2.0, LGPL 2.1+)
├── build_all.sh                   # One-click build script for the full addon JAR
├── build_so.sh                    # C++ compilation delegator for libimgui-moulberry90-java64.so
│
├── dist/                          # Production deliverables
│   ├── flashbacktouch-1.0.0.jar   # All-in-One Fabric companion mod (Dear ImGui + FFmpeg)
│   ├── libimgui-moulberry90-java64.so # Standalone ARM64 Dear ImGui shared library
│   ├── libc++_flashtoch.so        # Collision-free C++ runtime
│   └── flashtoch-ffmpeg-1.0.0.jar # Standalone modular FFmpeg addon
│
├── flashtoch-addon/               # Fabric addon mod source code
│   ├── build.gradle               # Gradle build file
│   ├── settings.gradle
│   └── src/main/
│       ├── java/com/flashtoch/    # PreLaunchEntrypoint implementation
│       └── resources/             # fabric.mod.json and bundled ARM64 natives
│
├── imgui-android/                 # Standalone Dear ImGui ARM64 Android port (sub-repo)
│   ├── src/                       # Relocated JNI C++ sources (150 files)
│   ├── build.sh                   # Native clang++ build script
│   └── dist/                      # libimgui-moulberry90-java64.so output
│
├── scripts/                       # Orchestration scripts
│   ├── clone_all.sh               # Companion repo cloner
│   └── package_ffmpeg.sh          # Official Bionic FFmpeg packager
│
├── docs/                          # In-depth technical documentation
│   ├── android_port_guide.md      # Full step-by-step porting guide & checklist
│   ├── imgui.md                   # Analysis of Flashback's Dear ImGui architecture
│   ├── chatlog.md                 # Complete milestone and discovery log
│   └── diagnostics/               # Symbol dump parity logs
│
└── flashback-reference/           # Upstream Flashback mod source reference
```

---

## Modular Architecture & Repositories

Flashback Touch uses a clean, two-repository architecture:

1. **[`FlashbackTouch`](https://github.com/git-drs/FlashbackTouch)** (This Repository):
   - The main Fabric companion mod with pre-launch extraction logic and runtime compatibility Mixins.
   - Includes `scripts/package_ffmpeg.sh` to package official Bionic FFmpeg binaries.
   - Orchestrates the full build process and produces the final `flashbacktouch-1.0.0.jar`.
2. **[`imgui-android`](https://github.com/git-drs/imgui-android)**:
   - Standalone C++ ARM64 Android NDK port of Dear ImGui with `imgui.moulberry90` JNI relocation.
   - Compiles `libimgui-moulberry90-java64.so` and `libc++_flashtoch.so`.

---

## Building from Source

### 1. Prerequisites (Termux or Linux ARM64)
- `clang++` (LLVM 17+)
- `openjdk-21` or `openjdk-17`
- `patchelf`

### 2. Auto-Clone & Build
To automatically clone the `imgui-android` companion repository, package Bionic FFmpeg, and build the final mod:
```bash
# Optional: Set your GitHub username/org (default: git-drs)
export FLASHTOCH_GITHUB_USER="git-drs"

# One-click auto setup & build:
bash build_all.sh
```

Or clone the companion repository manually before building:
```bash
bash scripts/clone_all.sh
bash build_all.sh
```

---

## Credits, Licenses & Upstream Sources

This project stands on the shoulders of incredible open-source projects:

- **Flashback Touch Mod**: [MIT License](LICENSE) (Maintained by [@git-drs](https://github.com/git-drs)).
- **Flashback**: Created by Moulberry ([Official Modrinth Page](https://modrinth.com/mod/flashback)). Flashback Touch is an independent third-party companion and does not redistribute Flashback.
- **Dear ImGui**: Created by Omar Cornut ([ocornut/imgui](https://github.com/ocornut/imgui)) — [MIT License](https://github.com/ocornut/imgui/blob/master/LICENSE.txt).
- **imgui-java**: JNI bindings created by SpaiR ([SpaiR/imgui-java](https://github.com/SpaiR/imgui-java)) — [Apache License 2.0](https://github.com/SpaiR/imgui-java/blob/master/LICENSE).
- **FFmpeg**: Licensed under the [GNU LGPL v2.1+](https://ffmpeg.org/legal.html). Upstream source code is available at [ffmpeg.org](https://ffmpeg.org/) and [github.com/FFmpeg/FFmpeg](https://github.com/FFmpeg/FFmpeg).
- **JavaCPP & FFmpeg Presets**: Created by Samuel Audet & Bytedeco ([bytedeco/javacpp](https://github.com/bytedeco/javacpp) and [bytedeco/javacpp-presets](https://github.com/bytedeco/javacpp-presets)) — [Apache License 2.0](https://github.com/bytedeco/javacpp/blob/master/LICENSE.txt).
