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

pub fn countInvalidIdsInRange(minId: i64, maxId: i64) !u64 {
    if (maxId < minId) {
        unreachable;
    }
    const allocator = std.heap.page_allocator;
    var invalidCount: u64 = 0;
    var currentId = minId;
    while (currentId <= maxId) : (currentId += 1) {
        const stringified = try std.fmt.allocPrint(allocator, "{}", .{currentId});
        defer allocator.free(stringified);
        if (stringified.len % 2 != 0) {
            continue;
        }
        const firstHalf = stringified[0 .. stringified.len / 2];
        const secondHalf = stringified[stringified.len / 2 ..];
        // Compare the string equality of firstHalf and secondHalf
        if (!std.mem.eql(u8, firstHalf, secondHalf)) {
            continue;
        }
        std.debug.print("Considering {s}\n", .{stringified});
        // TODO: check if invalid and increment invalidCount
        invalidCount += 1;
    }
    return invalidCount;
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
        std.debug.print("({}, {})\n", .{ pair[0], pair[1] });
        const invalidIdCount = try countInvalidIdsInRange(pair[0], pair[1]);
        std.debug.print("Invalid IDs: {}\n", .{invalidIdCount});
        acc += invalidIdCount;
    }
    return acc;
}
