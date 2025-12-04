const std = @import("std");
const utils = @import("utils.zig");

const Pair = struct { i64, i64 };

/// Reads lines from a file and returns them as a slice of strings.
/// Caller is responsible for freeing the returned slice.
pub fn readPairsFromFile(allocator: std.mem.Allocator, file_path: []const u8) !std.ArrayList(Pair) {
    var file = try std.fs.cwd().openFile(file_path, .{ .mode = .read_only });
    defer file.close();
    const content = try file.readToEndAlloc(allocator, std.math.maxInt(usize));
    defer allocator.free(content);

    const input = std.mem.trim(u8, content, &std.ascii.whitespace);

    var pairs: std.ArrayList(Pair) = .empty;
    errdefer pairs.deinit(allocator);

    var pair_iter = std.mem.splitSequence(u8, input, ",");
    while (pair_iter.next()) |pair_str| {
        var num_iter = std.mem.splitSequence(u8, pair_str, "-");

        const a = try std.fmt.parseInt(i64, num_iter.next() orelse continue, 10);
        const b = try std.fmt.parseInt(i64, num_iter.next() orelse continue, 10);

        // std.debug.print("({}, {})\n", .{ a, b });
        try pairs.append(allocator, Pair{ a, b });
    }
    return pairs;
}

pub fn loadDayTwoInput(allocator: std.mem.Allocator, day_number: u32) !std.ArrayList(Pair) {
    var path_buf: [64]u8 = undefined;
    const day_path = try utils.getInputPathForDay(&path_buf, day_number);
    return readPairsFromFile(allocator, day_path);
}

pub fn solve() !i64 {
    std.debug.print("Solving day 2...\n", .{});
    const input = try loadDayTwoInput(std.heap.page_allocator, 2);
    std.debug.print("Got input\n", .{});
    for (input.items) |pair| {
        std.debug.print("({}, {})\n", .{ pair[0], pair[1] });
    }
    return -1;
}
