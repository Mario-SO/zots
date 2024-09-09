const rl = @import("raylib");
const rg = @import("raygui");
const std = @import("std");
const layout = @import("ui/layout.zig");
const Note = @import("components/note.zig").Note;
const editor = @import("ui/editor.zig");
const file_ops = @import("utils/file_operations.zig");
const note_ops = @import("utils/note_operations.zig");

pub fn main() !void {
    rl.initWindow(layout.SCREEN_WIDTH, layout.SCREEN_HEIGHT, "🧠 Zots - Minimal note-taking app");
    defer rl.closeWindow();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var notes = std.ArrayList(Note).init(allocator);
    defer {
        for (notes.items) |*note| {
            note.deinit();
        }
        notes.deinit();
    }

    // Load existing notes from the notes/ directory
    try file_ops.loadExistingNotes(&notes, allocator);

    var search_text: [128:0]u8 = [_:0]u8{0} ** 128;
    var note_editor = editor.NoteEditor{
        .note = undefined,
        .is_open = false,
        .text_box = [_:0]u8{0} ** 4096,
    };

    rl.setTargetFPS(60);
    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(layout.BG_COLOR);

        // Draw search bar
        _ = rg.guiTextBox(.{ .x = 10, .y = 10, .width = layout.SCREEN_WIDTH - 60, .height = 30 }, &search_text, 128, true);
        if (rg.guiButton(.{ .x = layout.SCREEN_WIDTH - 40, .y = 10, .width = 30, .height = 30 }, "+") != 0) {
            try note_ops.createNewNote(&notes, allocator);
        }

        // Draw notes
        var y: f32 = 50;
        for (notes.items, 0..) |*note, i| {
            const note_height: f32 = 60;
            const note_rect = rl.Rectangle{ .x = 10, .y = y, .width = layout.SCREEN_WIDTH - 20, .height = note_height };

            if (rg.guiWindowBox(note_rect, &note.title) != 0) {
                if (rl.isMouseButtonPressed(rl.MouseButton.mouse_button_left)) {
                    note_editor.note = note;
                    note_editor.is_open = true;
                    std.mem.copyForwards(u8, &note_editor.text_box, note.content);
                } else if (rl.isMouseButtonPressed(rl.MouseButton.mouse_button_right)) {
                    _ = notes.orderedRemove(i);
                    try file_ops.deleteNoteFile(&note.title);
                }
            }
            rl.drawText(@ptrCast(note.content[0..@min(note.content.len, 50)]), 20, @as(c_int, @intFromFloat(y + 25)), 10, rl.Color.black);
            y += note_height + 10;
        }

        rl.drawFPS(10, layout.SCREEN_HEIGHT - 20);

        if (note_editor.is_open) {
            editor.drawNoteEditor(&note_editor) catch |err| {
                // Handle the error here. For now, we'll just print it.
                std.debug.print("Error in drawNoteEditor: {}\n", .{err});
            };
        }
    }
}
