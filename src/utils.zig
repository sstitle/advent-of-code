const std = @import("std");

/// Reads lines from a file and returns them as a slice of strings.
/// Caller is responsible for freeing the returned slice.
pub fn readLinesFromFile(allocator: std.mem.Allocator, file_path: []const u8) ![][]const u8 {
    var file = try std.fs.cwd().openFile(file_path, .{ .mode = .read_only });
    defer file.close();

    var actions: std.ArrayList([]const u8) = .empty;
    errdefer actions.deinit(allocator);

    var read_buf: [4096]u8 = undefined;
    var file_reader = file.reader(&read_buf);
    const reader = &file_reader.interface;

    var line_writer = std.Io.Writer.Allocating.init(allocator);
    defer line_writer.deinit();

    while (true) {
        _ = reader.streamDelimiter(&line_writer.writer, '\n') catch |err| {
            if (err == error.EndOfStream) break else return err;
        };
        _ = reader.toss(1); // skip the newline delimiter

        const line_str = try line_writer.toOwnedSlice();
        if (line_str.len == 0) {
            allocator.free(line_str);
            break;
        }

        try actions.append(allocator, line_str);
    }

    return actions.toOwnedSlice(allocator);
}

/// Builds a path to a day's input file using a stack buffer (no allocation).
pub fn getInputPathForDay(buf: []u8, day_number: u32) ![]const u8 {
    return std.fmt.bufPrint(buf, "data/day_{d}.txt", .{day_number});
}

/// Loads lines from a day's input file.
pub fn loadDayInput(allocator: std.mem.Allocator, day_number: u32) ![][]const u8 {
    var path_buf: [64]u8 = undefined;
    const day_path = try getInputPathForDay(&path_buf, day_number);
    return readLinesFromFile(allocator, day_path);
}
