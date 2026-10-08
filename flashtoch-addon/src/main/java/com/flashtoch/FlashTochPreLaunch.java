package com.flashtoch;

import net.fabricmc.loader.api.FabricLoader;
import net.fabricmc.loader.api.entrypoint.PreLaunchEntrypoint;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;

public class FlashTochPreLaunch implements PreLaunchEntrypoint {

    private static final String IMGUI_LIB = "libimgui-moulberry90-java64.so";
    private static final String LIBCXX_LIB = "libc++_flashtoch.so";

    @Override
    public void onPreLaunch() {
        System.out.println("[Flashback Touch] ===============================================");
        System.out.println("[Flashback Touch] Initializing Flashback Touch Android ARM64 runtime...");

        String osArch = System.getProperty("os.arch", "").toLowerCase();
        System.out.println("[Flashback Touch] Detected CPU architecture: " + osArch);

        try {
            Path nativesDir = determineNativesDir();
            Files.createDirectories(nativesDir);
            System.out.println("[Flashback Touch] Selected natives directory: " + nativesDir.toAbsolutePath());

            // 1. Extract libc++_shared.so
            Path libcxxTarget = nativesDir.resolve(LIBCXX_LIB);
            if (extractResource("/natives/" + LIBCXX_LIB, libcxxTarget)) {
                try {
                    System.load(libcxxTarget.toAbsolutePath().toString());
                    System.out.println("[Flashback Touch] Pre-loaded " + LIBCXX_LIB);
                } catch (Throwable t) {
                    System.out.println("[Flashback Touch] Note: automatic linker will load " + LIBCXX_LIB + " via $ORIGIN");
                }
            }

            // 2. Extract libimgui-moulberry90-java64.so
            Path imguiTarget = nativesDir.resolve(IMGUI_LIB);
            if (extractResource("/natives/" + IMGUI_LIB, imguiTarget)) {
                try {
                    imguiTarget.toFile().setExecutable(true, false);
                    imguiTarget.toFile().setReadable(true, false);
                } catch (Exception ignored) {}

                // Set property that Flashback checks before attempting any native loading
                System.setProperty("imgui.library.path", nativesDir.toAbsolutePath().toString());
                System.out.println("[Flashback Touch] Set imgui.library.path = " + System.getProperty("imgui.library.path"));
                System.out.println("[Flashback Touch] Flashback is now armed with ARM64 Dear ImGui!");

                // Configure JavaCPP cache directory to internal /data storage for safe FFmpeg dlopen
                Path javacppCache = nativesDir.resolve(".javacpp-cache");
                System.setProperty("org.bytedeco.javacpp.cachedir", javacppCache.toAbsolutePath().toString());
                System.out.println("[Flashback Touch] Set org.bytedeco.javacpp.cachedir = " + javacppCache.toAbsolutePath());
            } else {
                System.err.println("[Flashback Touch] ERROR: Failed to extract " + IMGUI_LIB);
            }

            System.out.println("[Flashback Touch] ===============================================");
        } catch (Exception e) {
            System.err.println("[Flashback Touch] Error during FlashToch initialization: " + e.getMessage());
            e.printStackTrace();
        }
    }

    private static Path determineNativesDir() {
        // Android bionic linker namespace requires dlopen targets to be under /data
        try {
            Path gameDir = FabricLoader.getInstance().getGameDir();
            Path candidate = gameDir.resolve(".flashtoch-natives");
            String real = candidate.toAbsolutePath().toString();
            try {
                if (Files.exists(gameDir)) {
                    real = gameDir.toRealPath().toString();
                }
            } catch (Exception ignored) {}

            if (real.startsWith("/data")) {
                return candidate;
            }
        } catch (Throwable ignored) {}

        // Fallback to java.io.tmpdir (guaranteed inside app's private /data on Android)
        String tmp = System.getProperty("java.io.tmpdir");
        if (tmp != null && !tmp.isEmpty()) {
            Path candidate = Paths.get(tmp).resolve("flashtoch-natives");
            if (candidate.toAbsolutePath().toString().startsWith("/data")) {
                return candidate;
            }
        }

        // Fallback to user.home
        String home = System.getProperty("user.home");
        if (home != null && !home.isEmpty()) {
            Path candidate = Paths.get(home).resolve(".flashtoch-natives");
            if (candidate.toAbsolutePath().toString().startsWith("/data")) {
                return candidate;
            }
        }

        // Default fallback
        try {
            return FabricLoader.getInstance().getGameDir().resolve(".flashtoch-natives");
        } catch (Throwable t) {
            return Paths.get(System.getProperty("java.io.tmpdir", ".")).resolve("flashtoch-natives");
        }
    }

    private static boolean extractResource(String resourcePath, Path destination) {
        try (InputStream in = FlashTochPreLaunch.class.getResourceAsStream(resourcePath)) {
            if (in == null) {
                System.err.println("[Flashback Touch] Resource not found: " + resourcePath);
                return false;
            }
            Files.copy(in, destination, StandardCopyOption.REPLACE_EXISTING);
            try {
                destination.toFile().setReadable(true, false);
            } catch (Exception ignored) {}
            return true;
        } catch (IOException e) {
            System.err.println("[Flashback Touch] Failed to extract " + resourcePath + ": " + e.getMessage());
            return false;
        }
    }
}
