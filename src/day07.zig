const std = @import("std");
const Day = @import("day.zig").Day;
const utils = @import("utils.zig");

pub const day = Day([]const u8, u64){
    .load = &loadInput,
    .getExample = &getExampleInput,
    .solvers = &.{
        .{ .name = "Part One", .func = &solvePartOne },
        .{ .name = "Part Two", .func = &solvePartTwo },
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

pub fn solvePartTwo(input: []const []const u8) !u64 {
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

    // Track timeline counts at each position
    // Key: column position, Value: number of timelines at that position
    var timeline_counts = std.AutoHashMap(i64, u64).init(allocator);
    try timeline_counts.put(start_col, 1);

    // Process row by row
    for (input[1..]) |line| {
        var new_counts = std.AutoHashMap(i64, u64).init(allocator);

        var iter = timeline_counts.iterator();
        while (iter.next()) |entry| {
            const col = entry.key_ptr.*;
            const count = entry.value_ptr.*;

            if (col < 0 or col >= @as(i64, @intCast(line.len))) {
                // Particle exits the manifold - timelines continue but don't interact
                const existing = try new_counts.getOrPut(col);
                if (!existing.found_existing) {
                    existing.value_ptr.* = 0;
                }
                existing.value_ptr.* += count;
                continue;
            }

            const ch = line[@intCast(col)];
            if (ch == '^') {
                // Splitter - each timeline splits into 2 (left and right)
                const left_col = col - 1;
                const right_col = col + 1;

                const left_entry = try new_counts.getOrPut(left_col);
                if (!left_entry.found_existing) {
                    left_entry.value_ptr.* = 0;
                }
                left_entry.value_ptr.* += count;

                const right_entry = try new_counts.getOrPut(right_col);
                if (!right_entry.found_existing) {
                    right_entry.value_ptr.* = 0;
                }
                right_entry.value_ptr.* += count;
            } else {
                // Empty space - particle continues downward, timeline count unchanged
                const existing = try new_counts.getOrPut(col);
                if (!existing.found_existing) {
                    existing.value_ptr.* = 0;
                }
                existing.value_ptr.* += count;
            }
        }

        timeline_counts.deinit();
        timeline_counts = new_counts;
    }

    // Sum up all timelines
    var total_timelines: u64 = 0;
    var iter = timeline_counts.valueIterator();
    while (iter.next()) |count| {
        total_timelines += count.*;
    }

    timeline_counts.deinit();
    return total_timelines;
}

pub fn loadInput(allocator: std.mem.Allocator) ![][]const u8 {
    return try utils.readLinesForDay(allocator, 7);
}
