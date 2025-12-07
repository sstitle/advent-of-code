const std = @import("std");
const Day = @import("day.zig").Day;
const utils = @import("utils.zig");

pub const day = Day([]const u8, u64){
    .load = &loadJoltages,
    .getExample = &getExampleJoltages,
    .solvers = &.{
        .{ .name = "Part One", .func = &solvePartOne },
        .{ .name = "Part Two", .func = &solvePartTwo },
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

pub fn solvePartOne(joltages: []const []const u8) !u64 {
    var total: u64 = 0;
    for (joltages) |joltage| {
        const value = try findLargestPair(joltage);
        std.debug.print("{s} -> {d}\n", .{ joltage, value });
        total += value;
    }
    return total;
}

/// Find the largest k-digit number by selecting k digits in order from the input
fn findLargestKDigits(digits: []const u8, k: usize) u64 {
    if (digits.len < k) return 0;
    if (digits.len == k) {
        // Must use all digits
        var result: u64 = 0;
        for (digits) |d| {
            result = result * 10 + (d - '0');
        }
        return result;
    }

    // Greedy approach: for each position in the result, pick the largest digit
    // that still leaves enough digits remaining for the rest of the result
    var result: u64 = 0;
    var start: usize = 0;

    for (0..k) |pos| {
        const remaining_to_pick = k - pos - 1;
        const end = digits.len - remaining_to_pick;

        // Find the largest digit in range [start, end)
        var best_idx = start;
        var best_digit = digits[start];
        for (start + 1..end) |i| {
            if (digits[i] > best_digit) {
                best_digit = digits[i];
                best_idx = i;
            }
        }

        result = result * 10 + (best_digit - '0');
        start = best_idx + 1;
    }

    return result;
}

pub fn solvePartTwo(joltages: []const []const u8) !u64 {
    var total: u64 = 0;
    for (joltages) |joltage| {
        const value = findLargestKDigits(joltage, 12);
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
