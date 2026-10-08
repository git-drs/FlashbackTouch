package com.flashtoch.mixin;

import com.mojang.renderpearl.api.commands.RenderPass;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.Unique;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Redirect;

@Mixin(targets = "com.moulberry.flashback.editor.ui.CustomImGuiImplB3D", remap = false)
public class MixinCustomImGuiImplB3D {

    @Unique
    private boolean flashtoch$skipCurrentDraw = false;

    @Redirect(
        method = "renderDrawData",
        at = @At(
            value = "INVOKE",
            target = "Lcom/mojang/renderpearl/api/commands/RenderPass;enableScissor(IIII)V",
            remap = false
        ),
        remap = false,
        require = 0
    )
    private void flashtoch$guardEnableScissor(RenderPass pass, int x, int y, int width, int height) {
        if (width <= 0 || height <= 0) {
            this.flashtoch$skipCurrentDraw = true;
            return;
        }
        this.flashtoch$skipCurrentDraw = false;
        pass.enableScissor(x, y, width, height);
    }

    @Redirect(
        method = "renderDrawData",
        at = @At(
            value = "INVOKE",
            target = "Lcom/mojang/renderpearl/api/commands/RenderPass;disableScissor()V",
            remap = false
        ),
        remap = false,
        require = 0
    )
    private void flashtoch$guardDisableScissor(RenderPass pass) {
        this.flashtoch$skipCurrentDraw = false;
        pass.disableScissor();
    }

    @Redirect(
        method = "renderDrawData",
        at = @At(
            value = "INVOKE",
            target = "Lcom/mojang/renderpearl/api/commands/RenderPass;drawIndexed(IIIII)V",
            remap = false
        ),
        remap = false,
        require = 0
    )
    private void flashtoch$guardDrawIndexed(RenderPass pass, int indexCount, int instanceCount, int firstIndex, int firstVertex, int firstInstance) {
        if (this.flashtoch$skipCurrentDraw) {
            this.flashtoch$skipCurrentDraw = false;
            return;
        }
        pass.drawIndexed(indexCount, instanceCount, firstIndex, firstVertex, firstInstance);
    }
}
