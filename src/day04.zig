const std = @import("std");
const Day = @import("day.zig").Day;
const utils = @import("utils.zig");

pub const day = Day([]const u8, u64){
    .load = &loadGrid,
    .getExample = &getExampleGrid,
    .solvers = &.{
        .{ .name = "Part One", .func = &solvePartOne },
        .{ .name = "Part Two", .func = &solvePartTwo },
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

fn countAdjacentRollsMutable(grid: [][]u8, row: usize, col: usize) u8 {
    var count: u8 = 0;
    const rows = grid.len;
    const cols = grid[0].len;

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

pub fn solvePartTwo(grid: []const []const u8) !u64 {
    // Create a mutable copy of the grid
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var mutable_grid = try allocator.alloc([]u8, grid.len);
    for (grid, 0..) |row, i| {
        mutable_grid[i] = try allocator.alloc(u8, row.len);
        @memcpy(mutable_grid[i], row);
    }

    var total_removed: u64 = 0;

    // Keep removing until no more can be removed
    while (true) {
        // Find all accessible rolls this round
        var to_remove: std.ArrayList([2]usize) = .empty;

        for (mutable_grid, 0..) |row, r| {
            for (row, 0..) |cell, c| {
                if (cell == '@') {
                    const adjacent = countAdjacentRollsMutable(mutable_grid, r, c);
                    if (adjacent < 4) {
                        try to_remove.append(allocator, .{ r, c });
                    }
                }
            }
        }

        if (to_remove.items.len == 0) break;

        // Remove all accessible rolls
        for (to_remove.items) |pos| {
            mutable_grid[pos[0]][pos[1]] = '.';
        }

        total_removed += to_remove.items.len;
    }

    return total_removed;
}
