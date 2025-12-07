const std = @import("std");
const Day = @import("day.zig").Day;
const utils = @import("utils.zig");

pub const day = Day([]const u8, u64){
    .load = &loadGrid,
    .getExample = &getExampleGrid,
    .solvers = &.{
        .{ .name = "Part One", .func = &solvePartOne },
    },
};

fn countAdjacentRolls(grid: []const []const u8, row: usize, col: usize) u8 {
    var count: u8 = 0;
    const rows = grid.len;
    const cols = grid[0].len;

    // Check all 8 directions
    const directions = [_][2]i8{
        .{ -1, -1 }, .{ -1, 0 }, .{ -1, 1 },
        .{ 0, -1 },              .{ 0, 1 },
        .{ 1, -1 },  .{ 1, 0 },  .{ 1, 1 },
    };

    for (directions) |dir| {
        const new_row = @as(i64, @intCast(row)) + dir[0];
        const new_col = @as(i64, @intCast(col)) + dir[1];

        if (new_row >= 0 and new_row < rows and new_col >= 0 and new_col < cols) {
            if (grid[@intCast(new_row)][@intCast(new_col)] == '@') {
                count += 1;
            }
        }
    }

    return count;
}

pub fn solvePartOne(grid: []const []const u8) !u64 {
    var accessible: u64 = 0;

    for (grid, 0..) |row, r| {
        for (row, 0..) |cell, c| {
            if (cell == '@') {
                const adjacent = countAdjacentRolls(grid, r, c);
                if (adjacent < 4) {
                    accessible += 1;
                }
            }
        }
    }

    return accessible;
}

pub fn getExampleGrid() []const []const u8 {
    const grid = [_][]const u8{
        "..@@.@@@@.",
        "@@@.@.@.@@",
        "@@@@@.@.@@",
        "@.@@@@..@.",
        "@@.@@@@.@@",
        ".@@@@@@@.@",
        ".@.@.@.@@@",
        "@.@@@.@@@@",
        ".@@@@@@@@.",
        "@.@.@@@.@.",
    };
    return &grid;
}

pub fn loadGrid(allocator: std.mem.Allocator) ![][]const u8 {
    return try utils.readLinesForDay(allocator, 4);
}
