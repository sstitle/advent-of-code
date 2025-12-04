const std = @import("std");
const day01 = @import("day01.zig");
const day02 = @import("day02.zig");

fn printHelp() void {
    std.debug.print(
        \\Advent of Code 2025 Solutions
        \\
        \\Usage: aoc [OPTIONS]
        \\
        \\Options:
        \\  --day <N>     Run solution for day N (required)
        \\  --day=<N>     Run solution for day N (alternative syntax)
        \\  --example     Use example input instead of full input
        \\  --help        Show this help message
        \\
        \\Examples:
        \\  aoc --day 1
        \\  aoc --day=2 --example
        \\
    , .{});
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();

    // Skip program name
    _ = args.next();

    var day: ?u32 = null;
    var use_example = false;

    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "--help") or std.mem.eql(u8, arg, "-h")) {
            printHelp();
            return;
        } else if (std.mem.eql(u8, arg, "--example")) {
            use_example = true;
        } else if (std.mem.eql(u8, arg, "--day")) {
            if (args.next()) |day_arg| {
                day = std.fmt.parseInt(u32, day_arg, 10) catch {
                    std.debug.print("Invalid day number: {s}\n", .{day_arg});
                    return;
                };
            }
        } else if (std.mem.startsWith(u8, arg, "--day=")) {
            const day_str = arg[6..];
            day = std.fmt.parseInt(u32, day_str, 10) catch {
                std.debug.print("Invalid day number: {s}\n", .{day_str});
                return;
            };
        }
    }

    const selected_day = day orelse {
        std.debug.print("Error: --day is required. Use --help for usage.\n", .{});
        return;
    };

    std.debug.print("Running day {d}{s}\n", .{ selected_day, if (use_example) " (example)" else "" });

    switch (selected_day) {
        1 => try runDay01(allocator, use_example),
        2 => try runDay02(allocator, use_example),
        else => std.debug.print("Day {d} not implemented yet\n", .{selected_day}),
    }
}

fn runDay01(allocator: std.mem.Allocator, use_example: bool) !void {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    const actions: []const []const u8 = if (use_example)
        day01.getExampleActions()
    else
        try day01.loadActions(alloc);

    const part_one = try day01.solvePartOne(actions);
    std.debug.print("Day One - Part One: {d}\n", .{part_one});

    const part_two = try day01.solvePartTwo(actions);
    std.debug.print("Day One - Part Two: {d}\n", .{part_two});
}

fn runDay02(allocator: std.mem.Allocator, use_example: bool) !void {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    const pairs: []const day02.Pair = if (use_example)
        day02.getExamplePairs()
    else
        try day02.loadPairs(alloc);

    const result = try day02.solve(pairs);
    std.debug.print("Day Two: {d}\n", .{result});
}
