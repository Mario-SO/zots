const rl = @import("raylib");
const rg = @import("raygui");
const std = @import("std");
const layout = @import("layout.zig");
const Note = @import("../components/note.zig").Note;

pub const NoteEditor = struct {
    note: *Note,
    is_open: bool,
    text_box: [4096:0]u8,
};

pub fn drawNoteEditor(editor: *NoteEditor) !void {
    const padding: f32 = 20;
    const editor_width = layout.SCREEN_WIDTH - (padding * 2);
    const editor_height = layout.SCREEN_HEIGHT - (padding * 2);

    if (rg.guiWindowBox(.{ .x = padding, .y = padding, .width = editor_width, .height = editor_height }, &editor.note.title) != 0) {
        editor.is_open = false;
    }

    _ = rg.guiTextBox(.{
        .x = padding + 10,
        .y = padding + 30,
        .width = editor_width - 20,
        .height = editor_height - 70,
    }, &editor.text_box, 4096, true);

    if (rg.guiButton(.{ .x = padding + 10, .y = editor_height + padding - 30, .width = 100, .height = 20 }, "Save") != 0) {
        std.mem.copyForwards(u8, editor.note.content, &editor.text_box);
        editor.note.saveToFile(try std.fmt.allocPrint(std.heap.page_allocator, "notes/{s}.md", .{editor.note.title})) catch {};
        editor.is_open = false;
    }
}
