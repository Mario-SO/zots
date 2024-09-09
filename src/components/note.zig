// components/note.zig
const std = @import("std");
const fs = std.fs;

pub const Note = struct {
    title: [64:0]u8,
    content: [:0]u8,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, title: []const u8) !Note {
        var note = Note{
            .title = [_:0]u8{0} ** 64,
            .content = try allocator.allocSentinel(u8, 1, 0), // Allocate with just one space
            .allocator = allocator,
        };
        std.mem.copyForwards(u8, &note.title, title[0..@min(title.len, 63)]);
        note.content[0] = ' '; // Set the content to a single space
        return note;
    }

    pub fn deinit(self: *Note) void {
        self.allocator.free(self.content);
    }

    pub fn loadFromFile(allocator: std.mem.Allocator, path: []const u8) !Note {
        const file = try fs.cwd().openFile(path, .{});
        defer file.close();

        const stat = try file.stat();
        var note = try Note.init(allocator, fs.path.basename(path));
        const new_content = try allocator.allocSentinel(u8, stat.size, 0);
        allocator.free(note.content);
        note.content = new_content;
        _ = try file.readAll(note.content[0..stat.size]);
        note.content[stat.size] = 0; // Ensure null termination

        return note;
    }

    pub fn saveToFile(self: *const Note, path: []const u8) !void {
        const file = try fs.cwd().createFile(path, .{});
        defer file.close();

        try file.writeAll(self.content);
    }
};
