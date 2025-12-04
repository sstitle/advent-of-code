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

/// Sum "mirror" numbers in range where first half equals second half.
/// For 2n digits, the number is x * (10^n + 1) where x has n digits.
/// Uses arithmetic series formula to avoid iteration: sum = n * (first + last) / 2
fn sumMirrorNumbersInRange(min_id: u64, max_id: u64) error{InvalidRange}!u64 {
    if (max_id < min_id) {
        return error.InvalidRange;
    }

    var total: u64 = 0;

    // Try each even digit length: 2, 4, 6, 8, ... up to 20 digits (u64 max is ~1.8e19)
    var half_digits: u6 = 1;
    while (half_digits <= 10) : (half_digits += 1) {
        const multiplier = std.math.pow(u64, 10, half_digits) + 1;
        const min_half = std.math.pow(u64, 10, half_digits - 1); // e.g., 10 for 2 half-digits
        const max_half = std.math.pow(u64, 10, half_digits) - 1; // e.g., 99 for 2 half-digits

        // Find the range of x values that produce numbers in [min_id, max_id]
        const start_x = @max(min_half, (min_id + multiplier - 1) / multiplier); // ceil division
        const end_x = @min(max_half, max_id / multiplier);

        if (start_x > end_x) continue;

        // Sum of arithmetic series: count * (first + last) / 2
        // where first = start_x * multiplier, last = end_x * multiplier
        const count = end_x - start_x + 1;
        const first_val = start_x * multiplier;
        const last_val = end_x * multiplier;
        total += count * (first_val + last_val) / 2;
    }

    return total;
}

pub fn solve(pairs: []const Pair) !u64 {
    var acc: u64 = 0;
    for (pairs) |pair| {
        acc += try sumMirrorNumbersInRange(pair[0], pair[1]);
    }
    return acc;
}

test "solve with example" {
    const pairs = getExamplePairs();
    const result = try solve(pairs);
    try std.testing.expectEqual(1227775554, result);
}

test "solve with input file" {
    const allocator = std.testing.allocator;
    var pairs_list = try loadPairs(allocator);
    defer pairs_list.deinit(allocator);
    const result = try solve(pairs_list.items);
    try std.testing.expectEqual(38158151648, result);
}
