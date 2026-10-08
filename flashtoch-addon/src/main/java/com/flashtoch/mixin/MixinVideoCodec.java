package com.flashtoch.mixin;

import org.bytedeco.ffmpeg.avcodec.AVCodec;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfoReturnable;

import java.util.ArrayList;
import java.util.List;

@Mixin(targets = "com.moulberry.flashback.combo_options.VideoCodec", remap = false)
public class MixinVideoCodec {

    @Inject(
        method = "doesEncoderWork",
        at = @At("HEAD"),
        cancellable = true,
        remap = false,
        require = 0
    )
    private static void flashtoch$rejectUnsupportedHardwareEncoders(AVCodec codec, CallbackInfoReturnable<Boolean> cir) {
        if (codec != null) {
            try {
                String name = codec.name().getString();
                if (name != null) {
                    name = name.toLowerCase();
                    // On Android Java launchers (Zalith, Pojav), mediacodec fails due to lack of
                    // android.media.MediaCodec on the OpenJDK classpath, and v4l2m2m lacks device access.
                    if (name.contains("mediacodec") || name.contains("v4l2m2m")) {
                        cir.setReturnValue(false);
                    }
                }
            } catch (Throwable ignored) {}
        }
    }

    @Inject(
        method = "getEncoders",
        at = @At("RETURN"),
        cancellable = true,
        remap = false,
        require = 0
    )
    private void flashtoch$filterEncodersList(CallbackInfoReturnable<String[]> cir) {
        String[] encoders = cir.getReturnValue();
        if (encoders != null && encoders.length > 0) {
            List<String> valid = new ArrayList<>();
            for (String enc : encoders) {
                if (enc == null) continue;
                String lower = enc.toLowerCase();
                if (lower.contains("mediacodec") || lower.contains("v4l2m2m")) {
                    continue;
                }
                valid.add(enc);
            }
            if (!valid.isEmpty()) {
                cir.setReturnValue(valid.toArray(new String[0]));
            }
        }
    }
}
