const std = @import("std");
const utils = @import("utils.zig");

const Pair = struct { u64, u64 };

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

        const a = try std.fmt.parseInt(u64, num_iter.next() orelse continue, 10);
        const b = try std.fmt.parseInt(u64, num_iter.next() orelse continue, 10);

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

pub fn getExamplePairs() []const Pair {
    const example = [_]Pair{
        .{ 11, 22 },
        .{ 95, 115 },
        .{ 998, 1012 },
        .{ 1188511880, 1188511890 },
        .{ 222220, 222224 },
        .{ 1698522, 1698528 },
        .{ 446443, 446449 },
        .{ 38593856, 38593862 },
    };
    return &example;
}

/// Generate "mirror" numbers where first half equals second half.
/// For 2n digits, the number is x * (10^n + 1) where x has n digits.
pub fn searchForInvalidIdsInRange(allocator: std.mem.Allocator, minId: u64, maxId: u64) ![]u64 {
    if (maxId < minId) {
        unreachable;
    }
    var invalidIds: std.ArrayList(u64) = .empty;
    errdefer invalidIds.deinit(allocator);

    // Try each even digit length: 2, 4, 6, 8, ...
    var half_digits: u6 = 1;
    while (half_digits <= 10) : (half_digits += 1) {
        const multiplier = std.math.pow(u64, 10, half_digits) + 1;
        const min_half = std.math.pow(u64, 10, half_digits - 1); // e.g., 10 for 2 half-digits
        const max_half = std.math.pow(u64, 10, half_digits) - 1; // e.g., 99 for 2 half-digits

        // Find the range of x values that produce numbers in [minId, maxId]
        const start_x = @max(min_half, (minId + multiplier - 1) / multiplier); // ceil division
        const end_x = @min(max_half, maxId / multiplier);

        if (start_x > end_x) continue;

        var x = start_x;
        while (x <= end_x) : (x += 1) {
            const num = x * multiplier;
            if (num >= minId and num <= maxId) {
                try invalidIds.append(allocator, num);
            }
        }
    }

    return invalidIds.toOwnedSlice(allocator);
}

pub fn solve(use_example: bool) !u64 {
    std.debug.print("Solving day 2...\n", .{});
    const allocator = std.heap.page_allocator;

    const pairs: []const Pair = if (use_example)
        getExamplePairs()
    else
        (try loadDayTwoInput(allocator, 2)).items;

    std.debug.print("Got input\n", .{});
    var acc: u64 = 0;
    for (pairs) |pair| {
        const invalidIds = try searchForInvalidIdsInRange(allocator, pair[0], pair[1]);
        defer allocator.free(invalidIds);
        for (invalidIds) |id| {
            acc += id;
        }
    }
    return acc;
}

test "verify that the answer for day 2 example is correct" {
    const result = try solve(true);
    try std.testing.expectEqual(result, 1227775554);
}

test "verify that the answer for day 2 is correct" {
    const result = try solve(false);
    try std.testing.expectEqual(result, 38158151648);
}
