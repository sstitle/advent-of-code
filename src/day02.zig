const std = @import("std");
const utils = @import("utils.zig");

pub const Pair = struct { u64, u64 };

const ParseError = error{
    MalformedPair,
    MissingValue,
};

/// Reads pairs from a comma-separated file in format "a-b,c-d,...".
/// Caller is responsible for freeing the returned ArrayList.
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

        const a_str = num_iter.next() orelse return ParseError.MalformedPair;
        const b_str = num_iter.next() orelse return ParseError.MissingValue;

        const a = try std.fmt.parseInt(u64, a_str, 10);
        const b = try std.fmt.parseInt(u64, b_str, 10);

        try pairs.append(allocator, Pair{ a, b });
    }
    return pairs;
}

pub fn loadPairs(allocator: std.mem.Allocator) !std.ArrayList(Pair) {
    var path_buf: [64]u8 = undefined;
    const day_path = try utils.getInputPathForDay(&path_buf, 2);
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
pub fn searchForInvalidIdsInRange(allocator: std.mem.Allocator, min_id: u64, max_id: u64) ![]u64 {
    if (max_id < min_id) {
        return error.InvalidRange;
    }
    var invalid_ids: std.ArrayList(u64) = .empty;
    errdefer invalid_ids.deinit(allocator);

    // Try each even digit length: 2, 4, 6, 8, ...
    var half_digits: u6 = 1;
    while (half_digits <= 10) : (half_digits += 1) {
        const multiplier = std.math.pow(u64, 10, half_digits) + 1;
        const min_half = std.math.pow(u64, 10, half_digits - 1); // e.g., 10 for 2 half-digits
        const max_half = std.math.pow(u64, 10, half_digits) - 1; // e.g., 99 for 2 half-digits

        // Find the range of x values that produce numbers in [min_id, max_id]
        const start_x = @max(min_half, (min_id + multiplier - 1) / multiplier); // ceil division
        const end_x = @min(max_half, max_id / multiplier);

        if (start_x > end_x) continue;

        var x = start_x;
        while (x <= end_x) : (x += 1) {
            try invalid_ids.append(allocator, x * multiplier);
        }
    }

    return invalid_ids.toOwnedSlice(allocator);
}

pub fn solve(allocator: std.mem.Allocator, pairs: []const Pair) !u64 {
    var acc: u64 = 0;
    for (pairs) |pair| {
        const invalid_ids = try searchForInvalidIdsInRange(allocator, pair[0], pair[1]);
        defer allocator.free(invalid_ids);
        for (invalid_ids) |id| {
            acc += id;
        }
    }
    return acc;
}

test "solve with example" {
    const pairs = getExamplePairs();
    const result = try solve(std.testing.allocator, pairs);
    try std.testing.expectEqual(1227775554, result);
}

test "solve with input file" {
    const allocator = std.testing.allocator;
    var pairs_list = try loadPairs(allocator);
    defer pairs_list.deinit(allocator);
    const result = try solve(allocator, pairs_list.items);
    try std.testing.expectEqual(38158151648, result);
}
