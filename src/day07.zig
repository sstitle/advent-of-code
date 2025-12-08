const std = @import("std");
const Day = @import("day.zig").Day;
const utils = @import("utils.zig");

pub const day = Day([]const u8, u64){
    .load = &loadInput,
    .getExample = &getExampleInput,
    .solvers = &.{
        .{ .name = "Part One", .func = &solvePartOne },
    },
};

pub fn getExampleInput() []const []const u8 {
    const input = [_][]const u8{
        ".......S.......",
        "...............",
        ".......^.......",
        "...............",
        "......^.^......",
        "...............",
        ".....^.^.^.....",
        "...............",
        "....^.^...^....",
        "...............",
        "...^.^...^.^...",
        "...............",
        "..^...^.....^..",
        "...............",
        ".^.^.^.^.^...^.",
        "...............",
    };
    return &input;
}

const Beam = struct {
    col: i64,
    row: usize,
};

pub fn solvePartOne(input: []const []const u8) !u64 {
    if (input.len == 0) return 0;

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // Find starting position S
    var start_col: i64 = 0;
    for (input[0], 0..) |ch, col| {
        if (ch == 'S') {
            start_col = @intCast(col);
            break;
        }
    }

    // Track active beam positions (beams at the same position merge)
    var beam_positions = std.AutoHashMap(i64, void).init(allocator);
    try beam_positions.put(start_col, {});

    var split_count: u64 = 0;

    // Process row by row
    for (input[1..]) |line| {
        var new_positions = std.AutoHashMap(i64, void).init(allocator);

        var iter = beam_positions.keyIterator();
        while (iter.next()) |col_ptr| {
            const col = col_ptr.*;

            if (col < 0 or col >= @as(i64, @intCast(line.len))) {
                // Beam exits the manifold
                continue;
            }

            const ch = line[@intCast(col)];
            if (ch == '^') {
                // Splitter - beam stops, emits left and right
                split_count += 1;

                // Add beams to left and right
                try new_positions.put(col - 1, {});
                try new_positions.put(col + 1, {});
            } else {
                // Empty space - beam continues downward
                try new_positions.put(col, {});
            }
        }

        beam_positions.deinit();
        beam_positions = new_positions;
    }

    beam_positions.deinit();
    return split_count;
}

pub fn loadInput(allocator: std.mem.Allocator) ![][]const u8 {
    return try utils.readLinesForDay(allocator, 7);
}
