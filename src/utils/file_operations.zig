const std = @import("std");
const Note = @import("../components/note.zig").Note;

pub fn loadExistingNotes(notes: *std.ArrayList(Note), allocator: std.mem.Allocator) !void {
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

pub fn deleteNoteFile(title: []const u8) !void {
    const allocator = std.heap.page_allocator;
    const file_path = try std.fmt.allocPrint(allocator, "notes/{s}.md", .{title});
    defer allocator.free(file_path);
    try std.fs.cwd().deleteFile(file_path);
}
