const std = @import("std");
const Day = @import("day.zig").Day;
const utils = @import("utils.zig");

pub const day = Day([]const u8, u64){
    .load = &loadInput,
    .getExample = &getExampleInput,
    .solvers = &.{
        .{ .name = "Result", .func = &solvePartOne },
    },
};

pub fn getExampleInput() []const []const u8 {
    const input = [_][]const u8{
        "123 328  51 64",
        " 45 64  387 23",
        "  6 98  215 314",
        " *   +   *   +",
    };
    return &input;
}

pub fn solvePartOne(input: []const []const u8) !u64 {
    for (input) |line| {
        std.debug.print("Line: {s}\n", .{line});
    }
    return 0;
}

pub fn loadInput(allocator: std.mem.Allocator) ![][]const u8 {
    return try utils.readLinesForDay(allocator, 5);
}
