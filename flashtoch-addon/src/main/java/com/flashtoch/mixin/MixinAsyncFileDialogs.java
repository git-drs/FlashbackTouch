package com.flashtoch.mixin;

import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfoReturnable;

import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.concurrent.CompletableFuture;

@Mixin(targets = "com.moulberry.flashback.utils.AsyncFileDialogs")
public class MixinAsyncFileDialogs {

    @Inject(method = "saveFileDialog", at = @At("HEAD"), cancellable = true, remap = false)
    private static void onSaveFileDialog(String defaultPath, String defaultName, String filterDescription, String[] filters, CallbackInfoReturnable<CompletableFuture<String>> cir) {
        String autoExtension = (filters != null && filters.length == 1) ? filters[0] : "mp4";
        String path = (defaultPath != null && !defaultPath.trim().isEmpty()) ? defaultPath : "flashback/videos";
        String name = (defaultName != null && !defaultName.trim().isEmpty()) ? defaultName : "replay." + autoExtension;

        if (autoExtension != null && !name.toLowerCase().endsWith("." + autoExtension.toLowerCase())) {
            name = name + "." + autoExtension;
        }

        Path fullPath = Paths.get(path, name);
        try {
            if (fullPath.getParent() != null) {
                Files.createDirectories(fullPath.getParent());
            }
        } catch (Exception e) {
            System.err.println("[Flashback Touch] Failed to create directories for: " + fullPath + " (" + e.getMessage() + ")");
        }

        System.out.println("[Flashback Touch] Android save dialog bypass: output resolved to -> " + fullPath.toAbsolutePath());
        cir.setReturnValue(CompletableFuture.completedFuture(fullPath.toAbsolutePath().toString()));
    }

    @Inject(method = "openFolderDialog", at = @At("HEAD"), cancellable = true, remap = false)
    private static void onOpenFolderDialog(String defaultPath, CallbackInfoReturnable<CompletableFuture<String>> cir) {
        String path = (defaultPath != null && !defaultPath.trim().isEmpty()) ? defaultPath : "flashback/exports";
        Path fullPath = Paths.get(path);
        try {
            Files.createDirectories(fullPath);
        } catch (Exception e) {
            System.err.println("[Flashback Touch] Failed to create directories for: " + fullPath + " (" + e.getMessage() + ")");
        }

        System.out.println("[Flashback Touch] Android folder dialog bypass: directory resolved to -> " + fullPath.toAbsolutePath());
        cir.setReturnValue(CompletableFuture.completedFuture(fullPath.toAbsolutePath().toString()));
    }

    @Inject(method = "openFileDialog", at = @At("HEAD"), cancellable = true, remap = false)
    private static void onOpenFileDialog(String defaultPath, String filterDescription, String[] filters, CallbackInfoReturnable<CompletableFuture<String>> cir) {
        System.out.println("[Flashback Touch] Android open dialog bypass: file resolved to -> " + defaultPath);
        cir.setReturnValue(CompletableFuture.completedFuture(defaultPath));
    }
}
