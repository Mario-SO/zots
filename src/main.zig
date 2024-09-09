const rl = @import("raylib");
const std = @import("std");
const layout = @import("ui/layout.zig");

pub fn main() !void {
    rl.initWindow(layout.SCREEN_WIDTH, layout.SCREEN_HEIGHT, "🧠 Zots - Note taking app for minimalists");
    defer rl.closeWindow();

    rl.setTargetFPS(60);
    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(layout.BG_COLOR);

        rl.drawFPS(10, 10);
    }
}
