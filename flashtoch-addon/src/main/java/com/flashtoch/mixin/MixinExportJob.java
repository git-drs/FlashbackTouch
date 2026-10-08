package com.flashtoch.mixin;

import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Redirect;

import java.nio.FloatBuffer;

@Mixin(targets = "com.moulberry.flashback.exporting.ExportJob")
public class MixinExportJob {

    @Redirect(
        method = "doExport",
        at = @At(
            value = "INVOKE",
            target = "Lorg/lwjgl/openal/SOFTLoopback;alcRenderSamplesSOFT(JLjava/nio/FloatBuffer;I)V",
            remap = false
        ),
        remap = false,
        require = 0
    )
    private void redirectAlcRenderSamplesSOFT(long device, FloatBuffer buffer, int samples) {
        try {
            org.lwjgl.openal.SOFTLoopback.alcRenderSamplesSOFT(device, buffer, samples);
        } catch (Throwable t) {
            // OpenAL loopback is unavailable on Android (e.g. OpenSL ES backend)
            // Fill with silence so video export doesn't freeze or crash
            if (buffer != null) {
                buffer.clear();
                while (buffer.hasRemaining()) {
                    buffer.put(0.0f);
                }
                buffer.flip();
            }
        }
    }
}
