const std = @import("std");
const advent_of_code = @import("advent_of_code");

pub fn main() !void {
    std.debug.print("Start of main\n", .{});
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    const current_dir = std.fs.cwd();
    const cwd_path = try current_dir.realpathAlloc(alloc, ".");
    std.debug.print("Current path: {s}\n", .{cwd_path});

    const data_dir = try std.fs.path.join(alloc, &[_][]const u8{ cwd_path, "data" });
    const day_number = 1;
    // Find path like "data/day_1.txt"
    const day_path_string = try std.fmt.allocPrint(alloc, "day_{d}.txt", .{day_number});
    std.debug.print("Day path string: {s}\n", .{day_path_string});

    const day_path = try std.fs.path.join(alloc, &[_][]const u8{ data_dir, day_path_string });
    std.debug.print("Day path: {s}\n", .{day_path});

    // Read the file contents and dump to the console
    const file = try std.fs.openFileAbsolute(day_path, .{ .mode = .read_only });
    defer file.close();
    const contents = try file.readToEndAlloc(alloc, std.math.maxInt(usize));
    std.debug.print("File contents: {s}\n", .{contents});

    try advent_of_code.bufferedPrint();
}

test "simple test" {
    const gpa = std.testing.allocator;
    var list: std.ArrayList(i32) = .empty;
    defer list.deinit(gpa); // Try commenting this out and see if zig detects the memory leak!
    try list.append(gpa, 42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
