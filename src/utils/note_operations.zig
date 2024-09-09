const std = @import("std");
const Note = @import("../components/note.zig").Note;

pub fn createNewNote(notes: *std.ArrayList(Note), allocator: std.mem.Allocator) !void {
    const title = "New Note";
    const file_path = try std.fmt.allocPrint(allocator, "notes/{s}.md", .{title});
    defer allocator.free(file_path);

    // Create an empty file
    const file = try std.fs.cwd().createFile(file_path, .{});
    file.close();

    // Load the newly created file
    const note = try Note.loadFromFile(allocator, file_path);
    try notes.append(note);
}
