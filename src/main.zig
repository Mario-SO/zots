const rl = @import("raylib");
const rg = @import("raygui");
const std = @import("std");
const layout = @import("ui/layout.zig");
const Note = @import("components/note.zig").Note;

const NoteEditor = struct {
    note: *Note,
    is_open: bool,
    text_box: [4096:0]u8,
};

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
    try loadExistingNotes(&notes, allocator);

    var search_text: [128:0]u8 = [_:0]u8{0} ** 128;
    var note_editor = NoteEditor{
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
            try createNewNote(&notes, allocator);
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
                    try deleteNoteFile(&note.title);
                }
            }
            rl.drawText(@ptrCast(note.content[0..@min(note.content.len, 50)]), 20, @as(c_int, @intFromFloat(y + 25)), 10, rl.Color.black);
            y += note_height + 10;
        }

        rl.drawFPS(10, layout.SCREEN_HEIGHT - 20);

        if (note_editor.is_open) {
            drawNoteEditor(&note_editor) catch |err| {
                // Handle the error here. For now, we'll just print it.
                std.debug.print("Error in drawNoteEditor: {}\n", .{err});
            };
        }
    }
}

fn loadExistingNotes(notes: *std.ArrayList(Note), allocator: std.mem.Allocator) !void {
    try std.fs.cwd().makePath("notes");
    var dir = try std.fs.cwd().openDir("notes", .{ .iterate = true });
    defer dir.close();

    var it = dir.iterate();
    while (try it.next()) |entry| {
        if (entry.kind == .file and std.mem.endsWith(u8, entry.name, ".md")) {
            const note = try Note.loadFromFile(allocator, try std.fmt.allocPrint(allocator, "notes/{s}", .{entry.name}));
            try notes.append(note);
        }
    }
}

fn createNewNote(notes: *std.ArrayList(Note), allocator: std.mem.Allocator) !void {
    const title = "New Note";
    var note = try Note.init(allocator, title);
    try notes.append(note);
    const file_path = try std.fmt.allocPrint(allocator, "notes/{s}.md", .{title});
    defer allocator.free(file_path);
    try note.saveToFile(file_path);
}

fn deleteNoteFile(title: []const u8) !void {
    const path = try std.fmt.allocPrint(std.heap.page_allocator, "notes/{s}.md", .{title});
    defer std.heap.page_allocator.free(path);
    try std.fs.cwd().deleteFile(path);
}

fn drawNoteEditor(editor: *NoteEditor) !void {
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
