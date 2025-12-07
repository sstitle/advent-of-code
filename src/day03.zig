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

pub fn solve(joltages: []const []const u8) !u64 {
    for (joltages) |joltage| {
        std.debug.print("Processing joltage: {s}\n", .{joltage});
    }
    return 0;
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
