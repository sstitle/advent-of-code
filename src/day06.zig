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

const Problem = struct { start: usize, end: usize, op: u8 };

pub fn solvePartOne(input: []const []const u8) !u64 {
    if (input.len == 0) return 0;

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // Find the maximum line length
    var max_len: usize = 0;
    for (input) |line| {
        max_len = @max(max_len, line.len);
    }

    // The last line contains the operators
    const op_line = input[input.len - 1];
    const num_lines = input[0 .. input.len - 1];

    // Find problem boundaries by looking for columns that are all spaces
    // A problem separator is a column where all rows (including op row) have spaces
    var problems: std.ArrayList(Problem) = .empty;

    var in_problem = false;
    var problem_start: usize = 0;

    for (0..max_len + 1) |col| {
        const is_separator = blk: {
            if (col >= max_len) break :blk true;
            // Check if this column is all spaces
            for (input) |line| {
                if (col < line.len and line[col] != ' ') {
                    break :blk false;
                }
            }
            break :blk true;
        };

        if (!is_separator and !in_problem) {
            // Starting a new problem
            in_problem = true;
            problem_start = col;
        } else if (is_separator and in_problem) {
            // Ending a problem
            in_problem = false;
            // Find the operator in this problem's range
            var op: u8 = '+';
            for (problem_start..col) |c| {
                if (c < op_line.len) {
                    const ch = op_line[c];
                    if (ch == '*' or ch == '+') {
                        op = ch;
                        break;
                    }
                }
            }
            try problems.append(allocator, .{ .start = problem_start, .end = col, .op = op });
        }
    }

    // Now solve each problem
    var grand_total: u64 = 0;

    for (problems.items) |problem| {
        var result: u64 = if (problem.op == '*') 1 else 0;

        for (num_lines) |line| {
            // Extract the number from this line within the problem's column range
            const end_col = @min(problem.end, line.len);
            if (problem.start >= line.len) continue;

            const slice = line[problem.start..end_col];
            // Parse the number, trimming spaces
            const trimmed = std.mem.trim(u8, slice, " ");
            if (trimmed.len == 0) continue;

            const num = std.fmt.parseInt(u64, trimmed, 10) catch continue;

            if (problem.op == '*') {
                result *= num;
            } else {
                result += num;
            }
        }

        grand_total += result;
    }

    return grand_total;
}

pub fn loadInput(allocator: std.mem.Allocator) ![][]const u8 {
    return try utils.readLinesForDay(allocator, 6);
}
