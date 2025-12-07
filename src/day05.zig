const std = @import("std");
const Day = @import("day.zig").Day;
const utils = @import("utils.zig");

const Range = struct {
    start: u64,
    end: u64,

    fn contains(self: Range, value: u64) bool {
        return value >= self.start and value <= self.end;
    }
};

const Input = struct {
    ranges: []Range,
    ingredients: []u64,
};

pub const day = Day([]const u8, u64){
    .load = &loadInput,
    .getExample = &getExampleInput,
    .solvers = &.{
        .{ .name = "Part One", .func = &solvePartOne },
    },
};

fn isFresh(ranges: []const Range, id: u64) bool {
    for (ranges) |range| {
        if (range.contains(id)) {
            return true;
        }
    }
    return false;
}

pub fn solvePartOne(lines: []const []const u8) !u64 {
    var ranges: std.ArrayList(Range) = .empty;
    var ingredients: std.ArrayList(u64) = .empty;
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var parsing_ranges = true;

    for (lines) |line| {
        if (line.len == 0) {
            parsing_ranges = false;
            continue;
        }

        if (parsing_ranges) {
            // Parse range like "3-5"
            var parts = std.mem.splitScalar(u8, line, '-');
            const start_str = parts.next() orelse continue;
            const end_str = parts.next() orelse continue;
            const start = try std.fmt.parseInt(u64, start_str, 10);
            const end = try std.fmt.parseInt(u64, end_str, 10);
            try ranges.append(allocator, .{ .start = start, .end = end });
        } else {
            // Parse ingredient ID
            const id = try std.fmt.parseInt(u64, line, 10);
            try ingredients.append(allocator, id);
        }
    }

    var fresh_count: u64 = 0;
    for (ingredients.items) |id| {
        if (isFresh(ranges.items, id)) {
            fresh_count += 1;
        }
    }

    return fresh_count;
}

pub fn getExampleInput() []const []const u8 {
    const input = [_][]const u8{
        "3-5",
        "10-14",
        "16-20",
        "12-18",
        "",
        "1",
        "5",
        "8",
        "11",
        "17",
        "32",
    };
    return &input;
}

pub fn loadInput(allocator: std.mem.Allocator) ![][]const u8 {
    return try utils.readLinesForDay(allocator, 5);
}
