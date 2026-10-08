# Why Dear ImGui is Used in Flashback

## 1. Executive Summary

[Flashback](https://github.com/Moulberry/Flashback) is a cinematic replay and video creation mod for Minecraft. Instead of using Minecraft's built-in GUI system (`Screen`, `AbstractWidget`, `DrawContext`) or standard modding UI libraries, Flashback embeds **Dear ImGui** (specifically a custom repackaged build: `imgui.moulberry90`, version 1.90.0 with the Docking branch enabled).

The primary reason for using Dear ImGui is that Flashback is designed not as a standard Minecraft menu, but as a **desktop-grade Non-Linear Video Editor (NLE) and Digital Content Creation (DCC) tool** (analogous to Blender, Unreal Engine Sequencer, or DaVinci Resolve) operating live within the Minecraft engine.

---

## 2. Core Architectural Reasons

### 2.1. Professional Dockable Workspace (`ImGuiConfigFlags.DockingEnable`)
- **Limitation of Vanilla Minecraft UI**: Vanilla Minecraft menus (`Screen`) are modal, single-screen surfaces that take over user input, hide the HUD, and cannot easily support simultaneously visible, resizable, dockable tool windows alongside active 3D gameplay.
- **The ImGui Solution**: In [`ReplayUI.java`](file:///data/data/com.termux/files/home/storage/shared/projects/FlashToch/flashback-reference/src/main/java/com/moulberry/flashback/editor/ui/ReplayUI.java#L611-L625), Flashback builds a full-screen dockspace:
  ```java
  int mainDock = ImGui.dockSpaceOverViewport(0, ImGui.getMainViewport(), ImGuiDockNodeFlags.NoDockingInCentralNode);
  ImGui.dockBuilderGetCentralNode(mainDock).addLocalFlags(ImGuiDockNodeFlags.NoTabBar);
  ```
- **Central 3D Viewport**: The central dock node hosts the 3D Minecraft gameplay preview ("Main" viewport), while panels dock around it:
  - **Timeline** at the bottom ([`TimelineWindow.java`](file:///data/data/com.termux/files/home/storage/shared/projects/FlashToch/flashback-reference/src/main/java/com/moulberry/flashback/editor/ui/windows/TimelineWindow.java))
  - **Visuals / Properties** on the right ([`VisualsWindow.java`](file:///data/data/com.termux/files/home/storage/shared/projects/FlashToch/flashback-reference/src/main/java/com/moulberry/flashback/editor/ui/windows/VisualsWindow.java))
  - **Player List**, **Movement Settings**, **Render Filters**, and **Keybinds** ([`WindowType.java`](file:///data/data/com.termux/files/home/storage/shared/projects/FlashToch/flashback-reference/src/main/java/com/moulberry/flashback/editor/ui/windows/WindowType.java))
- **Customizable Layouts**: Windows can be rearranged, resized, undocked into floating windows, collapsed, and persisted to `imgui.ini` across game sessions using default docking definitions in [`ReplayUIDefaults.java`](file:///data/data/com.termux/files/home/storage/shared/projects/FlashToch/flashback-reference/src/main/java/com/moulberry/flashback/editor/ui/ReplayUIDefaults.java#L9-L28).

---

### 2.2. Dynamic Viewport Resizing & Framebuffer Compositing
Unlike traditional mods that draw semi-transparent overlays on top of the full screen, Flashback dynamically adjusts Minecraft's 3D rendering pipeline to fit inside the ImGui dock layout:

1. **Pixel-Accurate Frame Sizing**: In [`ReplayUI.java`](file:///data/data/com.termux/files/home/storage/shared/projects/FlashToch/flashback-reference/src/main/java/com/moulberry/flashback/editor/ui/ReplayUI.java#L635-L669), the central dock window calculates exact bounds (`frameX`, `frameY`, `frameWidth`, `frameHeight`).
2. **Game Framebuffer Override**: Through mixins in [`MixinWindow.java`](file:///data/data/com.termux/files/home/storage/shared/projects/FlashToch/flashback-reference/src/main/java/com/moulberry/flashback/mixin/MixinWindow.java#L65-L95), Minecraft's game viewport (`overrideFramebufferWidth`, `overrideFramebufferHeight`) is updated to match the dock frame.
3. **Aspect Ratio Simulation**: Flashback supports custom production aspect ratios (e.g., 16:9 widescreen, 4:3, or 9:16 vertical format for TikTok/Shorts). If the dock window aspect ratio differs, it letterboxes/pillarboxes the viewport within the ImGui frame.
4. **Off-Screen Compositing**: In [`MixinMinecraft.java`](file:///data/data/com.termux/files/home/storage/shared/projects/FlashToch/flashback-reference/src/main/java/com/moulberry/flashback/mixin/MixinMinecraft.java#L112-L140):
   - The 3D world is rendered into an offscreen render target.
   - The texture is blitted into the docked bounding box.
   - The ImGui draw data render target (`ReplayUI.compositeOnTop`) is composited directly on top.

---

### 2.3. High-Density Interactive Timeline Editor (`TimelineWindow.java`)
The replay editor's most critical component is the multi-track timeline ([`TimelineWindow.java`](file:///data/data/com.termux/files/home/storage/shared/projects/FlashToch/flashback-reference/src/main/java/com/moulberry/flashback/editor/ui/windows/TimelineWindow.java), over 2,400 lines of code):

- **Multiple Track Types**: Handles independent tracks for Camera, Camera Orbit, Timelapse, FOV, Time of Day, Tickrate, Weather, Audio, Spectator, Block Overrides, and Entity Tracking.
- **DCC Timeline Features**:
  - Zoomable and pannable time ruler with tick markings and timecodes.
  - Export range in/out sliders.
  - Playhead scrubbing and frame-stepping.
  - Multi-keyframe marquee (box) selection.
  - Keyframe repositioning, snapping, and clipboard copy/paste with relative coordinate offsets (position, yaw, pitch).
  - Custom drawing using `ImDrawList` primitives (curves, markers, lines, custom colored nodes, and waveform indicators).

Building this level of graphical density and responsiveness in vanilla Minecraft GUI would require thousands of lines of fragile retained widget code.

---

### 2.4. Immediate-Mode UI vs. Retained-Mode Minecraft GUI
- **Retained-Mode Complexity**: Vanilla Minecraft's GUI paradigm is retained-mode: widgets are stateful objects instantiated in `Screen.init()`. Managing dozens of interacting keyframe tracks, dynamic entity lists, real-time scrubbing, and modal popups leads to frequent state desynchronization and massive boilerplate.
- **Immediate-Mode Simplicity**: In Dear ImGui, UI is declared directly alongside the state:
  ```java
  if (ImGui.checkbox(I18n.get("flashback.visuals.world.render_entities"), visuals.renderEntities)) {
      visuals.renderEntities = !visuals.renderEntities;
      editorState.markDirty();
  }
  ```
  State changes are reflected immediately without manual DOM/tree mutation or event bus dispatching.

---

### 2.5. Viewport Raycasting & DCC Camera Controls
Because ImGui manages input state explicitly, Flashback can distinguish between interacting with UI widgets and interacting with the 3D scene:

- **Raycasting from UI Coordinates**: [`ReplayUI.getMouseForwardsVector()`](file:///data/data/com.termux/files/home/storage/shared/projects/FlashToch/flashback-reference/src/main/java/com/moulberry/flashback/editor/ui/ReplayUI.java#L346-L385) inverts the Minecraft projection matrix based on mouse position inside the central dock frame.
- **Context Menus for World Objects**: Clicking an entity in the viewport opens an ImGui context popup ([`SelectedEntityPopup.java`](file:///data/data/com.termux/files/home/storage/shared/projects/FlashToch/flashback-reference/src/main/java/com/moulberry/flashback/editor/ui/windows/SelectedEntityPopup.java)) to track, attach camera, or filter that entity.
- **DCC Navigation Modes**: Implements 3D software camera controls in [`EditorMovementControls.java`](file:///data/data/com.termux/files/home/storage/shared/projects/FlashToch/flashback-reference/src/main/java/com/moulberry/flashback/editor/ui/EditorMovementControls.java):
  - **Rotate / Free-cam**
  - **Pan**
  - **Arcball / Orbit** around focal points

---

### 2.6. Low-Level Hardware GPU Rendering (`CustomImGuiImplB3D.java`)
Flashback renders ImGui with native performance:

- In [`CustomImGuiImplB3D.java`](file:///data/data/com.termux/files/home/storage/shared/projects/FlashToch/flashback-reference/src/main/java/com/moulberry/flashback/editor/ui/CustomImGuiImplB3D.java#L73-L120), Flashback creates a dedicated Blaze3D/Renderpearl pipeline:
  - Custom shader: `flashback:core/imgui_b3d`
  - Direct vertex buffer (`GpuBuffer`) and index buffer uploads.
  - Linear and Nearest texture samplers.
  - All panels, text, icons, and timeline controls are batched and drawn efficiently using hardware clipping/scissor rects.
- **Font & Icon Typography**: [`ReplayUI.initFonts()`](file:///data/data/com.termux/files/home/storage/shared/projects/FlashToch/flashback-reference/src/main/java/com/moulberry/flashback/editor/ui/ReplayUI.java#L176-L287) bundles custom TrueType typography:
  - **Inter (Medium, 16px)** for UI text.
  - **Material Icons Round** for UI icons (playback buttons, camera icons, lock/visibility toggles).
  - Noto Sans fallbacks for Chinese, Japanese, Korean, Cyrillic, and Hebrew.

---

## 3. Comparison: Flashback (Dear ImGui) vs. Legacy Replay Mod

| Feature | Legacy Replay Mod | Flashback (Dear ImGui) |
| :--- | :--- | :--- |
| **UI Paradigm** | Custom Minecraft Screen / GL overlay | Full Dockable NLE Workspace (Dear ImGui Docking) |
| **Viewport** | Fullscreen 3D world behind static GUI buttons | Embedded, letterboxable 3D viewport in dock center |
| **Panel Management** | Hardcoded positions; inflexible layout | Draggable, floating, dockable, and resizable panels |
| **Timeline Complexity** | Basic single/dual line timeline | Multi-track NLE timeline with marquee selection and zoom |
| **Aspect Ratio Preview** | None (constrained to game window) | Live preview for 16:9, 4:3, 9:16 vertical video |
| **Rendering Backend** | Legacy OpenGL immediate calls | Modern Mojang Renderpearl / Blaze3D GPU pipelines |

---

## 4. Key Files in Codebase

- [`ReplayUI.java`](file:///data/data/com.termux/files/home/storage/shared/projects/FlashToch/flashback-reference/src/main/java/com/moulberry/flashback/editor/ui/ReplayUI.java): ImGui context initialization, dockspace configuration, viewport bounds calculation, and font loading.
- [`ReplayUIDefaults.java`](file:///data/data/com.termux/files/home/storage/shared/projects/FlashToch/flashback-reference/src/main/java/com/moulberry/flashback/editor/ui/ReplayUIDefaults.java): Default docking layout configuration and custom dark color theme.
- [`CustomImGuiImplB3D.java`](file:///data/data/com.termux/files/home/storage/shared/projects/FlashToch/flashback-reference/src/main/java/com/moulberry/flashback/editor/ui/CustomImGuiImplB3D.java): Blaze3D / GPU pipeline backend implementation for Dear ImGui.
- [`CustomImGuiWindowerSdl.java`](file:///data/data/com.termux/files/home/storage/shared/projects/FlashToch/flashback-reference/src/main/java/com/moulberry/flashback/editor/ui/CustomImGuiWindowerSdl.java): SDL input and window event bridge for Dear ImGui.
- [`TimelineWindow.java`](file:///data/data/com.termux/files/home/storage/shared/projects/FlashToch/flashback-reference/src/main/java/com/moulberry/flashback/editor/ui/windows/TimelineWindow.java): Complete multi-track keyframe and playback timeline.
- [`VisualsWindow.java`](file:///data/data/com.termux/files/home/storage/shared/projects/FlashToch/flashback-reference/src/main/java/com/moulberry/flashback/editor/ui/windows/VisualsWindow.java): Replay visual settings, HUD toggles, and world rendering controls.
- [`StartExportWindow.java`](file:///data/data/com.termux/files/home/storage/shared/projects/FlashToch/flashback-reference/src/main/java/com/moulberry/flashback/editor/ui/windows/StartExportWindow.java): Video encoding, codec, bitrate, resolution, and export options.
- [`MixinMinecraft.java`](file:///data/data/com.termux/files/home/storage/shared/projects/FlashToch/flashback-reference/src/main/java/com/moulberry/flashback/mixin/MixinMinecraft.java): Intercepts the rendering loop to composite the docked 3D game scene with ImGui overlays.
- [`MixinWindow.java`](file:///data/data/com.termux/files/home/storage/shared/projects/FlashToch/flashback-reference/src/main/java/com/moulberry/flashback/mixin/MixinWindow.java): Overrides Minecraft window framebuffer dimensions to match the docked center frame.
