const std = @import("std");
const Day = @import("day.zig").Day;
const utils = @import("utils.zig");

pub const day = Day([]const u8, u64){
    .load = &loadJoltages,
    .getExample = &getExampleJoltages,
    .solvers = &.{
        .{ .name = "Result", .func = &solve },
    },
};

const solveError = error{
    tooFewValues,
};

pub fn findLargestPair(joltage: []const u8) !u64 {
    if (joltage.len < 2) {
        return solveError.tooFewValues;
    }
    var max_value: u64 = 0;
    for (0..joltage.len) |i| {
        for (i + 1..joltage.len) |j| {
            const a: u64 = joltage[i] - '0';
            const b: u64 = joltage[j] - '0';
            const value = a * 10 + b;
            if (value > max_value) {
                max_value = value;
            }
        }
    }
    return max_value;
}

pub fn solve(joltages: []const []const u8) !u64 {
    var total: u64 = 0;
    for (joltages) |joltage| {
        const value = try findLargestPair(joltage);
        std.debug.print("{s} -> {d}\n", .{ joltage, value });
        total += value;
    }
    return total;
}

pub fn getExampleJoltages() []const []const u8 {
    const joltages = [_][]const u8{
        "987654321111111",
        "811111111111119",
        "234234234234278",
        "818181911112111",
    };
    return &joltages;
}

pub fn loadJoltages(allocator: std.mem.Allocator) ![][]const u8 {
    return try utils.readLinesForDay(allocator, 3);
}
